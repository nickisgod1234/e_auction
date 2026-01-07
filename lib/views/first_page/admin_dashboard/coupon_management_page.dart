// import 'package:flutter/material.dart';
// import 'package:e_auction/models/coupon_model.dart';
// import 'package:e_auction/services/coupon_service.dart';
// import 'package:e_auction/utils/format.dart';
// import 'package:intl/intl.dart';

// class CouponManagementPage extends StatefulWidget {
//   const CouponManagementPage({super.key});

//   @override
//   State<CouponManagementPage> createState() => _CouponManagementPageState();
// }

// class _CouponManagementPageState extends State<CouponManagementPage> {
//   final CouponService _couponService = CouponService();
//   List<Coupon> _coupons = [];
//   List<Coupon> _filteredCoupons = [];
//   bool _isLoading = true;
//   Map<String, dynamic> _stats = {};
  
//   String _selectedStatus = 'all';
//   String _searchQuery = '';

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);
    
//     try {
//       _coupons = await _couponService.getAllCoupons();
//       _stats = await _couponService.getCouponStats();
//       _applyFilters();
//     } catch (e) {
//       print('❌ Error loading coupons: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _applyFilters() {
//     setState(() {
//       _filteredCoupons = _coupons.where((coupon) {
//         // Filter by status
//         if (_selectedStatus != 'all') {
//           if (_selectedStatus == 'active' && !coupon.canUse) return false;
//           if (_selectedStatus == 'used' && !coupon.isUsed) return false;
//           if (_selectedStatus == 'expired' && !coupon.isExpired && coupon.status != 'cancelled') return false;
//         }
        
//         // Filter by search query
//         if (_searchQuery.isNotEmpty) {
//           final query = _searchQuery.toLowerCase();
//           final matchesCode = coupon.code.toLowerCase().contains(query);
//           final matchesUser = (coupon.userName ?? '').toLowerCase().contains(query) ||
//                             (coupon.userPhone ?? '').contains(query);
//           final matchesProduct = (coupon.quotationTitle ?? '').toLowerCase().contains(query);
          
//           if (!matchesCode && !matchesUser && !matchesProduct) return false;
//         }
        
//         return true;
//       }).toList();
      
//       // Sort by created date (newest first)
//       _filteredCoupons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('จัดการคูปอง'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadData,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 // Statistics Cards
//                 _buildStatsSection(),
                
//                 // Filters
//                 _buildFiltersSection(),
                
//                 // Coupon List
//                 Expanded(
//                   child: _filteredCoupons.isEmpty
//                       ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.local_offer_outlined,
//                                 size: 64,
//                                 color: Colors.grey[400],
//                               ),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'ไม่พบคูปอง',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : RefreshIndicator(
//                           onRefresh: _loadData,
//                           child: ListView.builder(
//                             padding: const EdgeInsets.all(16),
//                             itemCount: _filteredCoupons.length,
//                             itemBuilder: (context, index) {
//                               return _buildCouponCard(_filteredCoupons[index]);
//                             },
//                           ),
//                         ),
//                 ),
//               ],
//             ),
//     );
//   }

//   Widget _buildStatsSection() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       color: Colors.grey[50],
//       child: Row(
//         children: [
//           Expanded(
//             child: _buildStatCard(
//               'ทั้งหมด',
//               '${_stats['total'] ?? 0}',
//               Colors.blue,
//               Icons.local_offer,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: _buildStatCard(
//               'ใช้งานได้',
//               '${_stats['active'] ?? 0}',
//               Colors.green,
//               Icons.check_circle,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: _buildStatCard(
//               'ใช้แล้ว',
//               '${_stats['used'] ?? 0}',
//               Colors.orange,
//               Icons.done_all,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: _buildStatCard(
//               'หมดอายุ',
//               '${_stats['expired'] ?? 0}',
//               Colors.red,
//               Icons.cancel,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(String label, String value, Color color, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 24),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFiltersSection() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       color: Colors.white,
//       child: Column(
//         children: [
//           // Search Bar
//           TextField(
//             decoration: InputDecoration(
//               hintText: 'ค้นหาด้วยรหัสคูปอง, ชื่อผู้ใช้, หรือชื่อสินค้า',
//               prefixIcon: const Icon(Icons.search),
//               suffixIcon: _searchQuery.isNotEmpty
//                   ? IconButton(
//                       icon: const Icon(Icons.clear),
//                       onPressed: () {
//                         setState(() {
//                           _searchQuery = '';
//                           _applyFilters();
//                         });
//                       },
//                     )
//                   : null,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             onChanged: (value) {
//               setState(() {
//                 _searchQuery = value;
//                 _applyFilters();
//               });
//             },
//           ),
//           const SizedBox(height: 12),
//           // Status Filter
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 _buildFilterChip('all', 'ทั้งหมด'),
//                 const SizedBox(width: 8),
//                 _buildFilterChip('active', 'ใช้งานได้'),
//                 const SizedBox(width: 8),
//                 _buildFilterChip('used', 'ใช้แล้ว'),
//                 const SizedBox(width: 8),
//                 _buildFilterChip('expired', 'หมดอายุ'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterChip(String status, String label) {
//     final isSelected = _selectedStatus == status;
//     return FilterChip(
//       label: Text(label),
//       selected: isSelected,
//       onSelected: (selected) {
//         setState(() {
//           _selectedStatus = status;
//           _applyFilters();
//         });
//       },
//       selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
//       checkmarkColor: Theme.of(context).primaryColor,
//       labelStyle: TextStyle(
//         color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
//         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//       ),
//     );
//   }

