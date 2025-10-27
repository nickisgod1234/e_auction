import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/views/first_page/add_auction_page/add_auction_page.dart';
import 'package:e_auction/views/first_page/chat_page/chat_page.dart';
import 'package:e_auction/views/first_page/admin_dashboard/admin_dashboard.dart';
import 'package:e_auction/utils/user_data_manager.dart';

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

  // นำทางไปหน้าแชท (ตรวจสอบ role)
  void _navigateToChat(BuildContext context) async {
    final isAdmin = await UserDataManager.isAdmin();
    
    if (isAdmin) {
      // Admin ไปหน้า Dashboard
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminDashboard()),
      );
    } else {
      // Customer ไปหน้า Chat
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserDataManager.isAdmin(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;
        
        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index == 1) {
              // Navigate to add auction page
              _navigateToAddAuction(context);
            } else if (index == 2) {
              // Navigate to chat page (role-based)
              _navigateToChat(context);
            } else {
              // Handle other tabs (index 0: home, index 3: settings)
              onItemTapped(index);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
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
              label: isAdmin ? 'Admin' : 'แชทกับเจ้าหน้าที่',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'ตั้งค่า',
            ),
          ],
        );
      },
    );
  }
}