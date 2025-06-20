import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AuctionResultPage extends StatelessWidget {
  final Map<String, dynamic> auctionData;

  const AuctionResultPage({super.key, required this.auctionData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ผลการประมูล',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image and basic info
            _buildHeader(context),
            
            // Winner announcement section
            _buildWinnerSection(context),
            
            // Auction statistics
            _buildAuctionStats(context),
            
            // Bidding history
            _buildBiddingHistory(context),
            
            // Auction details
            _buildAuctionDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.customTheme.primaryColor.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                auctionData['image'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 64),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              auctionData['title'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ประมูลเสร็จสิ้น',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Text(
                'ผู้ชนะการประมูล',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.green,
                child: Text(
                  auctionData['winner'].substring(3, 5), // Get first 2 characters
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auctionData['winner'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'ผู้ชนะการประมูล',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ราคาที่ชนะ:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '฿${NumberFormat('#,###').format(auctionData['finalPrice'])}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionStats(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.gavel,
              title: 'จำนวนผู้เสนอราคา',
              value: '${auctionData['bidCount'] ?? 15} คน',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.timer,
              title: 'ระยะเวลาประมูล',
              value: '${auctionData['duration'] ?? '7 วัน'}',
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.visibility,
              title: 'ผู้เข้าชม',
              value: '${auctionData['viewCount'] ?? 1247} คน',
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBiddingHistory(BuildContext context) {
    // Mock bidding history data
    final List<Map<String, dynamic>> biddingHistory = [
      {
        'bidder': auctionData['winner'],
        'amount': auctionData['finalPrice'],
        'time': '2 นาทีที่แล้ว',
        'isWinner': true,
      },
      {
        'bidder': 'คุณ Panuwat S.',
        'amount': auctionData['finalPrice']! - 1000,
        'time': '5 นาทีที่แล้ว',
        'isWinner': false,
      },
      {
        'bidder': 'คุณ Travel P.',
        'amount': auctionData['finalPrice']! - 2000,
        'time': '10 นาทีที่แล้ว',
        'isWinner': false,
      },
      {
        'bidder': 'คุณ Photo M.',
        'amount': auctionData['finalPrice']! - 3000,
        'time': '15 นาทีที่แล้ว',
        'isWinner': false,
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ประวัติการเสนอราคา',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: biddingHistory.length,
              itemBuilder: (context, index) {
                final bid = biddingHistory[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: index < biddingHistory.length - 1
                        ? Border(
                            bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                          )
                        : null,
                    color: bid['isWinner'] ? Colors.green.withOpacity(0.05) : null,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: bid['isWinner'] ? Colors.green : Colors.grey,
                        child: Text(
                          bid['bidder'].substring(3, 5),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  bid['bidder'],
                                  style: TextStyle(
                                    fontWeight: bid['isWinner'] ? FontWeight.bold : FontWeight.normal,
                                    color: bid['isWinner'] ? Colors.green : Colors.black,
                                  ),
                                ),
                                if (bid['isWinner']) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'ผู้ชนะ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              bid['time'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '฿${NumberFormat('#,###').format(bid['amount'])}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: bid['isWinner'] ? Colors.green : Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionDetails(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายละเอียดการประมูล',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _buildDetailRow('วันที่เริ่มประมูล', '${auctionData['startDate'] ?? '15 มกราคม 2024'}'),
                _buildDetailRow('วันที่สิ้นสุดประมูล', '${auctionData['endDate'] ?? '22 มกราคม 2024'}'),
                _buildDetailRow('ราคาเริ่มต้น', '฿${NumberFormat('#,###').format(auctionData['startingPrice'] ?? auctionData['finalPrice']! - 50000)}'),
                _buildDetailRow('ราคาปิดประมูล', '฿${NumberFormat('#,###').format(auctionData['finalPrice'])}'),
                _buildDetailRow('ผู้ขาย', '${auctionData['sellerName'] ?? 'ผู้ขายมืออาชีพ'}'),
                _buildDetailRow('หมวดหมู่', '${_getCategoryName(auctionData['category'])}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String? category) {
    switch (category) {
      case 'watches':
        return 'นาฬิกา';
      case 'phones':
        return 'มือถือ';
      case 'computers':
        return 'คอมพิวเตอร์';
      case 'cameras':
        return 'กล้อง';
      case 'bags':
        return 'กระเป๋า';
      case 'cars':
        return 'รถยนต์';
      case 'jewelry':
        return 'เครื่องประดับ';
      case 'games':
        return 'เกมส์';
      default:
        return 'อื่นๆ';
    }
  }
} 