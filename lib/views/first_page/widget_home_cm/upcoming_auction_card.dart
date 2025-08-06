import 'package:flutter/material.dart';
import 'package:e_auction/views/first_page/detail_page/detail_page.dart';
import 'package:e_auction/views/first_page/auction_page/quantity_reduction_auction_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/utils/time_calculator.dart';

class UpcomingAuctionCard extends StatelessWidget {
  final Map<String, dynamic> auctionData;

  const UpcomingAuctionCard({
    super.key,
    required this.auctionData,
  });

  // Helper method to get starting price as int
  int _getStartingPriceAsInt() {
    final startingPriceRaw = auctionData['startingPrice'];
    if (startingPriceRaw is double) {
      return startingPriceRaw.round();
    } else if (startingPriceRaw is int) {
      return startingPriceRaw;
    }
    return 0; // default value
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

  @override
  Widget build(BuildContext context) {
    // คำนวณเวลาที่เหลือ
    final startDate = _parseDateTime(auctionData['auction_start_date']);
    final endDate = _parseDateTime(auctionData['auction_end_date']);
    
    // ใช้ TimeCalculator เพื่อตรวจสอบสถานะที่ถูกต้อง
    final status = startDate != null && endDate != null 
        ? TimeCalculator.getAuctionStatus(startDate: startDate, endDate: endDate)
        : (auctionData['status'] ?? 'unknown');
    
    final timeRemaining = TimeCalculator.calculateTimeRemaining(
      startDate: startDate,
      endDate: endDate,
      status: status,
    );

  

    return GestureDetector(
      onTap: () {
        // ตรวจสอบประเภทการประมูล
        final quotationTypeCode = auctionData['quotation_type_code']?.toString() ?? '';
        
        // ถ้าเป็น AS03 ให้ไปหน้า Quantity Reduction Auction Detail
        if (quotationTypeCode == 'AS03') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuantityReductionAuctionDetailPage(auctionData: auctionData),
            ),
          );
        } else {
          // ประเภทอื่นๆ ไปหน้า Detail ปกติ
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(auctionData: auctionData),
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
                child: _buildAuctionImage(auctionData['image']),
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
                          Icons.schedule_outlined,
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
                  // ป้ายประเภทสินค้า (ไม่แสดงสำหรับ AS03)
                  if (auctionData['quotation_type_description'] != null &&
                      auctionData['quotation_type_description']
                          .toString()
                          .isNotEmpty &&
                      auctionData['quotation_type_code'] != 'AS03')
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            auctionData['quotation_type_description']
                                .toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // ป้ายพิเศษสำหรับ AS03 (ประมูลลดตามจำนวน)
                  if (auctionData['quotation_type_code'] == 'AS03')
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_down,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'ลดตามจำนวน: ${auctionData['quantity'] ?? 0} ชิ้น',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      auctionData['title'] ?? 'สินค้า',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    // แสดงจำนวนสินค้าสำหรับ AS03
                    if (auctionData['quotation_type_code'] == 'AS03')
                      Container(
                        margin: EdgeInsets.only(bottom: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2,
                              color: Colors.purple[300],
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'จำนวน: ${auctionData['quantity'] ?? 0} รายการ',
                              style: TextStyle(
                                color: Colors.purple[300],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (auctionData['quotation_type_code'] == 'AS03')
                      SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'เริ่มต้น: ${Format.formatCurrency(_getStartingPriceAsInt())}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'รอเริ่ม',
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

  // Helper method to build auction image
  Widget _buildAuctionImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Image.asset('assets/images/noimage.jpg', fit: BoxFit.cover);
    }

    // ตรวจสอบว่าเป็น URL หรือไม่
    final isUrl =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isUrl) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/noimage.jpg', fit: BoxFit.cover);
        },
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/noimage.jpg', fit: BoxFit.cover);
        },
      );
    }
  }
}
