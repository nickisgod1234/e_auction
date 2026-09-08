import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:e_auction/services/product_approval_service.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:http/http.dart' as http;

/// ดึงสินค้าที่ผู้ใช้ลงประมูลไว้เอง พร้อมสถานะการอนุมัติ
///
/// ทางหลักใช้ flutter_quotation_approval_controller.php?customer_id= ซึ่งส่ง
/// customer_id, status และ approval_comment มาครบในคำขอเดียว (~21KB)
/// และคืนเฉพาะประเภทประมูล (AS) อยู่แล้วจึงไม่ต้องกรองประเภทเอง
///
/// ถ้าเซิร์ฟเวอร์ยังเป็นรุ่นก่อนที่จะรองรับ customer_id จะถอยไปใช้
/// list_quotation_type_auction_price_controller.php แบบเดิม (~747KB)
/// เพื่อให้แอปที่ออกไปก่อน API deploy ยังแสดงรายการได้
class MyProductsService {
  static String get _approvalUrl =>
      '${Config.erpWriteBaseUrl}/modules/sales/controllers/flutter_quotation_approval_controller.php';

  static String get _legacyListUrl =>
      '${Config.erpWriteBaseUrl}/modules/sales/controllers/list_quotation_type_auction_price_controller.php';

  static const Duration _timeout = Duration(seconds: 30);

  /// จำไว้ว่าเซิร์ฟเวอร์รองรับ ?customer_id= หรือยัง
  ///
  /// ถ้าไม่จำ ทุกครั้งที่เปิดหน้านี้ตอนที่ API ยังไม่ deploy จะเสียค่าโหลด
  /// ทางหลัก 145KB ทิ้งก่อนจะไปโหลดทางถอย 871KB
  /// null = ยังไม่รู้, ค่าที่จำไว้จะรีเซ็ตเมื่อเปิดแอปใหม่
  static bool? _serverFiltersByCustomer;

  static Future<List<ProductQuotation>> getMyProducts() async {
    final customerId = await UserDataManager.getID();
    if (customerId == null || customerId.trim().isEmpty) {
      return [];
    }

    final ownerId = customerId.trim();
    final client = http.Client();
    try {
      if (_serverFiltersByCustomer == false) {
        return _sorted(await _fetchLegacy(client, ownerId));
      }

      final items = await _fetchApproval(client, ownerId);

      // เซิร์ฟเวอร์รุ่นเก่าไม่ส่ง customer_id มาเลย ถ้ากรองต่อจะได้ศูนย์รายการ
      // จึงต้องแยกให้ออกระหว่าง "ไม่มีสิทธิ์เห็น" กับ "เซิร์ฟเวอร์ยังไม่รองรับ"
      if (items.isNotEmpty && !items.any(_hasCustomerId)) {
        _serverFiltersByCustomer = false;
        return _sorted(await _fetchLegacy(client, ownerId));
      }

      if (items.isNotEmpty) {
        _serverFiltersByCustomer = true;
      }

      return _sorted(
        items
            .where((item) => _isOwnedBy(item, ownerId))
            .map(ProductQuotation.fromJson)
            .toList(),
      );
    } on SocketException {
      throw Exception(
          'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต');
    } on TimeoutException {
      throw Exception('การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง');
    } finally {
      client.close();
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchApproval(
    http.Client client,
    String ownerId,
  ) async {
    final uri = Uri.parse(_approvalUrl).replace(
      queryParameters: {'customer_id': ownerId},
    );

    final response = await _get(client, uri);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return [];

    final data = decoded['data'];
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map<String, dynamic>) return [data];
    return [];
  }

  static Future<List<ProductQuotation>> _fetchLegacy(
    http.Client client,
    String ownerId,
  ) async {
    final response = await _get(client, Uri.parse(_legacyListUrl));
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .where((item) => _isOwnedBy(item, ownerId))
        .where(_isAuction)
        .map((item) => ProductQuotation.fromJson(_normalizeLegacy(item)))
        .toList();
  }

  static Future<http.Response> _get(http.Client client, Uri uri) async {
    final response = await client
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )
        .timeout(
          _timeout,
          onTimeout: () => throw TimeoutException(
              'Request timeout after ${_timeout.inSeconds} seconds'),
        );

    if (response.statusCode != 200) {
      throw Exception('โหลดข้อมูลสินค้าไม่สำเร็จ (${response.statusCode})');
    }
    return response;
  }

  /// เรียงตาม quotation_id เพราะวันที่ว่างในบางรายการ แต่ id เพิ่มตามลำดับที่สร้าง
  static List<ProductQuotation> _sorted(List<ProductQuotation> products) {
    products.sort((a, b) => b.quotationId.compareTo(a.quotationId));
    return products;
  }

  static bool _hasCustomerId(Map<String, dynamic> item) =>
      item['customer_id'] != null;

  /// กรองเจ้าของซ้ำอีกชั้นแม้ส่ง ?customer_id= ไปแล้ว
  ///
  /// endpoint นี้เคยเพิกเฉยพารามิเตอร์ที่ไม่รู้จักแล้วคืนทุกใบ (fail-open)
  /// ถ้าตัวกรองฝั่ง server พังอีก ผู้ใช้จะเห็นประกาศของคนอื่นทั้งหมด
  /// จึงต้องกันไว้ที่นี่ด้วย ไม่ใช่ไว้ใจ server อย่างเดียว
  static bool _isOwnedBy(Map<String, dynamic> item, String customerId) =>
      item['customer_id']?.toString() == customerId;

  /// รายการรวมของ endpoint เก่ามีใบเสนอราคาปกติ (QT) ปนมา เอาเฉพาะประเภทประมูล (AS)
  static bool _isAuction(Map<String, dynamic> item) =>
      (item['quotation_type_code']?.toString() ?? '').startsWith('AS');

  /// endpoint เก่าใช้ชื่อฟิลด์ไม่ตรงกับที่ ProductQuotation อ่าน
  /// และไม่ส่ง created_at มา (เป็น null ทุกรายการ) จึงใช้ request_date แทน
  static Map<String, dynamic> _normalizeLegacy(Map<String, dynamic> item) {
    return {
      ...item,
      'type_description': item['type_description'] ??
          item['quotation_type_description'] ??
          item['quotation_type_code'],
      'phone': item['phone'] ?? item['phone_number'],
      'created_at': item['created_at'] ?? item['request_date'],
    };
  }
}
