import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'package:e_auction/views/first_page/auction_page/quantity_reduction_auctions_page.dart';
import 'package:e_auction/views/first_page/auction_page/auction_detail_view_page.dart';
import 'package:e_auction/views/first_page/auction_page/quantity_reduction_auction_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:e_auction/views/first_page/widget_home_cm/marquee_runner.dart';

import 'package:e_auction/views/first_page/request_otp_page/request_otp_login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/services/product_service.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:e_auction/utils/time_calculator.dart';

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

  // ProductService instance
  late ProductService _productService;

  // Data lists
  List<Map<String, dynamic>> _currentAuctions = [];
  List<Map<String, dynamic>> _upcomingAuctions = [];
  List<Map<String, dynamic>> _quantityReductionAuctions = [];
  bool _isLoadingCurrent = true;
  bool _isLoadingUpcoming = true;
  bool _isLoadingQuantityReduction = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _productService = ProductService(baseUrl: Config.apiUrlAuction);
    _checkAndShowPdpaDialog();
    _loadAuctionData();
  }

  Future<void> _loadAuctionData() async {
    await Future.wait([
      _loadCurrentAuctions(),
      _loadUpcomingAuctions(),
      _loadQuantityReductionAuctions(),
    ]);
  }

  Future<void> _loadCurrentAuctions() async {
    try {
      setState(() {
        _isLoadingCurrent = true;
        _errorMessage = null;
      });

      final currentAuctions = await _productService.getCurrentAuctions();

      if (currentAuctions != null) {
        final formattedAuctions = currentAuctions.map((auction) {
          final formatted = _productService.convertToAppFormat(auction);
          print('DEBUG: HomeScreen - Current auction formatted: ${formatted['title']} - image: ${formatted['image']}');
          return formatted;
        }).toList();

        setState(() {
          _currentAuctions = formattedAuctions;
          _isLoadingCurrent = false;
        });
      } else {
        setState(() {
          _currentAuctions = [];
          _isLoadingCurrent = false;
        });
      }
    } catch (e) {
   
      setState(() {
        _errorMessage = 'ไม่สามารถโหลดข้อมูลการประมูลปัจจุบันได้';
        _isLoadingCurrent = false;
      });
    }
  }

  Future<void> _loadUpcomingAuctions() async {
    try {
      setState(() {
        _isLoadingUpcoming = true;
        _errorMessage = null;
      });

      final upcomingAuctions = await _productService.getUpcomingAuctions();

      if (upcomingAuctions != null) {
        // กรองเอา AS03 ออก (เพราะจะแสดงในส่วนประมูลสินค้าลดตามจำนวนแล้ว)
        final filteredAuctions = upcomingAuctions.where((auction) {
          final typeCode = auction['quotation_type_code']?.toString() ?? '';
          return typeCode != 'AS03'; // ไม่แสดง AS03 ในส่วนนี้
        }).toList();

        final formattedAuctions = filteredAuctions.map((auction) {
          final formatted = _productService.convertToAppFormat(auction);
          print('DEBUG: HomeScreen - Upcoming auction formatted: ${formatted['title']} - image: ${formatted['image']}');
          return formatted;
        }).toList();

        setState(() {
          _upcomingAuctions = formattedAuctions;
          _isLoadingUpcoming = false;
        });
      } else {
        setState(() {
          _upcomingAuctions = [];
          _isLoadingUpcoming = false;
        });
      }
    } catch (e) {
   
      setState(() {
        _errorMessage = 'ไม่สามารถโหลดข้อมูลการประมูลที่กำลังจะมาถึงได้';
        _isLoadingUpcoming = false;
      });
    }
  }

  Future<void> _loadQuantityReductionAuctions() async {
    try {
      setState(() {
        _isLoadingQuantityReduction = true;
        _errorMessage = null;
      });

      final allAuctions = await _productService.getAllAuctionProducts();

      if (allAuctions != null) {
        // กรองเฉพาะ AS03 และที่ยังไม่เริ่มประมูล
        final as03UpcomingAuctions = allAuctions.where((auction) {
          final typeCode = auction['quotation_type_code']?.toString() ?? '';
          final startDate = DateTime.tryParse(auction['auction_start_date'] ?? '');
          final endDate = DateTime.tryParse(auction['auction_end_date'] ?? '');
          
          // ใช้ TimeCalculator เพื่อตรวจสอบสถานะ
          final status = TimeCalculator.getAuctionStatus(
            startDate: startDate,
            endDate: endDate,
          );
          
          return typeCode == 'AS03' && status == 'upcoming';
        }).toList();

        final formattedAuctions = as03UpcomingAuctions.map((auction) {
          final formatted = _productService.convertToAppFormat(auction);
          print('DEBUG: HomeScreen - AS03 upcoming auction formatted: ${formatted['title']} - image: ${formatted['image']}');
          return formatted;
        }).toList();

        setState(() {
          _quantityReductionAuctions = formattedAuctions;
          _isLoadingQuantityReduction = false;
        });
        
       
      } else {
        setState(() {
          _quantityReductionAuctions = [];
          _isLoadingQuantityReduction = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถโหลดข้อมูลการประมูลแบบลดจำนวนได้';
        _isLoadingQuantityReduction = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadAuctionData();
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.privacy_tip, color: Colors.black, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'นโยบายความเป็นส่วนตัว (PDPA)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'บริษัทฯ จะเก็บรวบรวม ใช้ และเปิดเผยข้อมูลส่วนบุคคลของท่านเพื่อวัตถุประสงค์ในการให้บริการตามที่ท่านร้องขอ โดยท่านสามารถศึกษารายละเอียดเพิ่มเติมได้ในนโยบายความเป็นส่วนตัวของบริษัทฯ'),
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
                        MaterialPageRoute(
                            builder: (context) => RequestOtpLoginPage()),
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

  List<Map<String, dynamic>> _getFilteredAuctions(
      List<Map<String, dynamic>> auctions) {
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
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    }
  }

  void _onItemTapped(int index) async {
    // Reset search when home tab is tapped
    if (index == 0) {
      setState(() {
        _selectedIndex = index;
        _searchQuery = '';
        _searchController.clear();
        _isSearching = false;
      });
    } else if (index == 2) {
      // Settings tab
      await _navigateToPage(context, SettingPage());
      setState(() => _selectedIndex = 0); // Reset index after returning
    } else {
      // Keep current index for other tabs
      setState(() {
        _selectedIndex = 0; // Always stay on home tab
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

  Future<void> _openPlayStore() async {
    final url = Uri.parse('https://play.google.com/store/apps/details?id=com.cloudmate.th.e_auction');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Show error message if URL cannot be launched
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเปิด Play Store ได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Widget _buildLoadingCard() {
    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 200,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 32),
              SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _refreshData,
                child: Text('ลองใหม่', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 200,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, color: Colors.grey, size: 32),
              SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityReductionCard(Map<String, dynamic> auctionData) {
    final quantity = auctionData['quantity'] ?? 0;
    


    // คำนวณเวลาที่เหลือ
    final startDate = _parseDateTime(auctionData['auction_start_date']);
    final endDate = _parseDateTime(auctionData['auction_end_date']);
    final status = auctionData['status'] ?? 'unknown';
    final timeRemaining = TimeCalculator.calculateTimeRemaining(
      startDate: startDate,
      endDate: endDate,
      status: status,
    );

    
    return Container(
      width: 300,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuantityReductionAuctionDetailPage(auctionData: auctionData),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // รูปภาพสินค้า
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 280,
                width: 300,
                child: _buildAuctionImage(auctionData['image']),
              ),
            ),
            
            // ป้ายสถานะและประเภท (อยู่บนรูป)
            Positioned(
              top: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ป้าย "ยังไม่เริ่ม"
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ยังไม่เริ่ม',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  // ป้าย "ลดตามจำนวน"
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_down,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'ลดตามจำนวน',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // ป้ายแสดงเวลาที่เหลือ (อยู่บนขวา)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      timeRemaining,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // ข้อมูลสินค้า (อยู่ด้านล่างรูป)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อสินค้า
                    Text(
                      auctionData['title'] ?? 'ไม่ระบุชื่อสินค้า',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 8),
                    
                    // จำนวนสินค้า
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: Colors.purple[300],
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'จำนวน: $quantity รายการ',
                          style: TextStyle(
                            color: Colors.purple[300],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    
                    // ราคา
                    Row(
                      children: [
                        Text(
                          '฿${NumberFormat('#,###').format(auctionData['startingPrice'] ?? 0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[300],
                          ),
                        ),
                        Spacer(),
                        // ปุ่ม "รอเริ่ม"
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'รอเริ่ม',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to parse date time
  DateTime? _parseDateTime(dynamic dateTimeValue) {

    
    if (dateTimeValue == null) {

      return null;
    }
    
    if (dateTimeValue is DateTime) {

      return dateTimeValue;
    } else if (dateTimeValue is String) {
      try {
        final parsed = DateTime.parse(dateTimeValue);

        return parsed;
      } catch (e) {

        return null;
      }
    }
    
  
    return null;
  }

  Widget _buildAuctionImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 32,
                color: Colors.grey[400],
              ),
              SizedBox(height: 4),
              Text(
                'ไม่มีรูปภาพ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 32,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 4),
                Text(
                  'ไม่สามารถโหลดรูปภาพ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
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
          // Stack(
          //   children: [
          //     IconButton(
          //       icon: Icon(Icons.notifications_outlined, color: Colors.black),
          //       onPressed: () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (context) => NotificationPage(),
          //           ),
          //         );
          //       },
          //     ),
          //     Positioned(
          //       right: 8,
          //       top: 8,
          //       child: Container(
          //         padding: const EdgeInsets.all(2),
          //         decoration: BoxDecoration(
          //           color: Colors.red,
          //           borderRadius: BorderRadius.circular(10),
          //         ),
          //         constraints: const BoxConstraints(
          //           minWidth: 16,
          //           minHeight: 16,
          //         ),
          //         child: const Text(
          //           '1',
          //           style: TextStyle(
          //             color: Colors.white,
          //             fontSize: 10,
          //             fontWeight: FontWeight.bold,
          //           ),
          //           textAlign: TextAlign.center,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          if (Platform.isAndroid)
            Container(
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF01875F), Color(0xFF00C851)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: _openPlayStore,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/google-play.png',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'ให้คะแนนแอพนี้',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
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
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
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
              SizedBox(
                height: 200,
                child: _isLoadingCurrent
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 3,
                        itemBuilder: (context, index) => _buildLoadingCard(),
                      )
                    : _errorMessage != null
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 1,
                            itemBuilder: (context, index) =>
                                _buildErrorCard(_errorMessage!),
                          )
                        : filteredCurrentAuctions.isEmpty
                            ? ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: 1,
                                itemBuilder: (context, index) =>
                                    _buildEmptyCard(
                                        'ไม่มีรายการประมูลปัจจุบัน'),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filteredCurrentAuctions.length,
                                itemBuilder: (context, index) {
                                  return CurrentAuctionCard(
                                      auctionData:
                                          filteredCurrentAuctions[index]);
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
              SizedBox(
                height: 200,
                child: _isLoadingUpcoming
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 3,
                        itemBuilder: (context, index) => _buildLoadingCard(),
                      )
                    : _errorMessage != null
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 1,
                            itemBuilder: (context, index) =>
                                _buildErrorCard(_errorMessage!),
                          )
                        : filteredUpcomingAuctions.isEmpty
                            ? ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: 1,
                                itemBuilder: (context, index) =>
                                    _buildEmptyCard(
                                        'ไม่มีรายการประมูลที่กำลังจะมาถึง'),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filteredUpcomingAuctions.length,
                                itemBuilder: (context, index) {
                                  return UpcomingAuctionCard(
                                      auctionData:
                                          filteredUpcomingAuctions[index]);
                                },
                              ),
              ),
              SizedBox(height: 15),

              // Quantity Reduction Auctions Section
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ประมูลสินค้าลดตามจำนวน',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _navigateToPage(context, QuantityReductionAuctionsPage());
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
              
              // Quantity Reduction Auctions List
              SizedBox(
                height: 280,
                child: _isLoadingQuantityReduction
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 3,
                        itemBuilder: (context, index) => _buildLoadingCard(),
                      )
                    : _errorMessage != null
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 1,
                            itemBuilder: (context, index) =>
                                _buildErrorCard(_errorMessage!),
                          )
                        : _quantityReductionAuctions.isEmpty
                            ? ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: 1,
                                itemBuilder: (context, index) =>
                                    _buildEmptyCard('ไม่มีสินค้าประมูลแบบลดจำนวน'),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _quantityReductionAuctions.length,
                                itemBuilder: (context, index) {
                                  return _buildQuantityReductionCard(
                                      _quantityReductionAuctions[index]);
                                },
                              ),
              ),

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
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