//   Widget _buildCouponCard(Coupon coupon) {
//     final isActive = coupon.canUse;
//     final isUsed = coupon.isUsed;

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ExpansionTile(
//         leading: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: isActive
//                 ? Colors.green.withOpacity(0.1)
//                 : isUsed
//                     ? Colors.orange.withOpacity(0.1)
//                     : Colors.red.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(
//             isActive
//                 ? Icons.check_circle
//                 : isUsed
//                     ? Icons.done_all
//                     : Icons.cancel,
//             color: isActive
//                 ? Colors.green
//                 : isUsed
//                     ? Colors.orange
//                     : Colors.red,
//           ),
//         ),
//         title: Text(
//           coupon.code,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 4),
//             Text(
//               'ผู้ใช้: ${coupon.userName ?? coupon.userPhone ?? 'ไม่ระบุ'}',
//               style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//             ),
//             Text(
//               'สถานะ: ${coupon.statusText}',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: isActive
//                     ? Colors.green
//                     : isUsed
//                         ? Colors.orange
//                         : Colors.red,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//         trailing: Icon(
//           Icons.expand_more,
//           color: Colors.grey[400],
//         ),
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildDetailRow('รหัสคูปอง', coupon.code),
//                 _buildDetailRow('ผู้ใช้', coupon.userName ?? coupon.userPhone ?? 'ไม่ระบุ'),
//                 _buildDetailRow('เบอร์โทร', coupon.userPhone ?? 'ไม่ระบุ'),
//                 if (coupon.quotationTitle != null)
//                   _buildDetailRow('สินค้า', coupon.quotationTitle!),
//                 _buildDetailRow(
//                   'ส่วนลด',
//                   coupon.discountPercent != null
//                       ? '${coupon.discountPercent}%'
//                       : coupon.discountAmount != null
//                           ? Format.formatCurrency(coupon.discountAmount!.toInt())
//                           : '-',
//                 ),
//                 if (coupon.maxDiscountAmount != null)
//                   _buildDetailRow(
//                     'ส่วนลดสูงสุด',
//                     Format.formatCurrency(coupon.maxDiscountAmount!.toInt()),
//                   ),
//                 if (coupon.minPurchaseAmount != null)
//                   _buildDetailRow(
//                     'ขั้นต่ำ',
//                     Format.formatCurrency(coupon.minPurchaseAmount!.toInt()),
//                   ),
//                 _buildDetailRow(
//                   'สร้างเมื่อ',
//                   DateFormat('dd/MM/yyyy HH:mm').format(coupon.createdAt),
//                 ),
//                 if (coupon.expiresAt != null)
//                   _buildDetailRow(
//                     'หมดอายุ',
//                     DateFormat('dd/MM/yyyy HH:mm').format(coupon.expiresAt!),
//                   ),
//                 if (coupon.usedAt != null)
//                   _buildDetailRow(
//                     'ใช้เมื่อ',
//                     DateFormat('dd/MM/yyyy HH:mm').format(coupon.usedAt!),
//                   ),
//                 if (coupon.usedInOrderId != null)
//                   _buildDetailRow('Order ID', coupon.usedInOrderId!),
//                 const SizedBox(height: 12),
//                 if (isActive)
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: () => _showCancelDialog(coupon),
//                           icon: const Icon(Icons.cancel),
//                           label: const Text('ยกเลิกคูปอง'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.red,
//                             foregroundColor: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               '$label:',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _showCancelDialog(Coupon coupon) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('ยกเลิกคูปอง'),
//         content: Text('คุณต้องการยกเลิกคูปอง ${coupon.code} ใช่หรือไม่?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('ยกเลิก'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('ยืนยัน'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       final success = await _couponService.cancelCoupon(coupon.id);
//       if (success) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('ยกเลิกคูปองสำเร็จ')),
//           );
//           _loadData();
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('ไม่สามารถยกเลิกคูปองได้')),
//           );
//         }
//       }
//     }
//   }
// }

