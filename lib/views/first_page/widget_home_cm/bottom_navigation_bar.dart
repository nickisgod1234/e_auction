import 'dart:async';

import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/views/first_page/add_auction_page/add_auction_page.dart';
import 'package:e_auction/views/first_page/chat_page/chat_page.dart';
import 'package:e_auction/views/first_page/admin_dashboard/admin_dashboard.dart';
import 'package:e_auction/services/chat_unread_service.dart';
import 'package:e_auction/utils/user_data_manager.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar>
    with WidgetsBindingObserver {
  /// แอปไม่มี push notification จึงต้อง poll เพื่อให้ badge อัปเดตเอง
  static const Duration _pollInterval = Duration(seconds: 30);

  bool _isAdmin = false;
  int _unreadCount = 0;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUnreadCount();
    }
  }

  Future<void> _initialize() async {
    final isAdmin = await UserDataManager.isAdmin();
    if (!mounted) return;

    setState(() {
      _isAdmin = isAdmin;
    });

    // badge ของ admin นับจาก session ของลูกค้าหลายคน ยังไม่รองรับในเฟสนี้
    if (isAdmin) return;

    await _refreshUnreadCount();
    _pollingTimer = Timer.periodic(_pollInterval, (_) {
      _refreshUnreadCount();
    });
  }

  Future<void> _refreshUnreadCount() async {
    if (_isAdmin) return;

    final count = await ChatUnreadService.getUnreadCount();
    if (!mounted || count == _unreadCount) return;

    setState(() {
      _unreadCount = count;
    });
  }

  void _navigateToAddAuction(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAuctionPage()),
    );
  }

  // นำทางไปหน้าแชท (ตรวจสอบ role)
  void _navigateToChat(BuildContext context) async {
    if (_isAdmin) {
      // Admin ไปหน้า Dashboard
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminDashboard()),
      );
      return;
    }

    // Customer ไปหน้า Chat แล้วนับใหม่ เพราะหน้าแชท mark read ให้แล้ว
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage()),
    );
    await _refreshUnreadCount();
  }

  Widget _buildChatIcon() {
    if (_unreadCount <= 0) {
      return Icon(Icons.chat);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.chat),
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            constraints: BoxConstraints(minWidth: 18),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              _unreadCount > 99 ? '99+' : '$_unreadCount',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) {
        if (index == 1) {
          // Navigate to add auction page
          _navigateToAddAuction(context);
        } else if (index == 2) {
          // Navigate to chat page (role-based)
          _navigateToChat(context);
        } else {
          // Handle other tabs (index 0: home, index 3: settings)
          widget.onItemTapped(index);
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
          icon: _buildChatIcon(),
          label: _isAdmin ? 'Admin' : 'แชทกับเจ้าหน้าที่',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'ตั้งค่า',
        ),
      ],
    );
  }
}
