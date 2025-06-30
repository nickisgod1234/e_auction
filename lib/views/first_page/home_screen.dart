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
import 'package:e_auction/views/first_page/request_otp_page/request_otp_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _pdpaDialogShown = false;

  @override
  void initState() {
    super.initState();
    _checkAndShowPdpaDialog();
  }

  Future<void> _checkAndShowPdpaDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final consent = prefs.getBool('userConsent') ?? false;
    final userId = prefs.getString('id') ?? '';
    final phoneNumber = prefs.getString('phone') ?? '';
    
    // ไม่แสดง PDPA dialog สำหรับ Apple test account
    if (userId == 'APPLE_TEST_ID' || phoneNumber == '0001112345') {
      return;
    }
    
    if (!consent && !_pdpaDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPdpaDialog();
      });
      _pdpaDialogShown = true;
    }
  }

  void _showPdpaDialog() {
    bool dontShowAgain = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.privacy_tip, color: Colors.black, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'นโยบายความเป็นส่วนตัว (PDPA)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('บริษัทฯ จะเก็บรวบรวม ใช้ และเปิดเผยข้อมูลส่วนบุคคลของท่านเพื่อวัตถุประสงค์ในการให้บริการตามที่ท่านร้องขอ โดยท่านสามารถศึกษารายละเอียดเพิ่มเติมได้ในนโยบายความเป็นส่วนตัวของบริษัทฯ'),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: dontShowAgain,
                        onChanged: (val) {
                          setState(() {
                            dontShowAgain = val ?? false;
                          });
                        },
                      ),
                      Expanded(child: Text('ไม่ต้องแสดงอีกจนกว่าจะปิดแอป')),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // ปฏิเสธ - ล้างข้อมูล user และกลับไปหน้า login
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('userConsent', false);
                    await prefs.remove('id');
                    await prefs.remove('phone');
                    await prefs.remove('token');
                    await prefs.remove('refno');
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => RequestOtpLoginPage()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                  child: Text('ไม่ยอมรับ', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('userConsent', true);
                    Navigator.of(context).pop();
                  },
                  child: Text('ยอมรับ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

  List<Map<String, dynamic>> _getFilteredAuctions(List<Map<String, dynamic>> auctions) {
    // Filter by search query if exists
    if (_searchQuery.isEmpty) {
      return auctions;
    }

    return auctions.where((auction) {
      final title = auction['title']?.toString().toLowerCase() ?? '';
      final searchLower = _searchQuery.toLowerCase();

      return title.contains(searchLower);
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
      
      // Reset search when home tab is tapped
      if (index == 0) {
        _searchQuery = '';
        _searchController.clear();
        _isSearching = false;
      }
    });
    
    // Navigate to different pages based on selected index
    if (index == 2) { // Settings tab
      await _navigateToPage(context, SettingPage());
      setState(() => _selectedIndex = 0); // Reset index after returning
    } else {
       setState(() {
        _selectedIndex = index;
        if (index == 0) {
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
        hintText: 'ค้นหาจากชื่อสินค้า...',
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: TextStyle(color: Colors.black, fontSize: 16),
      onChanged: _handleSearch,
      textInputAction: TextInputAction.search,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCurrentAuctions = _getFilteredAuctions(_currentAuctions);
    final filteredUpcomingAuctions = _getFilteredAuctions(_upcomingAuctions);

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
            // Disclaimer Banner
            Container(
              width: double.infinity,
              color: Colors.white,
              height: 36,
              child: Row(
                children: [
                  SizedBox(width: 8),
                  Icon(Icons.info_outline, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: MarqueeRunner(
                      child: Text(
                        '• บริษัทฯ ขอสงวนสิทธิ์ในการยกเลิกหรือเลื่อนการประมูลโดยไม่ต้องแจ้งเหตุผล   '
                        '• คำตัดสินของคณะกรรมการหรือผู้แทนบริษัทฯ ถือเป็นที่สิ้นสุด   '
                        '• บริษัทฯ ไม่รับผิดชอบต่อความเสียหายหรือข้อพิพาทที่อาจเกิดขึ้นหลังจากการส่งมอบสินค้า',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                      millisecondsPerPixel: 20,
                      pauseDuration: Duration(seconds: 1),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
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
            SizedBox(height: 15),

            // My Auctions Section
            Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ประวัติการประมูลของฉัน',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                ],
              ),
            ),
            // My Auctions Preview Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    _navigateToPage(context, MyAuctionsPage());
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.history,
                            color: Colors.blue,
                            size: 32,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ดูประวัติการประมูลทั้งหมด',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'กำลังประมูล • ชนะ • ไม่ชนะ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom spacing
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
