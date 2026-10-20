import 'package:flutter/material.dart';
import 'package:e_auction/views/first_page/auction_page/auction_detail_view_page.dart';
import 'package:e_auction/views/first_page/auction_page/quantity_reduction_auction_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    // ถ้าเป็นการประมูลแบบลดตามจำนวน (AS03) ใช้สีม่วง
    if (_isAS03Type()) {
      return Colors.green;
    }
    
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

  int _readPrice(dynamic raw) {
    if (raw is double) return raw.round();
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  int _displayPrice() {
    final status = widget.auctionData['status'] ?? '';
    if (status == 'upcoming') {
      return _readPrice(widget.auctionData['startingPrice']);
    }
    final current = _readPrice(widget.auctionData['currentPrice']);
    if (current > 0) return current;
    return _readPrice(widget.auctionData['startingPrice']);
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
    final timeRemaining = _timeRemaining.isNotEmpty ? _timeRemaining : 'กำลังโหลด...';
    final priceLabel = status == 'upcoming' ? 'ราคาเริ่มต้น' : 'ราคาปัจจุบัน';
    

    
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildAuctionImage(widget.auctionData['image']),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Text(
                      timeRemaining,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.auctionData['title']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$priceLabel ${Format.formatCurrency(_displayPrice())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEE4D2D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.auctionData['bidCount'] ?? 0} รายการเสนอราคา',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// เพิ่มฟังก์ชัน helper สำหรับแสดงรูป (ใช้ cache เพื่อโหลดเร็ว)
Widget _buildAuctionImage(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) {
    return _imagePlaceholder();
  }
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return CachedNetworkImage(
      imageUrl: imagePath,
      fit: BoxFit.cover,
      placeholder: (context, url) => _imagePlaceholder(),
      errorWidget: (context, url, error) => _imagePlaceholder(),
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }
  return Image.asset(
    imagePath,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
  );
}

Widget _imagePlaceholder() {
  return Container(
    color: Colors.grey[200],
    child: Center(
      child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 32),
    ),
  );
} 