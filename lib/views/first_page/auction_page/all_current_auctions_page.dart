import 'package:e_auction/views/first_page/auction_page/auction_detail_view_page.dart';
import 'package:flutter/material.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/views/first_page/widgets/auction_list_item_widget.dart';

class AllCurrentAuctionsPage extends StatelessWidget {
  final List<Map<String, dynamic>> currentAuctions;

  const AllCurrentAuctionsPage({super.key, required this.currentAuctions});



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
                return AuctionListItemWidget(
                  auction: currentAuctions[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuctionDetailViewPage(auctionData: currentAuctions[index]),
                      ),
                    );
                  },
                  timeColor: Colors.red,
                );
              },
            ),
    );
  }
}
