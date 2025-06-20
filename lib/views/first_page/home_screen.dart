import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:e_auction/views/first_page/widget_home_cm/current_auction_card.dart';
import 'package:e_auction/views/first_page/widget_home_cm/upcoming_auction_card.dart';
// import 'package:e_auction/views/first_page/widget_home_cm/completed_auction_card.dart';
import 'package:e_auction/views/first_page/widget_home_cm/bottom_navigation_bar.dart';
import 'package:e_auction/views/first_page/profile_page/profile.dart';
import 'package:e_auction/views/first_page/setting_page/setting_page.dart';
import 'package:e_auction/views/first_page/auction_page/current_auction_page.dart';
import 'package:e_auction/views/first_page/detail_page/detail_page.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/views/first_page/auction_page/all_current_auctions_page.dart';
import 'package:e_auction/views/first_page/auction_page/all_upcoming_auctions_page.dart';
import 'package:e_auction/views/first_page/auction_page/my_auctions_page.dart';
import 'package:e_auction/views/first_page/auction_page/all_winner_announcements_page.dart';
import 'package:e_auction/views/first_page/widget_home_cm/winner_announcement_card.dart';
import 'package:e_auction/views/first_page/auction_page/auction_result_page.dart';
import 'package:e_auction/views/first_page/notification_page/notification_page.dart';
import 'package:intl/intl.dart';
import 'package:e_auction/views/first_page/widget_home_cm/marquee_runner.dart';
import 'package:e_auction/utils/loading_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {
      'icon': Icons.grid_view,
      'label': 'ทั้งหมด',
      'id': 'all'
    },
    {
      'icon': Icons.watch,
      'label': 'นาฬิกา',
      'id': 'watches'
    },
    {
      'icon': Icons.phone_iphone,
      'label': 'มือถือ',
      'id': 'phones'
    },
    {
      'icon': Icons.laptop_mac,
      'label': 'คอมพิวเตอร์',
      'id': 'computers'
    },
    {
      'icon': Icons.camera_alt,
      'label': 'กล้อง',
      'id': 'cameras'
    },
    {
      'icon': Icons.shopping_bag,
      'label': 'กระเป๋า',
      'id': 'bags'
    },
    {
      'icon': Icons.car_rental,
      'label': 'รถยนต์',
      'id': 'cars'
    },
    {
      'icon': Icons.diamond,
      'label': 'เครื่องประดับ',
      'id': 'jewelry'
    },
    {
      'icon': Icons.sports_esports,
      'label': 'เกมส์',
      'id': 'games'
    },
  ];

  // Mock data for current auctions
  final List<Map<String, dynamic>> _currentAuctions = [
    {
      'id': 'rolex_submariner_001',
      'title': 'Rolex Submariner',
      'currentPrice': 850000,
      'startingPrice': 800000,
      'bidCount': 12,
      'timeRemaining': 'เหลือ 2:30:45',
      'isActive': true,
      'image': 'assets/images/m126618lb-0002.png',
      'description': 'นาฬิกา Rolex Submariner รุ่นคลาสสิก วัสดุคุณภาพสูง มาพร้อมกับกล่องและเอกสารรับประกัน อยู่ในสภาพดีมาก เหมาะสำหรับนักสะสมและผู้ที่ชื่นชอบนาฬิกาคุณภาพสูง',
      'brand': 'Rolex',
      'model': 'Submariner',
      'material': 'สแตนเลสสตีล',
      'size': '40mm',
      'color': 'ดำ',
      'condition': 'ดีมาก',
      'sellerName': 'ผู้ขายมืออาชีพ',
      'sellerRating': '4.8',
      'category': 'watches'
    },
    {
      'id': 'iphone_15_pro_max_002',
      'title': 'iPhone 15 Pro Max',
      'currentPrice': 45000,
      'startingPrice': 40000,
      'bidCount': 8,
      'timeRemaining': 'เหลือ 1:15:30',
      'isActive': true,
      'image': 'assets/images/4ebcdc_032401a646044297adbcf3438498a19b~mv2.png',
      'description': 'iPhone 15 Pro Max สี Titanium Natural 256GB อยู่ในสภาพใหม่ มาพร้อมกับกล่องและอุปกรณ์ครบชุด',
      'brand': 'Apple',
      'model': 'iPhone 15 Pro Max',
      'material': 'Titanium',
      'size': '6.7 นิ้ว',
      'color': 'Titanium Natural',
      'condition': 'ใหม่',
      'sellerName': 'Apple Store Thailand',
      'sellerRating': '4.9',
      'category': 'phones'
    },
    {
      'id': 'macbook_pro_m3_003',
      'title': 'MacBook Pro M3',
      'currentPrice': 75000,
      'startingPrice': 70000,
      'bidCount': 15,
      'timeRemaining': 'เหลือ 3:45:20',
      'isActive': true,
      'image': 'assets/images/noimage.jpg',
      'description': 'MacBook Pro 14 นิ้ว พร้อมชิป M3 512GB SSD 16GB RAM อยู่ในสภาพดีมาก เหมาะสำหรับงานกราฟิกและพัฒนาโปรแกรม',
      'brand': 'Apple',
      'model': 'MacBook Pro M3',
      'material': 'Aluminum',
      'size': '14 นิ้ว',
      'color': 'Space Gray',
      'condition': 'ดีมาก',
      'sellerName': 'Tech Store',
      'sellerRating': '4.7',
      'category': 'computers'
    },
    {
      'id': 'sony_a7r_v_004',
      'title': 'Sony A7R V Camera',
      'currentPrice': 120000,
      'startingPrice': 110000,
      'bidCount': 6,
      'timeRemaining': 'เหลือ 0:30:15',
      'isActive': true,
      'image': 'assets/images/noimage.jpg',
      'description': 'กล้อง DSLR Sony A7R V 61MP มาพร้อมกับเลนส์ 24-70mm f/2.8 GM อยู่ในสภาพดีมาก',
      'brand': 'Sony',
      'model': 'A7R V',
      'material': 'Magnesium Alloy',
      'size': 'Full Frame',
      'color': 'ดำ',
      'condition': 'ดีมาก',
      'sellerName': 'Camera Pro',
      'sellerRating': '4.6',
      'category': 'cameras'
    },
  ];

  // Mock data for upcoming auctions
  final List<Map<String, dynamic>> _upcomingAuctions = [
    {
      'id': 'patek_nautilus_006',
      'title': 'Patek Philippe Nautilus',
      'startingPrice': 1500000,
      'timeUntilStart': '2 วัน',
      'isActive': false,
      'image': 'assets/images/The-ultimative-Patek-Philippe-Nautilus-Guide.jpg',
      'description': 'นาฬิกา Patek Philippe Nautilus รุ่น 5711/1A สีฟ้า วัสดุสแตนเลสสตีล อยู่ในสภาพดีมาก มาพร้อมกับกล่องและเอกสารรับประกัน',
      'brand': 'Patek Philippe',
      'model': 'Nautilus 5711/1A',
      'material': 'สแตนเลสสตีล',
      'size': '40.5mm',
      'color': 'ฟ้า',
      'condition': 'ดีมาก',
      'sellerName': 'Luxury Watches',
      'sellerRating': '5.0',
      'category': 'watches'
    },
    {
      'id': 'tesla_model_s_007',
      'title': 'Tesla Model S',
      'startingPrice': 3500000,
      'timeUntilStart': '5 วัน',
      'isActive': false,
      'image': 'assets/images/testlamodels.png',
      'description': 'รถยนต์ไฟฟ้า Tesla Model S Long Range สีแดง 2023 อยู่ในสภาพใหม่ วิ่งได้ 396 ไมล์ต่อการชาร์จหนึ่งครั้ง',
      'brand': 'Tesla',
      'model': 'Model S Long Range',
      'material': 'Aluminum',
      'size': 'Sedan',
      'color': 'แดง',
      'condition': 'ใหม่',
      'sellerName': 'Tesla Thailand',
      'sellerRating': '4.8',
      'category': 'cars'
    },
    {
      'id': 'chanel_classic_flap_008',
      'title': 'Chanel Classic Flap',
      'startingPrice': 180000,
      'timeUntilStart': '1 วัน',
      'isActive': false,
      'image': 'assets/images/noimage.jpg',
      'description': 'กระเป๋า Chanel Classic Flap Medium สีดำ มาพร้อมกับกล่องและเอกสารรับประกัน อยู่ในสภาพดีมาก',
      'brand': 'Chanel',
      'model': 'Classic Flap Medium',
      'material': 'Caviar Leather',
      'size': 'Medium',
      'color': 'ดำ',
      'condition': 'ดีมาก',
      'sellerName': 'Chanel Boutique',
      'sellerRating': '4.9',
    },
    {
      'id': 'leica_m11_009',
      'title': 'Leica M11 Camera',
      'startingPrice': 280000,
      'timeUntilStart': '3 วัน',
      'isActive': false,
      'image': 'assets/images/noimage.jpg',
      'description': 'กล้อง Leica M11 Digital Rangefinder 60MP มาพร้อมกับเลนส์ Summilux-M 50mm f/1.4 ASPH อยู่ในสภาพดีมาก',
      'brand': 'Leica',
      'model': 'M11',
      'material': 'Magnesium Alloy',
      'size': 'Rangefinder',
      'color': 'ดำ',
      'condition': 'ดีมาก',
      'sellerName': 'Leica Store',
      'sellerRating': '4.7',
    },
  ];

  // Mock data for winner announcements - sorted with the most recent first
  final List<Map<String, dynamic>> _winnerAnnouncements = [
    {
      'id': 'apple_watch_ultra_011',
      'title': 'Apple Watch Ultra',
      'finalPrice': 32000,
      'image': 'assets/images/AppleWatch_Ultra_Titanium_MidnightOceanBand_1200x.png',
      'winner': 'คุณ Tech L.',
      'completedDate': '1 วันที่แล้ว',
      'category': 'watches',
      'bidCount': 25,
      'duration': '7 วัน',
      'viewCount': 1247,
      'startDate': '15 มกราคม 2024',
      'endDate': '22 มกราคม 2024',
      'startingPrice': 28000,
      'sellerName': 'Apple Store Thailand',
    },
    {
      'id': 'cartier_santos_010',
      'title': 'Cartier Santos',
      'finalPrice': 680000,
      'image':
          'assets/images/wssa0063-cartier-santos-de-cartier-medium-model-car0356037.png',
      'winner': 'คุณ Panuwat S.',
      'completedDate': '2 วันที่แล้ว',
      'category': 'watches',
      'bidCount': 18,
      'duration': '5 วัน',
      'viewCount': 892,
      'startDate': '17 มกราคม 2024',
      'endDate': '22 มกราคม 2024',
      'startingPrice': 600000,
      'sellerName': 'Luxury Timepieces',
    },
    {
      'id': 'louis_vuitton_keepall_012',
      'title': 'Louis Vuitton Keepall',
      'finalPrice': 85000,
      'image': 'assets/images/noimage.jpg',
      'winner': 'คุณ Travel P.',
      'completedDate': '3 วันที่แล้ว',
      'category': 'bags',
      'description':
          'กระเป๋าเดินทาง Louis Vuitton Keepall 55cm สี Monogram Canvas อยู่ในสภาพดีมาก มาพร้อมกับกล่องและเอกสารรับประกัน',
      'brand': 'Louis Vuitton',
      'model': 'Keepall 55',
      'material': 'Monogram Canvas',
      'size': '55cm',
      'color': 'Monogram',
      'condition': 'ดีมาก',
      'sellerName': 'LV Boutique',
      'sellerRating': '4.7',
      'bidCount': 32,
      'duration': '10 วัน',
      'viewCount': 1567,
      'startDate': '12 มกราคม 2024',
      'endDate': '22 มกราคม 2024',
      'startingPrice': 70000,
    },
    {
      'id': 'canon_eos_r5_013',
      'title': 'Canon EOS R5',
      'finalPrice': 95000,
      'image': 'assets/images/noimage.jpg',
      'winner': 'คุณ Photo M.',
      'completedDate': '5 วันที่แล้ว',
      'category': 'cameras',
      'description':
          'กล้อง Mirrorless Canon EOS R5 45MP มาพร้อมกับเลนส์ RF 24-105mm f/4L IS USM อยู่ในสภาพดีมาก',
      'brand': 'Canon',
      'model': 'EOS R5',
      'material': 'Magnesium Alloy',
      'size': 'Full Frame',
      'color': 'ดำ',
      'condition': 'ดีมาก',
      'sellerName': 'Canon Thailand',
      'sellerRating': '4.6',
      'bidCount': 15,
      'duration': '7 วัน',
      'viewCount': 734,
      'startDate': '15 มกราคม 2024',
      'endDate': '22 มกราคม 2024',
      'startingPrice': 85000,
    },
  ];

  List<Map<String, dynamic>> _getFilteredAuctions(List<Map<String, dynamic>> auctions) {
    // First filter by category
    List<Map<String, dynamic>> categoryFiltered = _selectedCategoryIndex == 0
        ? auctions
        : auctions.where((auction) => auction['category'] == _categories[_selectedCategoryIndex]['id']).toList();

    // Then filter by search query if exists
    if (_searchQuery.isEmpty) {
      return categoryFiltered;
    }

    return categoryFiltered.where((auction) {
      final title = auction['title']?.toString().toLowerCase() ?? '';
      final category = _categories
          .firstWhere((cat) => cat['id'] == auction['category'],
              orElse: () => {'label': ''})['label']
          .toString()
          .toLowerCase();
      final searchLower = _searchQuery.toLowerCase();

      return title.contains(searchLower) || category.contains(searchLower);
    }).toList();
  }

  Future<void> _navigateToPage(BuildContext context, Widget page) async {
    LoadingService.instance.show();
    // Simulate a network delay or data fetching
    await Future.delayed(const Duration(milliseconds: 300));
    LoadingService.instance.hide(); // Hide the loader BEFORE pushing the new page

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    }
  }

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
      
      // Reset category filter to "ทั้งหมด" when home tab is tapped
      if (index == 0) {
        _selectedCategoryIndex = 0;
        _searchQuery = '';
        _searchController.clear();
        _isSearching = false;
      }
    });
    
    // Navigate to different pages based on selected index
    if (index == 2) { // Current Auction tab
      await _navigateToPage(context, CurrentAuctionPage());
      setState(() => _selectedIndex = 0); // Reset index after returning
    } else if (index == 3) { // Profile tab
      await _navigateToPage(context, ProfilePage());
      setState(() => _selectedIndex = 0);
    } else if (index == 4) { // Setting tab
      await _navigateToPage(context, SettingPage());
      setState(() => _selectedIndex = 0);
    } else {
       setState(() {
        _selectedIndex = index;
        if (index == 0) {
          _selectedCategoryIndex = 0;
          _searchQuery = '';
          _searchController.clear();
          _isSearching = false;
        }
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _handleSearch(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'ค้นหาจากชื่อสินค้าหรือหมวดหมู่...',
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: TextStyle(color: Colors.black, fontSize: 16),
      onChanged: _handleSearch,
      textInputAction: TextInputAction.search,
    );
  }

  Widget _buildCategoryItem(int index) {
    final category = _categories[index];
    final isSelected = _selectedCategoryIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
        // Handle category selection here
        print('Selected category: ${category['label']}');
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.customTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? context.customTheme.primaryColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category['icon'],
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            SizedBox(width: 6),
            Text(
              category['label'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCurrentAuctions = _getFilteredAuctions(_currentAuctions);
    final filteredUpcomingAuctions = _getFilteredAuctions(_upcomingAuctions);
    final filteredWinnerAnnouncements =
        _getFilteredAuctions(_winnerAnnouncements);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _isSearching
            ? _buildSearchField()
            : Text(
                AppTheme.getAppTitle(AppTheme.currentClient),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationPage(),
                    ),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.list_alt, color: Colors.black),
            onPressed: () {
              _navigateToPage(context, MyAuctionsPage());
            },
          ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.black,
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories Section
            Container(
              height: 50,
              margin: EdgeInsets.only(top: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) => _buildCategoryItem(index),
              ),
            ),

            // Show search results message when searching
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'ผลการค้นหาสำหรับ "$_searchQuery"',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            // Current Auctions Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'กำลังประมูล',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _navigateToPage(
                          context,
                          AllCurrentAuctionsPage(
                              currentAuctions: _currentAuctions));
                    },
                    child: Text(
                      'ดูทั้งหมด',
                      style: TextStyle(
                        color: context.customTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (filteredCurrentAuctions.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'ไม่พบรายการในหมวดหมู่นี้',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredCurrentAuctions.length,
                  itemBuilder: (context, index) {
                    return CurrentAuctionCard(auctionData: filteredCurrentAuctions[index]);
                  },
                ),
              ),

            // Upcoming Auctions Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'รายการประมูลที่กำลังจะมาถึง',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _navigateToPage(
                          context,
                          AllUpcomingAuctionsPage(
                              upcomingAuctions: _upcomingAuctions));
                    },
                    child: Text(
                      'ดูทั้งหมด',
                      style: TextStyle(
                        color: context.customTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (filteredUpcomingAuctions.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'ไม่พบรายการในหมวดหมู่นี้',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUpcomingAuctions.length,
                  itemBuilder: (context, index) {
                    return UpcomingAuctionCard(auctionData: filteredUpcomingAuctions[index]);
                  },
                ),
              ),

            // Winner Announcement Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ประกาศผลผู้ชนะ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _navigateToPage(
                          context,
                          AllWinnerAnnouncementsPage(
                              winnerAnnouncements: _winnerAnnouncements));
                    },
                    child: Text(
                      'ดูทั้งหมด',
                      style: TextStyle(
                        color: context.customTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Marquee text for latest winner
            if (filteredWinnerAnnouncements.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: MarqueeRunner(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '🎉 ล่าสุด! ${filteredWinnerAnnouncements.first['winner']} ชนะการประมูล ${filteredWinnerAnnouncements.first['title']} ในราคา ฿${NumberFormat('#,###').format(filteredWinnerAnnouncements.first['finalPrice'])} 🎉',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (filteredWinnerAnnouncements.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'ไม่พบรายการประกาศผลผู้ชนะ',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              _buildWinnerAnnouncementListItem(
                context,
                filteredWinnerAnnouncements.first,
                isLatest: true,
              ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildWinnerAnnouncementListItem(
      BuildContext context, Map<String, dynamic> auction,
      {bool isLatest = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              _navigateToPage(context, AuctionResultPage(auctionData: auction));
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      auction['image'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child:
                              Icon(Icons.image_not_supported, color: Colors.grey),
                        );
                      },
                    ),
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
                          'ผู้ชนะ: ${auction['winner']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ราคาปิด: ฿${NumberFormat('#,###').format(auction['finalPrice'])}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLatest)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'ล่าสุด',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
