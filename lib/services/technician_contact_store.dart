import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:e_auction/models/technician_contact.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// แชทช่างอยู่ที่ ERP-Cloudmate รีวิวยังเก็บบนเครื่อง
class TechnicianContactStore {
  static const _reviewKey = 'technician_reviews_v1';
  static const Duration _timeout = Duration(seconds: 30);

  static Future<List<TechnicianReview>> loadReviews() async {
    return _readList(_reviewKey, TechnicianReview.fromJson);
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
    final reviews = await loadReviews();
    return reviews
        .where((review) => review.technicianOwnerId == technicianOwnerId)
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
    final reviews = await loadReviews();
    final index = reviews.indexWhere(
      (review) =>
          review.customerId == customerId &&
          review.technicianOwnerId == technicianOwnerId,
    );
    final review = TechnicianReview(
      customerId: customerId,
      customerName: customerName,
      technicianOwnerId: technicianOwnerId,
      stars: stars,
      comment: comment.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
    if (index >= 0) {
      reviews[index] = review;
    } else {
      reviews.add(review);
    }
    await _write(_reviewKey, reviews.map((item) => item.toJson()).toList());
    return review;
  }

  static Future<List<T>> _readList<T>(
    String key,
    T Function(Map<String, dynamic>) decode,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => decode(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> _write(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
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
