import 'dart:convert';

import 'package:e_auction/models/technician_contact.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ข้อความและรีวิวระหว่างผู้ใช้กับช่าง เก็บในเครื่องเดียวกับประวัติช่าง
class TechnicianContactStore {
  static const _threadKey = 'technician_threads_v1';
  static const _reviewKey = 'technician_reviews_v1';

  static Future<List<TechnicianThread>> loadThreads() async {
    return _readList(_threadKey, TechnicianThread.fromJson);
  }

  static Future<List<TechnicianReview>> loadReviews() async {
    return _readList(_reviewKey, TechnicianReview.fromJson);
  }

  static Future<TechnicianThread?> threadFor({
    required String customerId,
    required String technicianOwnerId,
  }) async {
    final id = TechnicianThread.makeId(customerId, technicianOwnerId);
    final threads = await loadThreads();
    for (final thread in threads) {
      if (thread.id == id) return thread;
    }
    return null;
  }

  static Future<List<TechnicianThread>> threadsForTechnician(
    String technicianOwnerId,
  ) async {
    final threads = await loadThreads();
    final mine = threads
        .where((thread) => thread.technicianOwnerId == technicianOwnerId)
        .toList();
    mine.sort((a, b) {
      final aTime = a.lastMessage?.sentAt ?? '';
      final bTime = b.lastMessage?.sentAt ?? '';
      return bTime.compareTo(aTime);
    });
    return mine;
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

    final threads = await loadThreads();
    final id = TechnicianThread.makeId(customerId, technicianOwnerId);
    final index = threads.indexWhere((thread) => thread.id == id);
    final existing = index >= 0
        ? threads[index]
        : TechnicianThread(
            id: id,
            customerId: customerId,
            customerName: customerName,
            technicianOwnerId: technicianOwnerId,
            technicianName: technicianName,
            messages: const [],
          );
    final next = TechnicianThread(
      id: existing.id,
      customerId: existing.customerId,
      customerName: customerName.isEmpty ? existing.customerName : customerName,
      technicianOwnerId: existing.technicianOwnerId,
      technicianName: technicianName.isEmpty
          ? existing.technicianName
          : technicianName,
      messages: [
        ...existing.messages,
        TechnicianMessage(
          senderId: senderId,
          text: trimmed,
          sentAt: DateTime.now().toIso8601String(),
        ),
      ],
    );
    if (index >= 0) {
      threads[index] = next;
    } else {
      threads.add(next);
    }
    await _write(_threadKey, threads.map((thread) => thread.toJson()).toList());
    return next;
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
}
