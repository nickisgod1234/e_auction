import 'package:e_auction/models/coupon_model.dart';
import 'dart:math';

/// Mock Coupon Service - สำหรับทดสอบก่อนเชื่อม API จริง
class CouponService {
  static final CouponService _instance = CouponService._internal();
  factory CouponService() => _instance;
  CouponService._internal();

  // Mock data storage (จะแทนที่ด้วย API call ในอนาคต)
  static List<Coupon> _mockCoupons = [];
  static int _couponCounter = 1;

  /// ตรวจสอบว่าผู้ใช้เคยได้รับคูปองสำหรับสินค้านี้แล้วหรือยัง
  Future<bool> hasCouponForQuotation(String userId, String quotationId) async {
    try {
      await _loadCouponsFromStorage();
      
      // ตรวจสอบว่ามีคูปองสำหรับ quotation_id และ user_id นี้แล้วหรือยัง
      final existingCoupon = _mockCoupons.any((coupon) =>
          coupon.userId == userId &&
          coupon.quotationId == quotationId &&
          coupon.type == 'bid_reward');
      
      return existingCoupon;
    } catch (e) {
      print('❌ COUPON: Error checking existing coupon: $e');
      return false;
    }
  }

  /// สร้างคูปองให้ผู้ใช้เมื่อประมูลสำเร็จ (แสดง dialog แค่ครั้งแรกเท่านั้น)
  Future<Coupon?> createBidRewardCoupon({
    required String userId,
    String? userName,
    String? userPhone,
    required String quotationId,
    String? quotationTitle,
    bool checkExisting = true, // ตรวจสอบว่ามีคูปองอยู่แล้วหรือไม่
  }) async {
    try {
      // ตรวจสอบว่าผู้ใช้เคยได้รับคูปองสำหรับสินค้านี้แล้วหรือยัง
      if (checkExisting) {
        final hasExisting = await hasCouponForQuotation(userId, quotationId);
        if (hasExisting) {
          print('🎫 COUPON: ผู้ใช้เคยได้รับคูปองสำหรับสินค้านี้แล้ว - Quotation: $quotationId');
          return null; // ไม่สร้างคูปองใหม่
        }
      }
      
      // สร้างรหัสคูปองแบบสุ่ม
      final code = _generateCouponCode();
      
      // กำหนดวันหมดอายุ (30 วันจากวันนี้)
      final expiresAt = DateTime.now().add(Duration(days: 30));
      
      // สร้างคูปอง (ส่วนลด 5% สูงสุด 500 บาท)
      final coupon = Coupon(
        id: 'COUPON_${_couponCounter++}',
        code: code,
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        quotationId: quotationId,
        quotationTitle: quotationTitle,
        status: 'active',
        discountPercent: 5.0,
        minPurchaseAmount: 1000.0,
        maxDiscountAmount: 500.0,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        type: 'bid_reward',
        description: 'คูปองส่วนลดจากการประมูลสินค้า',
      );

      // เก็บใน mock data
      _mockCoupons.add(coupon);
      
      // เก็บใน SharedPreferences (สำหรับ mock)
      await _saveCouponsToStorage();
      
      print('🎫 COUPON: สร้างคูปองสำเร็จ - Code: $code, User: $userId, Quotation: $quotationId');
      
      return coupon;
    } catch (e) {
      print('❌ COUPON: Error creating coupon: $e');
      return null;
    }
  }

  /// ดึงคูปองทั้งหมดของผู้ใช้
  Future<List<Coupon>> getUserCoupons(String userId) async {
    try {
      // โหลดจาก storage
      await _loadCouponsFromStorage();
      
      // กรองคูปองของผู้ใช้
      final userCoupons = _mockCoupons
          .where((coupon) => coupon.userId == userId)
          .toList();
      
      // เรียงตามวันที่สร้าง (ใหม่สุดก่อน)
      userCoupons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return userCoupons;
    } catch (e) {
      print('❌ COUPON: Error getting user coupons: $e');
      return [];
    }
  }

  /// ดึงคูปองทั้งหมด (สำหรับ Admin)
  Future<List<Coupon>> getAllCoupons({
    String? status,
    String? userId,
    String? quotationId,
  }) async {
    try {
      await _loadCouponsFromStorage();
      
      var filteredCoupons = _mockCoupons;
      
      if (status != null && status.isNotEmpty) {
        filteredCoupons = filteredCoupons
            .where((coupon) => coupon.status == status)
            .toList();
      }
      
      if (userId != null && userId.isNotEmpty) {
        filteredCoupons = filteredCoupons
            .where((coupon) => coupon.userId == userId)
            .toList();
      }
      
      if (quotationId != null && quotationId.isNotEmpty) {
        filteredCoupons = filteredCoupons
            .where((coupon) => coupon.quotationId == quotationId)
            .toList();
      }
      
      // เรียงตามวันที่สร้าง (ใหม่สุดก่อน)
      filteredCoupons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return filteredCoupons;
    } catch (e) {
      print('❌ COUPON: Error getting all coupons: $e');
      return [];
    }
  }

