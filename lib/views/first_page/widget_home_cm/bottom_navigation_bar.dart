import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/views/first_page/add_auction_page/add_auction_page.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  void _navigateToAddAuction(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAuctionPage()),
    // แสดง dialog "อยู่ระหว่างปรับปรุง"
    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       shape: RoundedRectangleBorder(
    //         borderRadius: BorderRadius.circular(16),
    //       ),
    //       title: Row(
    //         children: [
    //           Icon(
    //             Icons.engineering,
    //             color: Colors.orange,
    //             size: 28,
    //           ),
    //           SizedBox(width: 12),
    //           Text(
    //             'อยู่ระหว่างปรับปรุง',
    //             style: TextStyle(
    //               fontSize: 20,
    //               fontWeight: FontWeight.bold,
    //               color: Colors.orange[700],
    //             ),
    //           ),
    //         ],
    //       ),
    //       content: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           Text(
    //             'ฟีเจอร์ "เพิ่มสินค้าประมูล" กำลังอยู่ระหว่างการพัฒนาและปรับปรุง',
    //             style: TextStyle(
    //               fontSize: 16,
    //               color: Colors.grey[700],
    //               height: 1.4,
    //             ),
    //           ),
    //           SizedBox(height: 16),
    //           Container(
    //             padding: EdgeInsets.all(12),
    //             decoration: BoxDecoration(
    //               color: Colors.blue.withOpacity(0.1),
    //               borderRadius: BorderRadius.circular(8),
    //               border: Border.all(color: Colors.blue.withOpacity(0.3)),
    //             ),
    //             child: Row(
    //               children: [
    //                 Icon(
    //                   Icons.info_outline,
    //                   color: Colors.blue,
    //                   size: 20,
    //                 ),
    //                 SizedBox(width: 8),
    //                 Expanded(
    //                   child: Text(
    //                     'เราจะแจ้งให้ทราบเมื่อฟีเจอร์นี้พร้อมใช้งาน',
    //                     style: TextStyle(
    //                       fontSize: 14,
    //                       color: Colors.blue[700],
    //                       fontWeight: FontWeight.w500,
    //                     ),
    //                   ),
    //                 ),
    //               ],
    //             ),
    //           ),
    //         ],
    //       ),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.of(context).pop(),
    //           child: Text(
    //             'เข้าใจแล้ว',
    //             style: TextStyle(
    //               fontSize: 16,
    //               fontWeight: FontWeight.w600,
    //               color: Colors.orange[700],
    //             ),
    //           ),
    //         ),
    //       ],
    //     );
    //   },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 1) {
          // Navigate to add auction page
          _navigateToAddAuction(context);
        } else {
          onItemTapped(index);
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: context.customTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'หน้าแรก',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_business),
          label: 'เพิ่มสินค้าประมูล',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'ตั้งค่า',
        ),
      ],
    );
  }
}