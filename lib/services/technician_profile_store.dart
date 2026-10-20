import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:e_auction/models/technician_profile.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// ประวัติช่างอยู่ที่ ERP-Cloudmate เพื่อให้เครื่องอื่นและงานประมูลใช้ชุดเดียวกัน
class TechnicianProfileStore {
  static const Duration _timeout = Duration(seconds: 30);

  static Future<List<TechnicianProfile>> loadAll() async {
    final data = await _get();
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => TechnicianProfile.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  static Future<TechnicianProfile?> loadByOwner(String ownerId) async {
    final data = await _get({'customer_id': ownerId});
    if (data is! List || data.isEmpty) return null;
    final first = data.first;
    if (first is! Map) return null;
    return TechnicianProfile.fromJson(Map<String, dynamic>.from(first));
  }

  static Future<TechnicianProfile> submit({
    required String ownerId,
    required String ownerName,
    required String ownerPhone,
    required String displayName,
    required List<String> skills,
    required String serviceArea,
    required double startingPrice,
    required List<String> keptPortfolioPaths,
    required List<File> newPortfolioFiles,
    required List<String> keptCertificatePaths,
    required List<File> newCertificateFiles,
    required List<TechnicianJob> jobs,
  }) async {
    final portfolioKept = _keptIds(keptPortfolioPaths);
    final certificateKept = _keptIds(keptCertificatePaths);
    final portfolioImages = [
      ...await _encodeLocal(keptPortfolioPaths),
      ...await _encodeFiles(newPortfolioFiles),
    ];
    final certificateImages = [
      ...await _encodeLocal(keptCertificatePaths),
      ...await _encodeFiles(newCertificateFiles),
    ];

    final data = await _post({
      'action': 'submit',
      'customer_id': ownerId,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'display_name': displayName,
      'skills': skills,
      'service_area': serviceArea,
      'starting_price': startingPrice,
      'jobs': jobs
          .map((job) => {'title': job.title, 'detail': job.detail})
          .toList(),
      'keep_portfolio_ids': portfolioKept,
      'keep_certificate_ids': certificateKept,
      'portfolio_images': portfolioImages,
      'certificate_images': certificateImages,
    });
    if (data is! Map) {
      throw Exception('บันทึกประวัติไม่สำเร็จ');
    }
    return TechnicianProfile.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<TechnicianProfile> review({
    required String id,
    required int status,
    String? comment,
  }) async {
    final data = await _post({
      'action': 'review',
      'id': int.tryParse(id) ?? id,
      'status': status,
      'comment': comment ?? '',
    });
    if (data is! Map) {
      throw Exception('บันทึกผลการตรวจไม่สำเร็จ');
    }
    return TechnicianProfile.fromJson(Map<String, dynamic>.from(data));
  }

  static List<int> _keptIds(List<String> paths) {
    final ids = <int>[];
    for (final item in paths) {
      if (!item.startsWith('http')) continue;
      final name = path.basename(Uri.parse(item).path);
      final match = RegExp(r'^(\d+)_').firstMatch(name);
      final id = match == null ? null : int.tryParse(match.group(1)!);
      if (id != null) ids.add(id);
    }
    return ids;
  }

  static Future<List<Map<String, String>>> _encodeLocal(List<String> paths) async {
    final images = <Map<String, String>>[];
    for (final item in paths) {
      if (item.startsWith('http')) continue;
      final file = File(item);
      if (!await file.exists()) continue;
      images.add(await _encodeFile(file));
    }
    return images;
  }

  static Future<List<Map<String, String>>> _encodeFiles(List<File> files) async {
    final images = <Map<String, String>>[];
    for (final file in files) {
      images.add(await _encodeFile(file));
    }
    return images;
  }

  static Future<Map<String, String>> _encodeFile(File file) async {
    final bytes = await file.readAsBytes();
    return {
      'name': path.basename(file.path),
      'data': base64Encode(bytes),
    };
  }

  static Future<dynamic> _get([Map<String, String>? query]) async {
    final uri = Uri.parse(Config.technicianApiUrl).replace(
      queryParameters: query,
    );
    try {
      final response = await http.get(uri).timeout(_timeout);
      return _decode(response);
    } on SocketException {
      throw Exception('เชื่อมต่อ ERP-Cloudmate ไม่ได้');
    } on TimeoutException {
      throw Exception('ERP-Cloudmate ตอบช้า ลองใหม่อีกครั้ง');
    }
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
      return _decode(response);
    } on SocketException {
      throw Exception('เชื่อมต่อ ERP-Cloudmate ไม่ได้');
    } on TimeoutException {
      throw Exception('ERP-Cloudmate ตอบช้า ลองใหม่อีกครั้ง');
    }
  }

  static dynamic _decode(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('ข้อมูลจาก ERP ไม่ถูกต้อง');
    }
    if (response.statusCode >= 400 || decoded['status'] == 'error') {
      throw Exception(decoded['message']?.toString() ?? 'ERP ตอบกลับไม่สำเร็จ');
    }
    return decoded['data'];
  }
}
