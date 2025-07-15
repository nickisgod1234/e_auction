import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:e_auction/utils/format.dart';

class DetailCompleted extends StatelessWidget {
  final Map<String, dynamic> auctionData;

  const DetailCompleted({
    super.key,
    required this.auctionData,
  });

  // Helper method to get final price as int
  int _getFinalPriceAsInt() {
    final finalPriceRaw = auctionData['finalPrice'];
    if (finalPriceRaw is double) {
      return finalPriceRaw.round();
    } else if (finalPriceRaw is int) {
      return finalPriceRaw;
    }
    return 0; // default value
  }

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

  // Helper method to build auction image (URL or asset)
  Widget _buildAuctionImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Image.asset('assets/images/morket_banner.png', fit: BoxFit.cover);
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/images/morket_banner.png', fit: BoxFit.cover),
      );
    }
    return Image.asset(imagePath, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    print('auctionData: $auctionData'); // เพิ่มบรรทัดนี้
    // Fallback helpers
    String getFinalPrice() {
      final price = auctionData['currentPrice'] ?? auctionData['finalPrice'] ?? auctionData['final_price'] ?? auctionData['winnerPrice'] ?? auctionData['winner_price'] ?? auctionData['price'] ?? null;
      if (price != null) {
        return Format.formatCurrency(price);
      }
      return '-';
    }
   String getWinnerName() {
      if (auctionData['winner'] != null && auctionData['winner'].toString().isNotEmpty) {
        return auctionData['winner'];
      }
      if (auctionData['winnerName'] != null && auctionData['winnerName'].toString().isNotEmpty) {
        return auctionData['winnerName'];
      }
      if (auctionData['winner_name'] != null && auctionData['winner_name'].toString().isNotEmpty) {
        return auctionData['winner_name'];
      }
      if (auctionData['winner_firstname'] != null && auctionData['winner_lastname'] != null) {
        final first = auctionData['winner_firstname'].toString();
        final last = auctionData['winner_lastname'].toString();
        if (first.isNotEmpty || last.isNotEmpty) {
          return (first + ' ' + last).trim();
        }
      }
      return '-';
    }
    
    String getWinnerPhone() {
      final phone = auctionData['winner_phone'] ?? auctionData['winnerPhone'] ?? auctionData['phone'] ?? null;
      if (phone != null && phone.toString().isNotEmpty) {
        final phoneStr = phone.toString();
        if (phoneStr.length >= 4) {
          // ซ่อน 4 ตัวสุดท้ายเป็น xxxx
          final visiblePart = phoneStr.substring(0, phoneStr.length - 4);
          return '$visiblePart xxxx';
        }
        return phoneStr;
      }
      return '-';
    }
    String getCompletedDate() {
      return auctionData['auction_end_date'] ?? auctionData['completedDate'] ?? auctionData['completed_date'] ?? auctionData['endDate'] ?? auctionData['end_date'] ?? '-';
    }

        return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('รายละเอียดการประมูล'),
          foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            SizedBox(
              width: double.infinity,
              height: 250,
              child: _buildAuctionImage(auctionData['image']),
            ),

            // Product Details
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    auctionData['title'] ?? 'สินค้า',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Auction Result Card
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ผลการประมูล',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildDetailRow('ราคาสุดท้าย', getFinalPrice()),
                        _buildDetailRow('ราคาเริ่มต้น',
                            '${Format.formatCurrency(_getStartingPriceAsInt())}'),
                        _buildDetailRow('จำนวนการประมูล',
                            '${auctionData['bidCount'] ?? 0} รายการ'),
                        _buildDetailRow('ผู้ชนะการประมูล', getWinnerName()),
                        _buildDetailRow('เบอร์โทรศัพท์', getWinnerPhone()),
                        _buildDetailRow('วันที่เสร็จสิ้น', getCompletedDate()),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Product Description
                  Text(
                    'รายละเอียดสินค้า',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    auctionData['description'] ?? 'ไม่มีรายละเอียดสินค้า',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
