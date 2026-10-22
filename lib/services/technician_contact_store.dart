import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:e_auction/models/technician_contact.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// แชทช่างและรีวิวอยู่ที่ ERP-Cloudmate
class TechnicianContactStore {
  static const _reviewKey = 'technician_reviews_v1';
  static const Duration _timeout = Duration(seconds: 30);

  static Future<List<TechnicianReview>> loadReviews() async {
    await _migrateLocalReviews();
    final data = await _post({'action': 'reviews'});
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => TechnicianReview.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<TechnicianThread?> threadFor({
    required String customerId,
    required String technicianOwnerId,
  }) async {
    final data = await _post({
      'action': 'thread',
      'customer_id': customerId,
      'technician_customer_id': technicianOwnerId,
    });
    if (data is! Map) return null;
    return TechnicianThread.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<List<TechnicianThread>> threadsForTechnician(
    String technicianOwnerId,
  ) async {
    final data = await _post({
      'action': 'threads',
      'technician_customer_id': technicianOwnerId,
    });
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => TechnicianThread.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<List<TechnicianReview>> reviewsFor(
    String technicianOwnerId,
  ) async {
    await _migrateLocalReviews();
    final data = await _post({
      'action': 'reviews',
      'technician_customer_id': technicianOwnerId,
    });
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => TechnicianReview.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<TechnicianThread> send({
    required String customerId,
    required String customerName,
    required String technicianOwnerId,
    required String technicianName,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('พิมพ์ข้อความก่อนส่ง');
    }

    final data = await _post({
      'action': 'send',
      'customer_id': customerId,
      'customer_name': customerName,
      'technician_customer_id': technicianOwnerId,
      'technician_name': technicianName,
      'sender_id': senderId,
      'text': trimmed,
    });
    if (data is! Map) {
      throw Exception('ส่งข้อความไม่สำเร็จ');
    }
    return TechnicianThread.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<TechnicianReview> saveReview({
    required String customerId,
    required String customerName,
    required String technicianOwnerId,
    required int stars,
    required String comment,
  }) async {
    if (stars < 1 || stars > 5) {
      throw Exception('ให้คะแนน 1 ถึง 5 ดาว');
    }
    await _migrateLocalReviews();
    final data = await _post({
      'action': 'save_review',
      'customer_id': customerId,
      'customer_name': customerName,
      'technician_customer_id': technicianOwnerId,
      'stars': stars,
      'comment': comment.trim(),
    });
    if (data is! Map) {
      throw Exception('บันทึกรีวิวไม่สำเร็จ');
    }
    return TechnicianReview.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<void> _migrateLocalReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reviewKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.isEmpty) {
      await prefs.remove(_reviewKey);
      return;
    }
    for (final item in decoded.whereType<Map>()) {
      final review = TechnicianReview.fromJson(Map<String, dynamic>.from(item));
      if (review.customerId.isEmpty || review.technicianOwnerId.isEmpty) continue;
      await _post({
        'action': 'save_review',
        'customer_id': review.customerId,
        'customer_name': review.customerName,
        'technician_customer_id': review.technicianOwnerId,
        'stars': review.stars,
        'comment': review.comment,
      });
    }
    await prefs.remove(_reviewKey);
  }

  static Future<dynamic> _post(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse(Config.technicianApiUrl),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw Exception('ข้อมูลจาก ERP ไม่ถูกต้อง');
      }
      if (response.statusCode >= 400 || decoded['status'] == 'error') {
        throw Exception(decoded['message']?.toString() ?? 'ERP ตอบกลับไม่สำเร็จ');
      }
      return decoded['data'];
    } on SocketException {
      throw Exception('เชื่อมต่อ ERP-Cloudmate ไม่ได้');
    } on TimeoutException {
      throw Exception('ERP-Cloudmate ตอบช้า ลองใหม่อีกครั้ง');
    }
  }
}
