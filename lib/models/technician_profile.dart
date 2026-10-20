/// ประวัติช่างที่ส่งให้เจ้าหน้าที่ตรวจ ก่อนจะเปิดให้ผู้ใช้คนอื่นค้นหา
class TechnicianJob {
  final String title;
  final String detail;

  const TechnicianJob({required this.title, this.detail = ''});

  Map<String, dynamic> toJson() => {'title': title, 'detail': detail};

  factory TechnicianJob.fromJson(Map<String, dynamic> json) {
    return TechnicianJob(
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
    );
  }
}

class TechnicianProfile {
  static const skillOptions = [
    'แอร์',
    'ไฟฟ้า',
    'ประปา',
    'สี',
    'ต่อเติม',
    'ทำความสะอาด',
    'เครื่องใช้ไฟฟ้า',
  ];

  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String displayName;
  final List<String> skills;
  final String serviceArea;
  final double startingPrice;
  final List<String> portfolioPaths;
  final List<String> certificatePaths;
  final List<TechnicianJob> jobs;

  /// 0 รออนุมัติ, 1 อนุมัติแล้ว, 2 ปฏิเสธ
  final int status;
  final String? reviewComment;
  final String updatedAt;

  const TechnicianProfile({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.displayName,
    required this.skills,
    required this.serviceArea,
    required this.startingPrice,
    required this.portfolioPaths,
    this.certificatePaths = const [],
    required this.jobs,
    required this.status,
    required this.reviewComment,
    required this.updatedAt,
  });

  String get statusLabel {
    switch (status) {
      case 1:
        return 'อนุมัติแล้ว';
      case 2:
        return 'ปฏิเสธ';
      default:
        return 'รออนุมัติ';
    }
  }

  TechnicianProfile copyWith({
    int? status,
    String? reviewComment,
    bool clearComment = false,
    String? updatedAt,
  }) {
    return TechnicianProfile(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      displayName: displayName,
      skills: skills,
      serviceArea: serviceArea,
      startingPrice: startingPrice,
      portfolioPaths: portfolioPaths,
      certificatePaths: certificatePaths,
      jobs: jobs,
      status: status ?? this.status,
      reviewComment: clearComment ? null : (reviewComment ?? this.reviewComment),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,
        'displayName': displayName,
        'skills': skills,
        'serviceArea': serviceArea,
        'startingPrice': startingPrice,
        'portfolioPaths': portfolioPaths,
        'certificatePaths': certificatePaths,
        'jobs': jobs.map((job) => job.toJson()).toList(),
        'status': status,
        'reviewComment': reviewComment,
        'updatedAt': updatedAt,
      };

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) {
    final rawJobs = json['jobs'];
    final rawSkills = json['skills'];
    final rawPaths = json['portfolioPaths'];
    final rawCertificates = json['certificatePaths'];
    final price = json['startingPrice'];

    return TechnicianProfile(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? '',
      ownerPhone: json['ownerPhone']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      skills: rawSkills is List
          ? rawSkills.map((item) => item.toString()).toList()
          : const [],
      serviceArea: json['serviceArea']?.toString() ?? '',
      startingPrice: price is num ? price.toDouble() : 0,
      portfolioPaths: rawPaths is List
          ? rawPaths.map((item) => item.toString()).toList()
          : const [],
      certificatePaths: rawCertificates is List
          ? rawCertificates.map((item) => item.toString()).toList()
          : const [],
      jobs: rawJobs is List
          ? rawJobs
              .whereType<Map>()
              .map((item) => TechnicianJob.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      status: json['status'] is int ? json['status'] as int : 0,
      reviewComment: json['reviewComment']?.toString(),
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}
