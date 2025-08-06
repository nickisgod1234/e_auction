import 'package:flutter/material.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/views/first_page/widgets/auction_image_widget.dart';
import 'package:e_auction/utils/time_calculator.dart';

class AuctionListItemWidget extends StatelessWidget {
  final Map<String, dynamic> auction;
  final VoidCallback onTap;
  final String? priceLabel;
  final String? timeLabel;
  final Color? timeColor;
  final bool showPrice;
  final bool showTime;

  const AuctionListItemWidget({
    super.key,
    required this.auction,
    required this.onTap,
    this.priceLabel,
    this.timeLabel,
    this.timeColor,
    this.showPrice = true,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              AuctionImageWidget(
                imagePath: auction['image'],
                width: 80,
                height: 80,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction['title'] ?? 'ไม่มีชื่อสินค้า',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showPrice) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getPriceText(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                    if (showTime) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getTimeText(),
                        style: TextStyle(
                          fontSize: 14,
                          color: timeColor ?? Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPriceText() {
    if (priceLabel != null) {
      return priceLabel!;
    }

    // ตรวจสอบประเภทของราคา
    if (auction['currentPrice'] != null) {
      return 'ราคาปัจจุบัน: ${Format.formatCurrency(auction['currentPrice'])}';
    } else if (auction['startingPrice'] != null) {
      return 'ราคาเริ่มต้น: ${Format.formatCurrency(auction['startingPrice'])}';
    } else if (auction['finalPrice'] != null) {
      return 'ราคาสุดท้าย: ${Format.formatCurrency(auction['finalPrice'])}';
    }

    return 'ไม่ระบุราคา';
  }

  String _getTimeText() {
    if (timeLabel != null) {
      return timeLabel!;
    }

    // Debug: ตรวจสอบข้อมูล
    print('DEBUG: AuctionListItemWidget - auction keys: ${auction.keys.toList()}');
    print('DEBUG: AuctionListItemWidget - auction_start_date: ${auction['auction_start_date']}');
    print('DEBUG: AuctionListItemWidget - auction_end_date: ${auction['auction_end_date']}');
    print('DEBUG: AuctionListItemWidget - status: ${auction['status']}');

    // Helper method to parse date time (เหมือนกับใน UpcomingAuctionCard)
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
          print('DEBUG: Error parsing date $dateTimeValue: $e');
          return null;
        }
      }
      
      return null;
    }

    // คำนวณเวลาที่เหลือ
    final startDate = _parseDateTime(auction['auction_start_date']);
    final endDate = _parseDateTime(auction['auction_end_date']);
    
    print('DEBUG: AuctionListItemWidget - parsed startDate: $startDate');
    print('DEBUG: AuctionListItemWidget - parsed endDate: $endDate');
    
    if (startDate != null && endDate != null) {
      // ใช้ TimeCalculator เพื่อตรวจสอบสถานะที่ถูกต้อง
      final status = TimeCalculator.getAuctionStatus(
        startDate: startDate,
        endDate: endDate,
      );
      
      print('DEBUG: AuctionListItemWidget - calculated status: $status');
      
      final timeRemaining = TimeCalculator.calculateTimeRemaining(
        startDate: startDate,
        endDate: endDate,
        status: status,
      );
      
      print('DEBUG: AuctionListItemWidget - timeRemaining: $timeRemaining');
      return timeRemaining;
    }

    // Fallback ถ้าไม่มีวันที่
    if (auction['timeUntilStart'] != null) {
      print('DEBUG: AuctionListItemWidget - using fallback timeUntilStart: ${auction['timeUntilStart']}');
      return 'จะเริ่มในอีก: ${auction['timeUntilStart']}';
    } else if (auction['timeRemaining'] != null) {
      print('DEBUG: AuctionListItemWidget - using fallback timeRemaining: ${auction['timeRemaining']}');
      return auction['timeRemaining'];
    } else if (auction['completedDate'] != null) {
      return auction['completedDate'];
    }

    return 'ไม่ระบุเวลา';
  }
}

// Helper function สำหรับ backward compatibility
Widget buildAuctionListItem(
  BuildContext context,
  Map<String, dynamic> auction, {
  required VoidCallback onTap,
  String? priceLabel,
  String? timeLabel,
  Color? timeColor,
  bool showPrice = true,
  bool showTime = true,
}) {
  return AuctionListItemWidget(
    auction: auction,
    onTap: onTap,
    priceLabel: priceLabel,
    timeLabel: timeLabel,
    timeColor: timeColor,
    showPrice: showPrice,
    showTime: showTime,
  );
} 