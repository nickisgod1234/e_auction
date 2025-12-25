import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/models/coupon_model.dart';
import 'package:e_auction/services/coupon_service.dart';
import 'package:e_auction/utils/format.dart';
import 'package:intl/intl.dart';

class MyCouponsPage extends StatefulWidget {
  const MyCouponsPage({super.key});

  @override
  State<MyCouponsPage> createState() => _MyCouponsPageState();
}

class _MyCouponsPageState extends State<MyCouponsPage> with SingleTickerProviderStateMixin {
  final CouponService _couponService = CouponService();
  List<Coupon> _coupons = [];
  bool _isLoading = true;
  String? _userId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCoupons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('id') ?? '';
      
      if (_userId != null && _userId!.isNotEmpty) {
        _coupons = await _couponService.getUserCoupons(_userId!);
      }
    } catch (e) {
      print('❌ Error loading coupons: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Coupon> get _activeCoupons => _coupons.where((c) => c.canUse).toList();
  List<Coupon> get _usedCoupons => _coupons.where((c) => c.isUsed).toList();
  List<Coupon> get _expiredCoupons => _coupons.where((c) => c.isExpired || c.status == 'cancelled').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('คูปองของฉัน'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(text: 'ใช้งานได้ (${_activeCoupons.length})'),
            Tab(text: 'ใช้แล้ว (${_usedCoupons.length})'),
            Tab(text: 'หมดอายุ (${_expiredCoupons.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCoupons,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCouponList(_activeCoupons, 'active'),
                  _buildCouponList(_usedCoupons, 'used'),
                  _buildCouponList(_expiredCoupons, 'expired'),
                ],
              ),
            ),
    );
  }

  Widget _buildCouponList(List<Coupon> coupons, String type) {
    if (coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'active'
                  ? 'ไม่มีคูปองที่ใช้งานได้'
                  : type == 'used'
                      ? 'ยังไม่มีการใช้คูปอง'
                      : 'ไม่มีคูปองที่หมดอายุ',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        return _buildCouponCard(coupons[index], type);
      },
    );
  }

  Widget _buildCouponCard(Coupon coupon, String type) {
    final isActive = type == 'active';
    final isUsed = type == 'used';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isActive
            ? LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Colors.grey[300],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.transparent : Colors.white,
          ),
          child: Stack(
            children: [
              // Background pattern
              if (isActive)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/noimage.jpg'),
                          repeat: ImageRepeat.repeat,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coupon.code,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.white : Colors.black87,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (coupon.quotationTitle != null)
                                Text(
                                  coupon.quotationTitle!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isActive ? Colors.white70 : Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white.withOpacity(0.3)
                                : Colors.grey[400],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            coupon.statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ส่วนลด',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isActive ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                coupon.discountPercent != null
                                    ? '${coupon.discountPercent}%'
                                    : coupon.discountAmount != null
                                        ? Format.formatCurrency(coupon.discountAmount!.toInt())
                                        : '-',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          if (coupon.maxDiscountAmount != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'สูงสุด',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isActive ? Colors.white70 : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Format.formatCurrency(coupon.maxDiscountAmount!.toInt()),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (coupon.minPurchaseAmount != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'ขั้นต่ำ ${Format.formatCurrency(coupon.minPurchaseAmount!.toInt())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: isActive ? Colors.white70 : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              coupon.expiresAt != null
                                  ? 'หมดอายุ: ${DateFormat('dd/MM/yyyy').format(coupon.expiresAt!)}'
                                  : 'ไม่มีวันหมดอายุ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isActive ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (isUsed && coupon.usedAt != null)
                          Text(
                            'ใช้เมื่อ: ${DateFormat('dd/MM/yyyy').format(coupon.usedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Used overlay
              if (isUsed)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

