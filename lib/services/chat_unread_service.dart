import 'package:e_auction/services/chat_service.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// นับจำนวนข้อความจากเจ้าหน้าที่ที่ลูกค้ายังไม่ได้อ่าน
///
/// API ฝั่งลูกค้าไม่มี endpoint ที่คืน unread_count มาให้ (มีแต่ฝั่ง admin)
/// จึงต้องดึงข้อความทั้งหมดของ session แล้วนับฝั่งแอปเอง
class ChatUnreadService {
  static const String _sessionIdKey = 'chat_session_id';

  /// id ของบัญชีสำหรับรีวิวแอป ไม่มี session จริงบนเซิร์ฟเวอร์
  static const int _demoCustomerId = 999;

  /// จำนวนข้อความที่ยังไม่อ่าน คืน 0 เมื่อยังไม่ล็อกอินหรือดึงข้อมูลไม่ได้
  ///
  /// ไม่โยน exception ออกไป เพราะถูกเรียกจาก UI ที่แสดง badge เท่านั้น
  static Future<int> getUnreadCount() async {
    try {
      final customerId = await UserDataManager.getCustomerID();
      if (customerId == null || customerId == _demoCustomerId) {
        return 0;
      }

      final sessionId = await _resolveSessionId(customerId);
      if (sessionId == null) return 0;

      final response = await ChatService.getMessages(
        sessionId: sessionId,
        customerId: customerId,
      );
      if (!response.success || response.data == null) return 0;

      return response.data!
          .where((message) => message.isFromAdmin && !message.isRead)
          .length;
    } catch (e) {
      return 0;
    }
  }

  /// ลบ session ที่จำไว้ ใช้ตอน logout เพื่อไม่ให้ผู้ใช้คนถัดไปใช้ session เดิม
  static Future<void> clearCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionIdKey);
  }

  /// จำ session id ไว้เพื่อไม่ต้อง POST สร้าง session ใหม่ทุกครั้งที่นับ
  static Future<int?> _resolveSessionId(int customerId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedId = prefs.getInt(_sessionIdKey);
    if (cachedId != null && cachedId > 0) {
      return cachedId;
    }

    final response = await ChatService.createOrGetSession(
      customerId: customerId,
    );
    if (!response.success || response.data == null) return null;

    final sessionId = _parseInt(response.data!['id']);
    if (sessionId == null || sessionId <= 0) return null;

    await prefs.setInt(_sessionIdKey, sessionId);
    return sessionId;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
