import 'package:e_auction/services/auth_service/auth_service.dart';
import 'package:e_auction/services/product_approval_service.dart';
import 'package:e_auction/views/config/config_prod.dart';

/// เติมเบอร์โทรของผู้ลงสินค้าให้รายการรออนุมัติ
///
/// API อนุมัติของ ERP ส่ง `phone` มาจากตาราง customer ฝั่ง ERP ซึ่งไม่มีข้อมูล
/// ของผู้ใช้ที่สมัครผ่านแอป ทำให้หน้าอนุมัติขึ้น '-' แต่ฐานข้อมูลของแอปมีเบอร์อยู่
/// จึงดึงจาก get_customer_data.php มาเติมให้แทน
///
/// รายการรวมไม่ส่ง customer_id มา ต้องขอจาก endpoint รายละเอียดก่อน
/// จึงต้องใช้ 2 request ต่อสินค้าที่ไม่มีเบอร์ และ cache ไว้ใช้ซ้ำ
class SellerPhoneResolver {
  SellerPhoneResolver({
    ProductApprovalService? approvalService,
    AuthService? authService,
  })  : _approvalService =
            approvalService ?? ProductApprovalService.defaultInstance(),
        _authService =
            authService ?? AuthService(baseUrl: Config.apiUrlotpsever);

  final ProductApprovalService _approvalService;
  final AuthService _authService;

  /// ยิงพร้อมกันแค่ไม่กี่ตัว กันถล่มเซิร์ฟเวอร์เวลารายการยาว
  static const int _batchSize = 4;

  static final Map<int, String> _phoneByCustomerId = {};
  static final Map<int, int> _customerIdByQuotationId = {};

  /// คืน map quotationId → เบอร์ เฉพาะรายการที่ API ไม่ได้ส่งเบอร์มา
  Future<Map<int, String>> resolveMissing(
    List<ProductQuotation> products,
  ) async {
    final targets = products.where(_isPhoneMissing).toList();
    if (targets.isEmpty) return {};

    final resolved = <int, String>{};

    for (var i = 0; i < targets.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, targets.length);
      final batch = targets.sublist(i, end);

      final results = await Future.wait(batch.map(_resolveOne));

      for (var j = 0; j < batch.length; j++) {
        final phone = results[j];
        if (phone != null && phone.isNotEmpty) {
          resolved[batch[j].quotationId] = phone;
        }
      }
    }

    return resolved;
  }

  Future<String?> _resolveOne(ProductQuotation product) async {
    final customerId = await _resolveCustomerId(product);
    if (customerId == null) return null;

    final cached = _phoneByCustomerId[customerId];
    if (cached != null) return cached;

    try {
      final profile = await _authService.getProfile(customerId.toString());
      final phone = profile?['phone']?.trim() ?? '';
      if (phone.isEmpty) return null;

      _phoneByCustomerId[customerId] = phone;
      return phone;
    } catch (e) {
      return null;
    }
  }

  Future<int?> _resolveCustomerId(ProductQuotation product) async {
    if (product.customerId != null && product.customerId! > 0) {
      return product.customerId;
    }

    final cached = _customerIdByQuotationId[product.quotationId];
    if (cached != null) return cached;

    try {
      final detail =
          await _approvalService.getProductDetail(product.quotationId);
      if (detail.status != 'success' || detail.data.isEmpty) return null;

      final customerId = detail.data.first.customerId;
      if (customerId == null || customerId <= 0) return null;

      _customerIdByQuotationId[product.quotationId] = customerId;
      return customerId;
    } catch (e) {
      return null;
    }
  }

  static bool _isPhoneMissing(ProductQuotation product) =>
      product.phone == null || product.phone!.trim().isEmpty;

  /// จัดรูปแบบให้ตรงกับ ProductQuotation.formattedPhone
  ///
  /// คอลัมน์ต้นทางเป็น integer ศูนย์นำหน้าจึงหายตอนบันทึก
  /// get_customer_data.php ยังส่งมา 9 หลัก (805400699) ห้ามเอาการเติม 0
  /// ออกแม้ ERP จะเริ่มส่ง 10 หลักแล้ว เพราะเบอร์ที่นี่มาจาก HR-API ไม่ใช่ ERP
  ///
  /// เติมทีละหนึ่งตัวตามเงื่อนไขความยาว ไม่ pad เป็นความยาวตายตัว
  /// ไม่งั้นเบอร์บ้าน 021234567 ที่เก็บเหลือ 8 หลักจะกลายเป็น 0021234567
  static String format(String? phone) {
    final value = phone?.trim() ?? '';
    if (value.isEmpty) return '-';
    if (value.length == 9 && !value.startsWith('0')) return '0$value';
    return value;
  }

  /// เบอร์ที่พร้อมแสดง โดยใช้ค่าจาก API ก่อน แล้วค่อย fallback ไปที่ค่าที่หามาได้
  static String display(
    ProductQuotation product,
    Map<int, String> resolvedPhones,
  ) {
    if (!_isPhoneMissing(product)) return product.formattedPhone;
    return format(resolvedPhones[product.quotationId]);
  }
}
