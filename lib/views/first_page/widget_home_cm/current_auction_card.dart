import 'package:flutter/material.dart';
import 'package:e_auction/views/first_page/auction_page/auction_detail_view_page.dart';
import 'package:e_auction/views/first_page/auction_page/quantity_reduction_auction_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/utils/time_calculator.dart';
import 'dart:async';

class CurrentAuctionCard extends StatefulWidget {
  final Map<String, dynamic> auctionData;

  const CurrentAuctionCard({
    super.key,
    required this.auctionData,
  });

  @override
  State<CurrentAuctionCard> createState() => _CurrentAuctionCardState();
}

class _CurrentAuctionCardState extends State<CurrentAuctionCard> {
  Timer? _timer;
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final startDate = _parseDateTime(widget.auctionData['auction_start_date']);
    final endDate = _parseDateTime(widget.auctionData['auction_end_date']);
    final status = widget.auctionData['status'] ?? 'unknown';
    
    final timeRemaining = TimeCalculator.calculateTimeRemaining(
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
    
    if (mounted) {
      setState(() {
        _timeRemaining = timeRemaining;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'current':
        return Colors.green;
      case 'upcoming':
        return Colors.orange;
      case 'completed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'current':
        return 'กำลังประมูล';
      case 'upcoming':
        return 'ยังไม่เริ่ม';
      case 'completed':
        return 'สิ้นสุดแล้ว';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  // Helper method to get current price as int
  int _getCurrentPriceAsInt() {
    final currentPriceRaw = widget.auctionData['currentPrice'];
    if (currentPriceRaw is double) {
      return currentPriceRaw.round();
    } else if (currentPriceRaw is int) {
      return currentPriceRaw;
    }
    return 850000; // default value
  }

  // Helper method to check if this is AS03 type
  bool _isAS03Type() {
    final typeCode = widget.auctionData['quotation_type_code']?.toString() ?? '';
    final typeCode2 = widget.auctionData['type_code']?.toString() ?? '';
    return typeCode == 'AS03' || typeCode2 == 'AS03';
  }

  // Helper method to parse date time
  DateTime? _parseDateTime(dynamic dateTimeValue) {

    
    if (dateTimeValue == null) {

      return null;
    }
    
    if (dateTimeValue is DateTime) {

      return dateTimeValue;
    } else if (dateTimeValue is String) {
      try {
        final parsed = DateTime.parse(dateTimeValue);

        return parsed;
      } catch (e) {

        return null;
      }
    }
    

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.auctionData['status'] ?? 'unknown';
    

    
    // ใช้ _timeRemaining ที่อัปเดตจาก Timer
    final timeRemaining = _timeRemaining.isNotEmpty ? _timeRemaining : 'กำลังโหลด...';
    

    
    return GestureDetector(
      onTap: () {
        try {
          print('DEBUG: CurrentAuctionCard - Tapped on auction: ${widget.auctionData['title']}');
          print('DEBUG: CurrentAuctionCard - Type code: ${widget.auctionData['quotation_type_code']}');
          
          if (widget.auctionData['quotation_type_code'] == 'AS03') {
            print('DEBUG: CurrentAuctionCard - Navigating to QuantityReductionAuctionDetailPage');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuantityReductionAuctionDetailPage(auctionData: widget.auctionData),
              ),
            );
          } else {
            print('DEBUG: CurrentAuctionCard - Navigating to AuctionDetailViewPage');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AuctionDetailViewPage(auctionData: widget.auctionData),
              ),
            );
          }
        } catch (e) {
          print('DEBUG: CurrentAuctionCard - Navigation error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาดในการเปิดหน้า: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        width: 300,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 300,
                height: 200,
                child: _buildAuctionImage(widget.auctionData['image']),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ป้ายสถานะ
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _getStatusText(status),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  // ป้ายประเภทสินค้า
                  if (widget.auctionData['quotation_type_description'] != null &&
                      widget.auctionData['quotation_type_description'].toString().isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            widget.auctionData['quotation_type_description'].toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // ป้ายเพิ่มเติมสำหรับ AS03 (ประมูลแบบลดตามจำนวน)
                  // if (widget.auctionData['quotation_type_code'] == 'AS03')
                  //   Container(
                  //     margin: EdgeInsets.only(top: 4),
                  //     padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  //     decoration: BoxDecoration(
                  //       color: Colors.orange.withOpacity(0.8),
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //     child: Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         Icon(
                  //           Icons.trending_down,
                  //           color: Colors.white,
                  //           size: 14,
                  //         ),
                  //         SizedBox(width: 4),
                  //         Text(
                  //           'ลดตามจำนวน: ${widget.auctionData['quantity'] ?? 0} ชิ้น',
                  //           style: TextStyle(
                  //             color: Colors.white,
                  //             fontWeight: FontWeight.w600,
                  //             fontSize: 11,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      timeRemaining,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.auctionData['title'] ?? 'Rolex Submariner',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isAS03Type() ? 'ราคาต่อชิ้น: ${Format.formatCurrency(_getCurrentPriceAsInt())}' : 'ราคา: ${Format.formatCurrency(_getCurrentPriceAsInt())}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.auctionData['bidCount'] ?? 12} รายการ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// เพิ่มฟังก์ชัน helper สำหรับแสดงรูป
Widget _buildAuctionImage(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) {
    return Image.asset('assets/images/noimage.jpg', fit: BoxFit.cover);
  }
  
  // Check if the image path is a network URL
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset('assets/images/noimage.jpg', fit: BoxFit.cover);
      },
    );
  } else {
    // Treat as local asset
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset('assets/images/noimage.jpg', fit: BoxFit.cover);
      },
    );
  }
} 