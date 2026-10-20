import 'dart:async';

import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/views/first_page/add_auction_page/add_auction_page.dart';
import 'package:e_auction/views/first_page/my_products_page/my_products_page.dart';
import 'package:e_auction/views/first_page/service_page/service_products_page.dart';
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

  Future<void> _navigateToAddAuction(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAuctionPage()),
    );
  }

  // นำทางไปหน้าแชท (ตรวจสอบ role)
  Future<void> _navigateToChat(BuildContext context) async {
    if (_isAdmin) {
      // Admin ไปหน้า Dashboard
      await Navigator.push(
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

  Future<void> _onBarTap(int index) async {
    if (index == 1) {
      await _navigateToAddAuction(context);
    } else if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ServiceProductsPage()),
      );
    } else if (index == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyProductsPage()),
      );
    } else if (index == 4) {
      await _navigateToChat(context);
    } else {
      widget.onItemTapped(index);
    }
  }

  Widget _buildChatIcon() {
    if (_unreadCount <= 0) {
      return const Icon(Icons.chat);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.chat),
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            constraints: const BoxConstraints(minWidth: 18),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              _unreadCount > 99 ? '99+' : '$_unreadCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset > 0 ? 8 : 12),
      child: Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BottomNavigationBar(
            currentIndex: widget.currentIndex,
            onTap: _onBarTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: context.customTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 10,
            unselectedFontSize: 9,
            iconSize: 22,
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'หน้าแรก',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.add_business),
                label: 'เพิ่มสินค้าประมูล',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.handyman_outlined),
                label: 'สินค้าบริการ',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2),
                label: 'สินค้าของฉัน',
              ),
              BottomNavigationBarItem(
                icon: _buildChatIcon(),
                label: _isAdmin ? 'Admin' : 'แชทกับเจ้าหน้าที่',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'ตั้งค่า',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
