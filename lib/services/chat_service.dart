import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_auction/models/chat_models.dart';

class ChatService {
  static const String baseUrl = 'https://your-api-domain.com/api/chat';
  
  // Headers สำหรับ API calls
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // สร้างหรือดึงข้อมูลการสนทนาของผู้ใช้
  static Future<ChatApiResponse<ChatSession>> createOrGetSession(String phoneId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sessions'),
        headers: _headers,
        body: jsonEncode({
          'phone_id': phoneId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse.fromJson(data, (json) => ChatSession.fromJson(json));
      } else {
        return ChatApiResponse<ChatSession>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการสร้างการสนทนา',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<ChatSession>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // ส่งข้อความใหม่
  static Future<ChatApiResponse<ChatMessage>> sendMessage({
    required int sessionId,
    required String senderType,
    required String senderId,
    required String message,
    String messageType = 'text',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: _headers,
        body: jsonEncode({
          'session_id': sessionId,
          'sender_type': senderType,
          'sender_id': senderId,
          'message': message,
          'message_type': messageType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse.fromJson(data, (json) => ChatMessage.fromJson(json));
      } else {
        return ChatApiResponse<ChatMessage>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการส่งข้อความ',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<ChatMessage>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // ดึงข้อความทั้งหมดของการสนทนา
  static Future<ChatApiResponse<ChatListResponse>> getMessages({
    required int sessionId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId/messages?page=$page&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse.fromJson(data, (json) => ChatListResponse.fromJson(json));
      } else {
        return ChatApiResponse<ChatListResponse>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการดึงข้อความ',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<ChatListResponse>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // อัปเดตสถานะการอ่านข้อความ
  static Future<ChatApiResponse<bool>> markMessagesAsRead({
    required int sessionId,
    required String recipientType,
    required String recipientId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/sessions/$sessionId/mark-read'),
        headers: _headers,
        body: jsonEncode({
          'recipient_type': recipientType,
          'recipient_id': recipientId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse.fromJson(data, (json) => json as bool);
      } else {
        return ChatApiResponse<bool>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการอัปเดตสถานะการอ่าน',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<bool>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // ดึงการแจ้งเตือนของผู้ใช้
  static Future<ChatApiResponse<List<ChatNotification>>> getNotifications({
    required String phoneId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?phone_id=$phoneId&page=$page&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse.fromJson(
          data, 
          (json) => (json as List).map((notification) => ChatNotification.fromJson(notification)).toList()
        );
      } else {
        return ChatApiResponse<List<ChatNotification>>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการดึงการแจ้งเตือน',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<List<ChatNotification>>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // อัปเดตสถานะการอ่านการแจ้งเตือน
  static Future<ChatApiResponse<bool>> markNotificationAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse.fromJson(data, (json) => json as bool);
      } else {
        return ChatApiResponse<bool>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการอัปเดตสถานะการอ่าน',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<bool>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // ปิดการสนทนา
  static Future<ChatApiResponse<bool>> closeSession(int sessionId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/sessions/$sessionId/close'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse.fromJson(data, (json) => json as bool);
      } else {
        return ChatApiResponse<bool>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการปิดการสนทนา',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<bool>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // ดึงข้อมูล admin ที่รับผิดชอบการสนทนา
  static Future<ChatApiResponse<ChatAdmin?>> getSessionAdmin(int sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId/admin'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse.fromJson(
          data, 
          (json) => json != null ? ChatAdmin.fromJson(json) : null
        );
      } else {
        return ChatApiResponse<ChatAdmin?>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการดึงข้อมูล admin',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<ChatAdmin?>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // ตรวจสอบข้อความใหม่ (สำหรับ polling)
  static Future<ChatApiResponse<List<ChatMessage>>> checkNewMessages({
    required int sessionId,
    required DateTime lastMessageTime,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId/new-messages?since=${lastMessageTime.toIso8601String()}'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse.fromJson(
          data, 
          (json) => (json as List).map((message) => ChatMessage.fromJson(message)).toList()
        );
      } else {
        return ChatApiResponse<List<ChatMessage>>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการตรวจสอบข้อความใหม่',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<List<ChatMessage>>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // อัปโหลดไฟล์แนบ
  static Future<ChatApiResponse<ChatAttachment>> uploadAttachment({
    required int messageId,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String fileType,
  }) async {
    try {
      // สร้าง multipart request สำหรับอัปโหลดไฟล์
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/attachments'),
      );
      
      request.headers.addAll(_headers);
      request.fields['message_id'] = messageId.toString();
      request.fields['file_name'] = fileName;
      request.fields['file_size'] = fileSize.toString();
      request.fields['file_type'] = fileType;
      
      // เพิ่มไฟล์
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return ChatApiResponse.fromJson(data, (json) => ChatAttachment.fromJson(json));
      } else {
        return ChatApiResponse<ChatAttachment>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการอัปโหลดไฟล์',
          error: responseBody,
        );
      }
    } catch (e) {
      return ChatApiResponse<ChatAttachment>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }
}
