import 'package:e_auction/services/chat_service.dart';
import 'package:e_auction/services/product_approval_service.dart';

/// ส่งข้อความแจ้งผลการอนุมัติสินค้าเข้าแชทของผู้ลงสินค้า
///
/// การอนุมัติอยู่บน ERP (cm-erp-prd) แต่แชทอยู่บน HR-API-morket
/// จึงต้องแยกการเรียกออกจากกัน และไม่ให้ผลลัพธ์ของแชทกระทบการอนุมัติ
class ApprovalChatNotifier {
  ApprovalChatNotifier({ProductApprovalService? approvalService})
      : _approvalService =
            approvalService ?? ProductApprovalService.defaultInstance();

  final ProductApprovalService _approvalService;

  /// ส่งข้อความแจ้งผลไปยังเจ้าของสินค้า
  ///
  /// [status] ใช้ค่าเดียวกับ API อนุมัติ คือ 'approved' หรือ 'rejected'
  /// [adminUserId] คือ id ของ admin ที่กดอนุมัติ ใช้เป็น sender_id ของข้อความ
  Future<SimpleApiResponse> notifyOwner({
    required ProductQuotation product,
    required String status,
    required int adminUserId,
    String? comment,
  }) async {
    final ownerId = await _resolveOwnerId(product);
    if (ownerId == null) {
      return SimpleApiResponse(
        success: false,
        message: 'ไม่พบรหัสผู้ลงสินค้า',
      );
    }

    final sessionResponse = await ChatService.createOrGetSession(
      customerId: ownerId,
    );
    if (!sessionResponse.success || sessionResponse.data == null) {
      return SimpleApiResponse(
        success: false,
        message: sessionResponse.message,
      );
    }

    final sessionId = _parseInt(sessionResponse.data!['id']);
    if (sessionId == null) {
      return SimpleApiResponse(
        success: false,
        message: 'ไม่พบ session ของแชท',
      );
    }

    final messageResponse = await ChatService.sendMessage(
      sessionId: sessionId,
      customerId: adminUserId,
      message: buildMessage(
        product: product,
        status: status,
        comment: comment,
      ),
      senderType: 'admin',
    );

    return SimpleApiResponse(
      success: messageResponse.success,
      message: messageResponse.message,
    );
  }

  /// สร้างข้อความแจ้งผล ถ้า admin ไม่ได้พิมพ์คอมเมนต์จะใช้ข้อความมาตรฐาน
  static String buildMessage({
    required ProductQuotation product,
    required String status,
    String? comment,
  }) {
    final isApproved = status == 'approved';
    final productName = (product.description?.trim().isNotEmpty ?? false)
        ? product.description!.trim()
        : 'ไม่ระบุชื่อสินค้า';

    final lines = <String>[
      'แจ้งผลการอนุมัติสินค้า',
      '',
      'สินค้า: $productName',
      'รหัสรายการ: #${product.quotationId}',
      'สถานะ: ${isApproved ? 'อนุมัติแล้ว' : 'ไม่ผ่านการอนุมัติ'}',
      '',
      isApproved
          ? 'สินค้าของคุณผ่านการอนุมัติเรียบร้อยแล้ว พร้อมเข้าร่วมประมูลตามวันและเวลาที่กำหนด'
          : 'สินค้าของคุณยังไม่ผ่านการอนุมัติ หากต้องการทราบรายละเอียดเพิ่มเติม สามารถตอบกลับข้อความนี้เพื่อสอบถามเจ้าหน้าที่ได้',
    ];

    final trimmedComment = comment?.trim() ?? '';
    if (trimmedComment.isNotEmpty) {
      lines.addAll(['', 'หมายเหตุจากเจ้าหน้าที่: $trimmedComment']);
    }

    return lines.join('\n');
  }

  /// รายการรออนุมัติไม่ส่ง customer_id มา จึงต้องดึงจากรายละเอียดอีกครั้ง
  Future<int?> _resolveOwnerId(ProductQuotation product) async {
    if (product.customerId != null && product.customerId! > 0) {
      return product.customerId;
    }

    final detail = await _approvalService.getProductDetail(product.quotationId);
    if (detail.status != 'success' || detail.data.isEmpty) {
      return null;
    }

    final ownerId = detail.data.first.customerId;
    return (ownerId != null && ownerId > 0) ? ownerId : null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
