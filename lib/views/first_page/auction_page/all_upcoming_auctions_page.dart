import 'package:e_auction/views/first_page/detail_page/detail_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:e_auction/utils/format.dart';

class AllUpcomingAuctionsPage extends StatelessWidget {
  final List<Map<String, dynamic>> upcomingAuctions;

  const AllUpcomingAuctionsPage({super.key, required this.upcomingAuctions});

  // Helper method to get starting price as int
  int _getStartingPriceAsInt(Map<String, dynamic> auction) {
    final startingPriceRaw = auction['startingPrice'];
    if (startingPriceRaw is double) {
      return startingPriceRaw.round();
    } else if (startingPriceRaw is int) {
      return startingPriceRaw;
    }
    return 0; // default value
  }

  Widget _buildAuctionImage(String? imagePath, {double width = 80, double height = 80}) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    
    // ตรวจสอบว่าเป็น URL หรือไม่
    final isUrl = imagePath.startsWith('http://') || imagePath.startsWith('https://');
    
    if (isUrl) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Icon(Icons.image_not_supported, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Icon(Icons.image_not_supported, color: Colors.grey),
          );
        },
      );
    }
  }

  Widget _buildAuctionListItem(
      BuildContext context, Map<String, dynamic> auction) {
    // Debug: ตรวจสอบข้อมูล image
    print('🔍 ALL_UPCOMING: auction[image] = ${auction['image']}');
    print('🔍 ALL_UPCOMING: auction[title] = ${auction['title']}');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(auctionData: auction),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildAuctionImage(auction['image']),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ราคาเริ่มต้น: ${Format.formatCurrency(_getStartingPriceAsInt(auction))}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'จะเริ่มในอีก: ${auction['timeUntilStart'] ?? 'ไม่ระบุ'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประมูลที่จะมาถึงทั้งหมด'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: upcomingAuctions.isEmpty
          ? const Center(
              child: Text(
                'ไม่มีรายการประมูลที่จะมาถึง',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: upcomingAuctions.length,
              itemBuilder: (context, index) {
                return _buildAuctionListItem(context, upcomingAuctions[index]);
              },
            ),
    );
  }
} 