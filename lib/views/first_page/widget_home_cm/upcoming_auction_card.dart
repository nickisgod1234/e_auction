import 'package:flutter/material.dart';
import 'package:e_auction/views/first_page/detail_page/detail_page.dart';
import 'package:intl/intl.dart';

class UpcomingAuctionCard extends StatelessWidget {
  final Map<String, dynamic> auctionData;

  const UpcomingAuctionCard({
    super.key,
    required this.auctionData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(auctionData: auctionData),
          ),
        );
      },
      child: Container(
        width: 280,
        height: 200,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
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
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 280,
                height: 200,
                child: Image.asset(
                  auctionData['image'] ?? 'assets/images/morket_banner.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Time Until Start Badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  auctionData['timeUntilStart'] ?? '2 วัน',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            // Product Details Overlay
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
                  mainAxisSize: MainAxisSize.min,
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
                    Text(
                      'เริ่มต้น ฿${NumberFormat('#,###').format(auctionData['startingPrice'] ?? 0)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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