import 'package:e_auction/noti_ios/noti_ios.dart';
import 'package:e_auction/services/my_products_service.dart';
import 'package:e_auction/services/product_approval_service.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// เฝ้าดูสถานะสินค้าที่ผู้ใช้ลงไว้ แล้วเด้ง local notification เมื่อผลอนุมัติเปลี่ยน
///
/// แอปไม่มี push notification จึงต้อง poll เอง แต่รายการสินค้าทั้งหมดหนักถึง ~850KB
/// จึงแยกเป็น 2 จังหวะ: discover ครั้งเดียวเพื่อหาว่ามีสินค้าไหนรออนุมัติ
/// แล้วหลังจากนั้น poll เฉพาะรายการที่รออนุมัติด้วย endpoint รายละเอียด (~1KB ต่อชิ้น)
class ProductStatusNotifier {
  static const String keyPrefix = 'product_status_';
  static const String _statusPrefix = '${keyPrefix}last_';
  static const String _pendingIdsKey = '${keyPrefix}pending_ids';
  static const String _lastDiscoveryKey = '${keyPrefix}last_discovery';

  /// รายการทั้งหมดมีขนาด ~850KB จึงดึงห่างๆ ไว้กันเปลืองเน็ตของผู้ใช้
  ///
  /// การค้นหาสินค้าใหม่ไม่ต้องพึ่งรอบนี้ เพราะถูก force ตอนลงสินค้าสำเร็จ
  /// และตอนเปิดหน้าสินค้าของฉันอยู่แล้ว
  static const Duration discoveryInterval = Duration(hours: 6);

  static final ProductApprovalService _approvalService =
      ProductApprovalService.defaultInstance();

  /// ดึงรายการสินค้าทั้งหมดของผู้ใช้เพื่อหาว่ามีรายการไหนรออนุมัติอยู่
  ///
  /// [force] ข้าม throttle ใช้ตอนผู้ใช้เปิดหน้าสินค้าของฉันเอง
  static Future<void> discoverPendingProducts({bool force = false}) async {
    final customerId = await UserDataManager.getID();
    if (customerId == null || customerId.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    if (!force && !_isDiscoveryDue(prefs)) return;

    try {
      final products = await MyProductsService.getMyProducts();
      await recordSnapshot(products);
    } catch (e) {
      // ดึงไม่ได้ก็ข้ามรอบนี้ไป ไม่ต้องรบกวนผู้ใช้
    }
  }

  /// บันทึกสถานะล่าสุดของสินค้าทุกชิ้น และอัปเดตรายการที่ต้องเฝ้าดู
  ///
  /// รายการที่เพิ่งเห็นครั้งแรกจะบันทึกเงียบๆ ไม่แจ้งเตือน
  /// เพื่อไม่ให้ผู้ใช้ที่มีสินค้าเก่าอยู่แล้วโดนเด้งรวดเดียวหลายสิบอัน
  static Future<void> recordSnapshot(List<ProductQuotation> products) async {
    final prefs = await SharedPreferences.getInstance();

    final pendingIds = <String>[];
    final seenKeys = <String>{};

    for (final product in products) {
      final key = '$_statusPrefix${product.quotationId}';
      seenKeys.add(key);
      await prefs.setInt(key, product.status ?? 0);

      if (_isPending(product.status)) {
        pendingIds.add(product.quotationId.toString());
      }
    }

    // ลบสถานะของสินค้าที่ไม่อยู่ในรายการแล้ว (ถูกลบออกจาก ERP)
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_statusPrefix) && !seenKeys.contains(key)) {
        await prefs.remove(key);
      }
    }

    await prefs.setStringList(_pendingIdsKey, pendingIds);
    await prefs.setInt(
      _lastDiscoveryKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// ตรวจเฉพาะสินค้าที่รออนุมัติ ถ้าไม่มีก็ไม่ยิง request เลย
  static Future<void> checkPendingProducts(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingIds = prefs.getStringList(_pendingIdsKey) ?? [];
    if (pendingIds.isEmpty) return;

    final stillPending = <String>[];

    for (final rawId in pendingIds) {
      final quotationId = int.tryParse(rawId);
      if (quotationId == null) continue;

      final product = await _fetchProduct(quotationId);
      if (product == null) {
        // ดึงไม่ได้ (เน็ตหลุด/เซิร์ฟเวอร์ล่ม) เก็บไว้ตรวจรอบหน้า
        stillPending.add(rawId);
        continue;
      }

      if (_isPending(product.status)) {
        stillPending.add(rawId);
        continue;
      }

      final statusKey = '$_statusPrefix$quotationId';
      final previousStatus = prefs.getInt(statusKey);

      // แจ้งเฉพาะตอนเปลี่ยนจากรออนุมัติไปเป็นผลสรุปจริง
      if (_isPending(previousStatus)) {
        try {
          await sendProductApprovalNotification(
            plugin,
            quotationId,
            _titleOf(product),
            product.status == 1,
          );
        } catch (e) {
          // แจ้งเตือนล้มไม่ควรทำให้สถานะที่ตรวจได้แล้วหายไปทั้งรอบ
        }
      }

      await prefs.setInt(statusKey, product.status ?? 0);
    }

    await prefs.setStringList(_pendingIdsKey, stillPending);
  }

  /// ลบข้อมูลที่เฝ้าดูไว้ทั้งหมด ใช้ตอน logout
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(keyPrefix));
    for (final key in keys.toList()) {
      await prefs.remove(key);
    }
  }

  static Future<ProductQuotation?> _fetchProduct(int quotationId) async {
    try {
      final response = await _approvalService.getProductDetail(quotationId);
      if (response.status != 'success' || response.data.isEmpty) return null;
      return response.data.first;
    } catch (e) {
      return null;
    }
  }

  static bool _isDiscoveryDue(SharedPreferences prefs) {
    final lastRun = prefs.getInt(_lastDiscoveryKey);
    if (lastRun == null) return true;

    final elapsed = DateTime.now().millisecondsSinceEpoch - lastRun;
    return elapsed >= discoveryInterval.inMilliseconds;
  }

  /// ERP ส่ง status 0 หรือ null มาเมื่อยังไม่ได้พิจารณา
  static bool _isPending(int? status) => status == null || status == 0;

  static String _titleOf(ProductQuotation product) {
    final description = product.description?.trim() ?? '';
    return description.isNotEmpty ? description : 'สินค้า #${product.quotationId}';
  }
}
