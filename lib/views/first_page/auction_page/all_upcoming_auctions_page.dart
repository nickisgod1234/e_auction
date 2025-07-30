import 'package:e_auction/views/first_page/detail_page/detail_page.dart';
import 'package:e_auction/views/first_page/auction_page/quantity_reduction_auctions_page.dart';
import 'package:e_auction/views/first_page/auction_page/quantity_reduction_auction_detail_page.dart';
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
        // actions: [
        //   // ปุ่มดูประมูลลดตามจำนวน (AS03)
        //   TextButton.icon(
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //           builder: (context) => QuantityReductionAuctionsPage(),
        //         ),
        //       );
        //     },
        //     icon: Icon(
        //       Icons.trending_down,
        //       color: Colors.purple,
        //       size: 20,
        //     ),
        //     label: Text(
        //       'ประมูลลดจำนวน',
        //       style: TextStyle(
        //         color: Colors.purple,
        //         fontWeight: FontWeight.w500,
        //         fontSize: 14,
        //       ),
        //     ),
        //   ),
        // ],
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
                    // ตรวจสอบประเภทการประมูล
                    final quotationTypeCode = upcomingAuctions[index]['quotation_type_code']?.toString() ?? '';
                    
                    // ถ้าเป็น AS03 ให้ไปหน้า Quantity Reduction Auction Detail
                    if (quotationTypeCode == 'AS03') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuantityReductionAuctionDetailPage(auctionData: upcomingAuctions[index]),
                        ),
                      );
                    } else {
                      // ประเภทอื่นๆ ไปหน้า Detail ปกติ
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(auctionData: upcomingAuctions[index]),
                        ),
                      );
                    }
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
