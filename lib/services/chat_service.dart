import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_auction/models/chat_models.dart';
import 'package:e_auction/views/config/config_prod.dart';

class ChatService {
  // static String get baseUrl => '${Config.apiUrlotplocalauction}api/chat';
  static String get baseUrl => '${Config.apiUrlotpsever}api/chat';
  
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  // สร้างหรือดึง session
  static Future<ChatApiResponse<Map<String, dynamic>>> createOrGetSession({
    required int customerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sessions.php'),
        headers: _headers,
        body: jsonEncode({
          'customer_id': customerId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse<Map<String, dynamic>>(
          success: data['success'] ?? false,
          message: data['message'] ?? 'ดำเนินการสำเร็จ',
          data: data['data'],
        );
      } else {
        return ChatApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการสร้าง session',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // ส่งข้อความ
  static Future<ChatApiResponse<Map<String, dynamic>>> sendMessage({
    required int sessionId,
    required int customerId,
    required String message,
    String senderType = 'customer',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages.php'),
        headers: _headers,
        body: jsonEncode({
          'session_id': sessionId,
          'sender_type': senderType,
          'sender_id': customerId,
          'message': message,
          'message_type': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return ChatApiResponse<Map<String, dynamic>>(
          success: data['success'] ?? false,
          message: data['message'] ?? 'ส่งข้อความสำเร็จ',
          data: data['data'],
        );
      } else {
        return ChatApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการส่งข้อความ',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // ดึงข้อความทั้งหมด
  static Future<ChatApiResponse<List<ChatMessage>>> getMessages({
    required int sessionId,
    required int customerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_messages.php?session_id=$sessionId&customer_id=$customerId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['data'] != null) {
          final messages = (data['data']['messages'] as List)
              .map((json) => ChatMessage.fromJson(json))
              .toList();
          return ChatApiResponse<List<ChatMessage>>(
            success: true,
            message: data['message'] ?? 'ดึงข้อความสำเร็จ',
            data: messages,
          );
        } else {
          return ChatApiResponse<List<ChatMessage>>(
            success: false,
            message: data['message'] ?? 'ไม่พบข้อความ',
            error: response.body,
          );
        }
      } else {
        return ChatApiResponse<List<ChatMessage>>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการดึงข้อความ',
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

  // ตรวจสอบข้อความใหม่
  static Future<ChatApiResponse<List<ChatMessage>>> checkNewMessages({
    required int sessionId,
    required int customerId,
    String? since, // เพิ่ม parameter since
  }) async {
    try {
      // สร้าง URL พร้อม parameters
      String url = '$baseUrl/new_messages.php?session_id=$sessionId&customer_id=$customerId';
      if (since != null) {
        url += '&since=$since';
      }
      
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['data'] != null) {
          // แก้ไข: data เป็น array โดยตรง ไม่ใช่ data.messages
          final messages = (data['data'] as List)
              .map((json) => ChatMessage.fromJson(json))
              .toList();
          return ChatApiResponse<List<ChatMessage>>(
            success: true,
            message: data['message'] ?? 'ดึงข้อความใหม่สำเร็จ',
            data: messages,
          );
        } else {
          return ChatApiResponse<List<ChatMessage>>(
            success: false,
            message: data['message'] ?? 'ไม่พบข้อความใหม่',
            data: [],
          );
        }
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

  // Mark messages as read
  static Future<ChatApiResponse<Map<String, dynamic>>> markMessagesAsRead({
    required int sessionId,
    required String recipientType, // 'customer' หรือ 'admin'
    required int recipientId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/mark_read.php?session_id=$sessionId'),
        headers: _headers,
        body: jsonEncode({
          'recipient_type': recipientType,
          'recipient_id': recipientId,
        }),
      );

      print('ChatService.markMessagesAsRead URL: $baseUrl/mark_read.php?session_id=$sessionId');
      print('ChatService.markMessagesAsRead Body: recipient_type=$recipientType, recipient_id=$recipientId');
      print('ChatService.markMessagesAsRead Response: ${response.statusCode}');
      print('ChatService.markMessagesAsRead Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse<Map<String, dynamic>>(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Mark messages as read successfully',
          data: data['data'],
        );
      } else {
        return ChatApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการ mark messages as read',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // ส่งสัญญาณกำลังพิมพ์ (Typing Indicator)
  static Future<ChatApiResponse<Map<String, dynamic>>> sendTypingIndicator({
    required int sessionId,
    required int customerId,
    required String senderType, // 'customer' หรือ 'admin'
    required bool isTyping, // true = กำลังพิมพ์, false = หยุดพิมพ์
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/typing_indicator.php'),
        headers: _headers,
        body: jsonEncode({
          'session_id': sessionId,
          'customer_id': customerId,
          'sender_type': senderType,
          'is_typing': isTyping,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse<Map<String, dynamic>>(
          success: data['success'] ?? false,
          message: data['message'] ?? 'ส่งสัญญาณสำเร็จ',
          data: data['data'],
        );
      } else {
        return ChatApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการส่งสัญญาณ',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // ดูรายการ session ที่รอตอบกลับ (สำหรับ Admin)
  static Future<ChatApiResponse<List<Map<String, dynamic>>>> getPendingSessions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pending_sessions.php?page=$page&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
     
        
        if (data['success'] && data['data'] != null) {
          return ChatApiResponse<List<Map<String, dynamic>>>(
            success: true,
            message: data['message'] ?? 'ดึงข้อมูลสำเร็จ',
            data: List<Map<String, dynamic>>.from(data['data']['sessions']),
          );
        } else {
          return ChatApiResponse<List<Map<String, dynamic>>>(
            success: false,
            message: data['message'] ?? 'ไม่พบข้อมูล',
            error: response.body,
          );
        }
      } else {
        return ChatApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการดึงรายการที่รอตอบกลับ',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // ดูรายการ session ทั้งหมด (สำหรับ Admin)
  static Future<ChatApiResponse<List<Map<String, dynamic>>>> getAllSessions({
    String status = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all_sessions.php?status=$status&page=$page&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] && data['data'] != null) {
          return ChatApiResponse<List<Map<String, dynamic>>>(
            success: true,
            message: data['message'] ?? 'ดึงข้อมูลสำเร็จ',
            data: List<Map<String, dynamic>>.from(data['data']['sessions']),
          );
        } else {
          return ChatApiResponse<List<Map<String, dynamic>>>(
            success: false,
            message: data['message'] ?? 'ไม่พบข้อมูล',
            error: response.body,
          );
        }
      } else {
        return ChatApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการดึงรายการทั้งหมด',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // ดูรายการ session ของ admin ที่รับผิดชอบ
  static Future<ChatApiResponse<List<Map<String, dynamic>>>> getMySessions({
    required int adminId,
    String status = 'active',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my_sessions.php?admin_id=$adminId&status=$status&page=$page&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
          
        if (data['success'] && data['data'] != null) {
          return ChatApiResponse<List<Map<String, dynamic>>>(
            success: true,
            message: data['message'] ?? 'ดึงข้อมูลสำเร็จ',
            data: List<Map<String, dynamic>>.from(data['data']['sessions']),
          );
        } else {
          return ChatApiResponse<List<Map<String, dynamic>>>(
            success: false,
            message: data['message'] ?? 'ไม่พบข้อมูล',
            error: response.body,
          );
        }
      } else {
        return ChatApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการดึงรายการที่ดูแล',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // รับผิดชอบ session (Assign Admin)
  static Future<ChatApiResponse<Map<String, dynamic>>> assignAdmin({
    required int sessionId,
    required int adminId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/assign_admin.php'),
        headers: _headers,
        body: jsonEncode({
          'session_id': sessionId,
          'admin_id': adminId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse<Map<String, dynamic>>(
          success: data['success'] ?? false,
          message: data['message'] ?? 'ดำเนินการสำเร็จ',
          data: data['data'],
        );
      } else {
        return ChatApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการรับผิดชอบ session',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }

  // ปิด session (สำหรับ Admin)
  static Future<ChatApiResponse<Map<String, dynamic>>> closeSessionByAdmin({
    required int sessionId,
    required int adminId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/close_session.php'),
        headers: _headers,
        body: jsonEncode({
          'session_id': sessionId,
          'admin_id': adminId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatApiResponse<Map<String, dynamic>>(
          success: data['success'] ?? false,
          message: data['message'] ?? 'ปิด session สำเร็จ',
          data: data['data'],
        );
      } else {
        return ChatApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'เกิดข้อผิดพลาดในการปิด session',
          error: response.body,
        );
      }
    } catch (e) {
      return ChatApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        error: e.toString(),
      );
    }
  }
}