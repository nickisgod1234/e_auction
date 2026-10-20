import 'dart:convert';
import 'dart:io';

import 'package:e_auction/models/technician_profile.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// เก็บประวัติช่างบนเครื่องนี้จนกว่าจะมี API
///
/// ข้อมูลไม่ถูกลบตอนออกจากระบบ เพื่อให้เจ้าหน้าที่บนเครื่องเดียวกันตรวจได้
class TechnicianProfileStore {
  static const _storageKey = 'technician_profiles_v1';

  static Future<List<TechnicianProfile>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => TechnicianProfile.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  static Future<TechnicianProfile?> loadByOwner(String ownerId) async {
    final profiles = await loadAll();
    for (final profile in profiles) {
      if (profile.ownerId == ownerId) return profile;
    }
    return null;
  }

  /// บันทึกแล้วกลับไปสถานะรออนุมัติทุกครั้งที่ช่างแก้ไข
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
    final savedPaths = <String>[
      ...keptPortfolioPaths,
      for (final file in newPortfolioFiles)
        await _copyIntoAppFolder(ownerId, 'portfolio', file),
    ];
    final savedCertificates = <String>[
      ...keptCertificatePaths,
      for (final file in newCertificateFiles)
        await _copyIntoAppFolder(ownerId, 'certificates', file),
    ];

    final profile = TechnicianProfile(
      id: ownerId,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      displayName: displayName.trim(),
      skills: skills,
      serviceArea: serviceArea.trim(),
      startingPrice: startingPrice,
      portfolioPaths: savedPaths,
      certificatePaths: savedCertificates,
      jobs: jobs
          .map((job) => TechnicianJob(
                title: job.title.trim(),
                detail: job.detail.trim(),
              ))
          .where((job) => job.title.isNotEmpty)
          .toList(),
      status: 0,
      reviewComment: null,
      updatedAt: DateTime.now().toIso8601String(),
    );

    final profiles = await loadAll();
    final index = profiles.indexWhere((item) => item.ownerId == ownerId);
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }
    await _write(profiles);
    return profile;
  }

  static Future<TechnicianProfile> review({
    required String id,
    required int status,
    String? comment,
  }) async {
    final profiles = await loadAll();
    final index = profiles.indexWhere((item) => item.id == id);
    if (index < 0) {
      throw Exception('ไม่พบประวัติช่าง');
    }

    final trimmed = comment?.trim();
    final updated = profiles[index].copyWith(
      status: status,
      clearComment: trimmed == null || trimmed.isEmpty,
      reviewComment: trimmed,
      updatedAt: DateTime.now().toIso8601String(),
    );
    profiles[index] = updated;
    await _write(profiles);
    return updated;
  }

  static Future<void> _write(List<TechnicianProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(profiles.map((profile) => profile.toJson()).toList()),
    );
  }

  static Future<String> _copyIntoAppFolder(
    String ownerId,
    String folderName,
    File file,
  ) async {
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory(
      path.join(root.path, 'technician_portfolio', ownerId, folderName),
    );
    await folder.create(recursive: true);
    final extension = path.extension(file.path);
    final name = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final saved = await file.copy(path.join(folder.path, name));
    return saved.path;
  }
}
