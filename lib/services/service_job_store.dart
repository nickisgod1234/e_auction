import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:e_auction/models/service_job.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ประกาศจ้างและราคาที่ช่างเสนออยู่ที่ ERP-Cloudmate
class ServiceJobStore {
  static const _jobKey = 'service_jobs_v1';
  static const _quoteKey = 'service_quotes_v1';
  static const Duration _timeout = Duration(seconds: 30);

  static Future<List<ServiceJob>> loadJobs() async {
    await _migrateLocal();
    final data = await _post({'action': 'jobs'});
    if (data is! List) return [];
    final jobs = data
        .whereType<Map>()
        .map((item) => ServiceJob.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return jobs;
  }

  static Future<List<ServiceQuote>> quotesFor(String jobId) async {
    final data = await _post({
      'action': 'quotes',
      'job_id': jobId,
    });
    if (data is! List) return [];
    final quotes = data
        .whereType<Map>()
        .map((item) => ServiceQuote.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    quotes.sort((a, b) => a.price.compareTo(b.price));
    return quotes;
  }

  static Future<ServiceJob> create({
    required String ownerId,
    required String ownerName,
    required String skill,
    required String title,
    required String detail,
    required String area,
    double? budget,
  }) async {
    final data = await _post({
      'action': 'create_job',
      'owner_id': ownerId,
      'owner_name': ownerName,
      'skill': skill,
      'title': title.trim(),
      'detail': detail.trim(),
      'area': area.trim(),
      'budget': budget,
    });
    if (data is! Map) {
      throw Exception('บันทึกประกาศไม่สำเร็จ');
    }
    return ServiceJob.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<ServiceQuote> submitQuote({
    required String jobId,
    required String technicianOwnerId,
    required String technicianName,
    required double price,
    required String note,
  }) async {
    final data = await _post({
      'action': 'submit_quote',
      'job_id': jobId,
      'technician_customer_id': technicianOwnerId,
      'technician_name': technicianName,
      'price': price,
      'note': note.trim(),
    });
    if (data is! Map) {
      throw Exception('ส่งราคาไม่สำเร็จ');
    }
    return ServiceQuote.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<ServiceJob> award({
    required String jobId,
    required String ownerId,
    required String quoteId,
  }) async {
    final data = await _post({
      'action': 'award_job',
      'job_id': jobId,
      'owner_id': ownerId,
      'quote_id': quoteId,
    });
    if (data is! Map) {
      throw Exception('เลือกช่างไม่สำเร็จ');
    }
    return ServiceJob.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<void> _migrateLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJobs = prefs.getString(_jobKey);
    if (rawJobs == null || rawJobs.isEmpty) return;
    final decodedJobs = jsonDecode(rawJobs);
    final decodedQuotes = jsonDecode(prefs.getString(_quoteKey) ?? '[]');
    if (decodedJobs is! List || decodedJobs.isEmpty) {
      await prefs.remove(_jobKey);
      await prefs.remove(_quoteKey);
      return;
    }

    final jobs = decodedJobs
        .whereType<Map>()
        .map((item) => ServiceJob.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final quotes = decodedQuotes is List
        ? decodedQuotes
            .whereType<Map>()
            .map((item) => ServiceQuote.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <ServiceQuote>[];
    final savedMap = prefs.getString('service_jobs_id_map_v1');
    final idMap = <String, String>{};
    if (savedMap != null && savedMap.isNotEmpty) {
      final decodedMap = jsonDecode(savedMap);
      if (decodedMap is Map) {
        decodedMap.forEach((key, value) {
          idMap[key.toString()] = value.toString();
        });
      }
    }

    for (final job in jobs) {
      if (idMap.containsKey(job.id)) continue;
      final created = await create(
        ownerId: job.ownerId,
        ownerName: job.ownerName,
        skill: job.skill,
        title: job.title,
        detail: job.detail,
        area: job.area,
        budget: job.budget,
      );
      idMap[job.id] = created.id;
      await prefs.setString('service_jobs_id_map_v1', jsonEncode(idMap));
    }
    final quoteIdMap = <String, String>{};
    for (final quote in quotes) {
      final jobId = idMap[quote.jobId];
      if (jobId == null) continue;
      final created = await submitQuote(
        jobId: jobId,
        technicianOwnerId: quote.technicianOwnerId,
        technicianName: quote.technicianName,
        price: quote.price,
        note: quote.note,
      );
      quoteIdMap[quote.id] = created.id;
    }
    for (final job in jobs) {
      final quoteId = job.awardedQuoteId;
      final newJobId = idMap[job.id];
      final newQuoteId = quoteId == null ? null : quoteIdMap[quoteId];
      if (!job.isOpen && newJobId != null && newQuoteId != null) {
        await award(jobId: newJobId, ownerId: job.ownerId, quoteId: newQuoteId);
      }
    }
    await prefs.remove(_jobKey);
    await prefs.remove(_quoteKey);
    await prefs.remove('service_jobs_id_map_v1');
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
