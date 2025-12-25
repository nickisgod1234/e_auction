class Coupon {
  final String id;
  final String code;
  final String userId;
  final String? userName;
  final String? userPhone;
  final String quotationId;
  final String? quotationTitle;
  final String status; // 'active', 'used', 'expired', 'cancelled'
  final double? discountAmount;
  final double? discountPercent;
  final double? minPurchaseAmount;
  final double? maxDiscountAmount;
  final DateTime createdAt;
  final DateTime? usedAt;
  final DateTime? expiresAt;
  final String? usedInOrderId;
  final String type; // 'bid_reward', 'promotion', 'special'
  final String? description;

  Coupon({
    required this.id,
    required this.code,
    required this.userId,
    this.userName,
    this.userPhone,
    required this.quotationId,
    this.quotationTitle,
    required this.status,
    this.discountAmount,
    this.discountPercent,
    this.minPurchaseAmount,
    this.maxDiscountAmount,
    required this.createdAt,
    this.usedAt,
    this.expiresAt,
    this.usedInOrderId,
    this.type = 'bid_reward',
    this.description,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString(),
      userPhone: json['user_phone']?.toString(),
      quotationId: json['quotation_id']?.toString() ?? '',
      quotationTitle: json['quotation_title']?.toString(),
      status: json['status']?.toString() ?? 'active',
      discountAmount: json['discount_amount'] != null
          ? double.tryParse(json['discount_amount'].toString())
          : null,
      discountPercent: json['discount_percent'] != null
          ? double.tryParse(json['discount_percent'].toString())
          : null,
      minPurchaseAmount: json['min_purchase_amount'] != null
          ? double.tryParse(json['min_purchase_amount'].toString())
          : null,
      maxDiscountAmount: json['max_discount_amount'] != null
          ? double.tryParse(json['max_discount_amount'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'].toString())
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'].toString())
          : null,
      usedInOrderId: json['used_in_order_id']?.toString(),
      type: json['type']?.toString() ?? 'bid_reward',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'user_id': userId,
      'user_name': userName,
      'user_phone': userPhone,
      'quotation_id': quotationId,
      'quotation_title': quotationTitle,
      'status': status,
      'discount_amount': discountAmount,
      'discount_percent': discountPercent,
      'min_purchase_amount': minPurchaseAmount,
      'max_discount_amount': maxDiscountAmount,
      'created_at': createdAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'used_in_order_id': usedInOrderId,
      'type': type,
      'description': description,
    };
  }

  bool get isActive => status == 'active' && !isExpired;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isUsed => status == 'used';
  bool get canUse => isActive && !isExpired && !isUsed;

  String get statusText {
    if (isExpired) return 'หมดอายุ';
    if (isUsed) return 'ใช้แล้ว';
    if (status == 'cancelled') return 'ยกเลิก';
    return 'ใช้งานได้';
  }
}

