import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailCompleted extends StatelessWidget {
  final Map<String, dynamic> auctionData;

  const DetailCompleted({
    super.key,
    required this.auctionData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดการประมูล'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            SizedBox(
              width: double.infinity,
              height: 250,
              child: Image.asset(
                auctionData['image'] ?? 'assets/images/morket_banner.png',
                fit: BoxFit.cover,
              ),
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
                        _buildDetailRow('ราคาสุดท้าย', '฿${NumberFormat('#,###').format(auctionData['finalPrice'] ?? 0)}'),
                        _buildDetailRow('ราคาเริ่มต้น', '฿${NumberFormat('#,###').format(auctionData['startingPrice'] ?? 0)}'),
                        _buildDetailRow('จำนวนการประมูล', '${auctionData['bidCount'] ?? 0} รายการ'),
                        _buildDetailRow('ผู้ชนะการประมูล', auctionData['winner'] ?? 'ไม่ระบุ'),
                        _buildDetailRow('วันที่เสร็จสิ้น', auctionData['completedDate'] ?? 'ไม่ระบุ'),
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