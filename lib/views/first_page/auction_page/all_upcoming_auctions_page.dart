import 'package:e_auction/views/first_page/detail_page/detail_page.dart';
import 'package:flutter/material.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/views/first_page/widgets/auction_list_item_widget.dart';

class AllUpcomingAuctionsPage extends StatelessWidget {
  final List<Map<String, dynamic>> upcomingAuctions;

  const AllUpcomingAuctionsPage({super.key, required this.upcomingAuctions});



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
                return AuctionListItemWidget(
                  auction: upcomingAuctions[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPage(auctionData: upcomingAuctions[index]),
                      ),
                    );
                  },
                  priceLabel: 'ราคาเริ่มต้น: ${Format.formatCurrency(upcomingAuctions[index]['startingPrice'])}',
                  timeLabel: 'จะเริ่มในอีก: ${upcomingAuctions[index]['timeUntilStart'] ?? 'ไม่ระบุ'}',
                  timeColor: Colors.blue,
                );
              },
            ),
    );
  }
} 
