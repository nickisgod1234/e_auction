import 'dart:convert';

import 'package:e_auction/models/service_job.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ประกาศจ้างและราคาที่ช่างเสนอ เก็บในเครื่องเดียวกับประวัติช่าง
class ServiceJobStore {
  static const _jobKey = 'service_jobs_v1';
  static const _quoteKey = 'service_quotes_v1';

  static Future<List<ServiceJob>> loadJobs() async {
    final jobs = await _read(_jobKey, ServiceJob.fromJson);
    jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return jobs;
  }

  static Future<List<ServiceQuote>> quotesFor(String jobId) async {
    final quotes = await _read(_quoteKey, ServiceQuote.fromJson);
    final mine = quotes.where((quote) => quote.jobId == jobId).toList();
    mine.sort((a, b) => a.price.compareTo(b.price));
    return mine;
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
    final job = ServiceJob(
      id: '${ownerId}_${DateTime.now().microsecondsSinceEpoch}',
      ownerId: ownerId,
      ownerName: ownerName,
      skill: skill,
      title: title.trim(),
      detail: detail.trim(),
      area: area.trim(),
      budget: budget,
      status: ServiceJob.statusOpen,
      awardedQuoteId: null,
      createdAt: DateTime.now().toIso8601String(),
    );
    final jobs = await loadJobs();
    jobs.add(job);
    await _write(_jobKey, jobs.map((item) => item.toJson()).toList());
    return job;
  }

  static Future<ServiceQuote> submitQuote({
    required String jobId,
    required String technicianOwnerId,
    required String technicianName,
    required double price,
    required String note,
  }) async {
    final jobs = await loadJobs();
    final jobIndex = jobs.indexWhere((job) => job.id == jobId);
    if (jobIndex < 0) throw Exception('ไม่พบประกาศ');
    if (!jobs[jobIndex].isOpen) throw Exception('ประกาศนี้เลือกช่างแล้ว');
    if (jobs[jobIndex].ownerId == technicianOwnerId) {
      throw Exception('เสนอราคาในประกาศของตัวเองไม่ได้');
    }
    if (price <= 0) throw Exception('กรอกราคาให้มากกว่า 0');

    final quotes = await _read(_quoteKey, ServiceQuote.fromJson);
    final index = quotes.indexWhere(
      (quote) =>
          quote.jobId == jobId && quote.technicianOwnerId == technicianOwnerId,
    );
    final quote = ServiceQuote(
      id: index >= 0
          ? quotes[index].id
          : '${technicianOwnerId}_${DateTime.now().microsecondsSinceEpoch}',
      jobId: jobId,
      technicianOwnerId: technicianOwnerId,
      technicianName: technicianName,
      price: price,
      note: note.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
    if (index >= 0) {
      quotes[index] = quote;
    } else {
      quotes.add(quote);
    }
    await _write(_quoteKey, quotes.map((item) => item.toJson()).toList());
    return quote;
  }

  static Future<ServiceJob> award({
    required String jobId,
    required String ownerId,
    required String quoteId,
  }) async {
    final jobs = await loadJobs();
    final index = jobs.indexWhere((job) => job.id == jobId);
    if (index < 0) throw Exception('ไม่พบประกาศ');
    if (jobs[index].ownerId != ownerId) {
      throw Exception('เลือกช่างได้เฉพาะเจ้าของประกาศ');
    }
    final quotes = await quotesFor(jobId);
    final quote = quotes.cast<ServiceQuote?>().firstWhere(
          (item) => item?.id == quoteId,
          orElse: () => null,
        );
    if (quote == null) throw Exception('ไม่พบราคาที่เสนอ');

    final updated = ServiceJob(
      id: jobs[index].id,
      ownerId: jobs[index].ownerId,
      ownerName: jobs[index].ownerName,
      skill: jobs[index].skill,
      title: jobs[index].title,
      detail: jobs[index].detail,
      area: jobs[index].area,
      budget: jobs[index].budget,
      status: ServiceJob.statusAwarded,
      awardedQuoteId: quote.id,
      createdAt: jobs[index].createdAt,
    );
    jobs[index] = updated;
    await _write(_jobKey, jobs.map((item) => item.toJson()).toList());
    return updated;
  }

  static Future<List<T>> _read<T>(
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
