import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/views/first_page/add_auction_page/add_auction_page.dart';
import 'package:e_auction/views/first_page/chat_page/chat_page.dart';

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
    );
  }

  void _navigateToChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage()),
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
        } else if (index == 2) {
          // Navigate to chat page
          _navigateToChat(context);
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
          icon: Icon(Icons.chat),
          label: 'แชทกับเจ้าหน้าที่',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'ตั้งค่า',
        ),
      ],
    );
  }
}