  /// ใช้คูปอง
  Future<bool> useCoupon(String couponId, String orderId) async {
    try {
      await _loadCouponsFromStorage();
      
      final couponIndex = _mockCoupons.indexWhere((c) => c.id == couponId);
      if (couponIndex == -1) return false;
      
      final coupon = _mockCoupons[couponIndex];
      if (!coupon.canUse) return false;
      
      // อัปเดตสถานะ
      _mockCoupons[couponIndex] = Coupon(
        id: coupon.id,
        code: coupon.code,
        userId: coupon.userId,
        userName: coupon.userName,
        userPhone: coupon.userPhone,
        quotationId: coupon.quotationId,
        quotationTitle: coupon.quotationTitle,
        status: 'used',
        discountAmount: coupon.discountAmount,
        discountPercent: coupon.discountPercent,
        minPurchaseAmount: coupon.minPurchaseAmount,
        maxDiscountAmount: coupon.maxDiscountAmount,
        createdAt: coupon.createdAt,
        usedAt: DateTime.now(),
        expiresAt: coupon.expiresAt,
        usedInOrderId: orderId,
        type: coupon.type,
        description: coupon.description,
      );
      
      await _saveCouponsToStorage();
      return true;
    } catch (e) {
      print('❌ COUPON: Error using coupon: $e');
      return false;
    }
  }

  /// ยกเลิกคูปอง (Admin)
  Future<bool> cancelCoupon(String couponId) async {
    try {
      await _loadCouponsFromStorage();
      
      final couponIndex = _mockCoupons.indexWhere((c) => c.id == couponId);
      if (couponIndex == -1) return false;
      
      final coupon = _mockCoupons[couponIndex];
      
      _mockCoupons[couponIndex] = Coupon(
        id: coupon.id,
        code: coupon.code,
        userId: coupon.userId,
        userName: coupon.userName,
        userPhone: coupon.userPhone,
        quotationId: coupon.quotationId,
        quotationTitle: coupon.quotationTitle,
        status: 'cancelled',
        discountAmount: coupon.discountAmount,
        discountPercent: coupon.discountPercent,
        minPurchaseAmount: coupon.minPurchaseAmount,
        maxDiscountAmount: coupon.maxDiscountAmount,
        createdAt: coupon.createdAt,
        usedAt: coupon.usedAt,
        expiresAt: coupon.expiresAt,
        usedInOrderId: coupon.usedInOrderId,
        type: coupon.type,
        description: coupon.description,
      );
      
      await _saveCouponsToStorage();
      return true;
    } catch (e) {
      print('❌ COUPON: Error cancelling coupon: $e');
      return false;
    }
  }

  /// สร้างรหัสคูปองแบบสุ่ม
  String _generateCouponCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final code = List.generate(8, (index) => chars[random.nextInt(chars.length)]).join('');
    return 'BID$code';
  }

  /// บันทึกคูปองลง SharedPreferences (mock)
  Future<void> _saveCouponsToStorage() async {
    try {
      // ใช้ JSON string (ในอนาคตจะใช้ API แทน)
      // final prefs = await SharedPreferences.getInstance();
      // final couponsJson = _mockCoupons.map((c) => c.toJson()).toList();
      // prefs.setString('mock_coupons', jsonEncode(couponsJson));
    } catch (e) {
      print('❌ COUPON: Error saving coupons: $e');
    }
  }

  /// โหลดคูปองจาก SharedPreferences (mock)
  Future<void> _loadCouponsFromStorage() async {
    try {
      // ในอนาคตจะโหลดจาก API
      // final prefs = await SharedPreferences.getInstance();
      // final couponsJson = prefs.getString('mock_coupons');
      // if (couponsJson != null) {
      //   final List<dynamic> decoded = jsonDecode(couponsJson);
      //   _mockCoupons = decoded.map((json) => Coupon.fromJson(json)).toList();
      // }
    } catch (e) {
      print('❌ COUPON: Error loading coupons: $e');
    }
  }

  /// สถิติคูปอง (สำหรับ Admin)
  Future<Map<String, dynamic>> getCouponStats() async {
    try {
      await _loadCouponsFromStorage();
      
      final total = _mockCoupons.length;
      final active = _mockCoupons.where((c) => c.isActive && !c.isExpired).length;
      final used = _mockCoupons.where((c) => c.isUsed).length;
      final expired = _mockCoupons.where((c) => c.isExpired).length;
      final cancelled = _mockCoupons.where((c) => c.status == 'cancelled').length;
      
      return {
        'total': total,
        'active': active,
        'used': used,
        'expired': expired,
        'cancelled': cancelled,
      };
    } catch (e) {
      print('❌ COUPON: Error getting stats: $e');
      return {
        'total': 0,
        'active': 0,
        'used': 0,
        'expired': 0,
        'cancelled': 0,
      };
    }
  }
}

