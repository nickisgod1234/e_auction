import 'package:e_auction/views/first_page/auction_page/auction_detail_view_page.dart';
import 'package:e_auction/views/first_page/auction_page/quantity_reduction_auction_detail_page.dart';
import 'package:e_auction/views/first_page/auction_page/quantity_reduction_auctions_page.dart';
import 'package:e_auction/views/first_page/detail_page/detail_page.dart';
import 'package:flutter/material.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/views/first_page/widgets/auction_list_item_widget.dart';

class AllAuctionsPage extends StatelessWidget {
  final List<Map<String, dynamic>> currentAuctions;
  final List<Map<String, dynamic>> upcomingAuctions;

  const AllAuctionsPage({
    super.key,
    required this.currentAuctions,
    required this.upcomingAuctions,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ดูทั้งหมด'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'กำลังประมูล'),
              Tab(text: 'กำลังจะมาถึง'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AuctionList(
              auctions: currentAuctions,
              emptyText: 'ไม่มีรายการกำลังประมูล',
              timeColor: Colors.red,
              onTap: (context, auction) {
                final typeCode = auction['quotation_type_code']?.toString() ?? '';
                final typeCode2 = auction['type_code']?.toString() ?? '';
                final isAS03 = typeCode == 'AS03' || typeCode2 == 'AS03';
                if (isAS03) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuantityReductionAuctionsPage(),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AuctionDetailViewPage(auctionData: auction),
                  ),
                );
              },
            ),
            _AuctionList(
              auctions: upcomingAuctions,
              emptyText: 'ไม่มีรายการประมูลที่จะมาถึง',
              timeColor: Colors.blue,
              priceLabelFor: (auction) =>
                  'ราคาเริ่มต้น: ${Format.formatCurrency(auction['startingPrice'])}',
              onTap: (context, auction) {
                final quotationTypeCode =
                    auction['quotation_type_code']?.toString() ?? '';
                if (quotationTypeCode == 'AS03') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuantityReductionAuctionDetailPage(
                        auctionData: auction,
                      ),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(auctionData: auction),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AuctionList extends StatelessWidget {
  final List<Map<String, dynamic>> auctions;
  final String emptyText;
  final Color timeColor;
  final void Function(BuildContext context, Map<String, dynamic> auction) onTap;
  final String Function(Map<String, dynamic> auction)? priceLabelFor;

  const _AuctionList({
    required this.auctions,
    required this.emptyText,
    required this.timeColor,
    required this.onTap,
    this.priceLabelFor,
  });

  @override
  Widget build(BuildContext context) {
    if (auctions.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: auctions.length,
      itemBuilder: (context, index) {
        final auction = auctions[index];
        return AuctionListItemWidget(
          auction: auction,
          onTap: () => onTap(context, auction),
          timeColor: timeColor,
          priceLabel: priceLabelFor?.call(auction),
        );
      },
    );
  }
}
