import 'package:e_auction/views/first_page/auction_page/auction_detail_view_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:e_auction/utils/format.dart';

class AllCurrentAuctionsPage extends StatelessWidget {
  final List<Map<String, dynamic>> currentAuctions;

  const AllCurrentAuctionsPage({super.key, required this.currentAuctions});

  Widget _buildAuctionImage(String? imagePath, {double width = 80, double height = 80}) {
    if (imagePath == null || imagePath.isEmpty) {
      return Image.asset('assets/images/noimage.jpg', width: width, height: height, fit: BoxFit.cover);
    }
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/noimage.jpg', width: width, height: height, fit: BoxFit.cover);
        },
      );
    } else {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/noimage.jpg', width: width, height: height, fit: BoxFit.cover);
        },
      );
    }
  }

  Widget _buildAuctionListItem(
      BuildContext context, Map<String, dynamic> auction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuctionDetailViewPage(auctionData: auction),
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
                      'ราคาปัจจุบัน: ${Format.formatCurrency(auction['currentPrice'])}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${auction['timeRemaining']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
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
        title: const Text('กำลังประมูลทั้งหมด'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: currentAuctions.isEmpty
          ? const Center(
              child: Text(
                'ไม่มีรายการกำลังประมูล',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: currentAuctions.length,
              itemBuilder: (context, index) {
                return _buildAuctionListItem(context, currentAuctions[index]);
              },
            ),
    );
  }
} 