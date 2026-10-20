class ServiceJob {
  static const statusOpen = 'open';
  static const statusAwarded = 'awarded';

  final String id;
  final String ownerId;
  final String ownerName;
  final String skill;
  final String title;
  final String detail;
  final String area;
  final double? budget;
  final String status;
  final String? awardedQuoteId;
  final String createdAt;

  const ServiceJob({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.skill,
    required this.title,
    required this.detail,
    required this.area,
    required this.budget,
    required this.status,
    required this.awardedQuoteId,
    required this.createdAt,
  });

  bool get isOpen => status == statusOpen;

  String get statusLabel => isOpen ? 'เปิดรับราคา' : 'เลือกช่างแล้ว';

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'skill': skill,
        'title': title,
        'detail': detail,
        'area': area,
        'budget': budget,
        'status': status,
        'awardedQuoteId': awardedQuoteId,
        'createdAt': createdAt,
      };

  factory ServiceJob.fromJson(Map<String, dynamic> json) {
    final budget = json['budget'];
    return ServiceJob(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? '',
      skill: json['skill']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      budget: budget is num ? budget.toDouble() : null,
      status: json['status']?.toString() ?? statusOpen,
      awardedQuoteId: json['awardedQuoteId']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class ServiceQuote {
  final String id;
  final String jobId;
  final String technicianOwnerId;
  final String technicianName;
  final double price;
  final String note;
  final String createdAt;

  const ServiceQuote({
    required this.id,
    required this.jobId,
    required this.technicianOwnerId,
    required this.technicianName,
    required this.price,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'technicianOwnerId': technicianOwnerId,
        'technicianName': technicianName,
        'price': price,
        'note': note,
        'createdAt': createdAt,
      };

  factory ServiceQuote.fromJson(Map<String, dynamic> json) {
    final price = json['price'];
    return ServiceQuote(
      id: json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      technicianOwnerId: json['technicianOwnerId']?.toString() ?? '',
      technicianName: json['technicianName']?.toString() ?? '',
      price: price is num ? price.toDouble() : 0,
      note: json['note']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
