import 'package:flutter/material.dart';
import 'package:e_auction/views/first_page/detail_page/detail_page.dart';
import 'package:e_auction/views/first_page/auction_page/auction_detail_view_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/services/auth_service/auth_service.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:e_auction/views/first_page/widgets/my_auctions_widget.dart';
import 'package:e_auction/utils/format.dart';
import 'dart:async';

class MyAuctionsPage extends StatefulWidget {
  const MyAuctionsPage({super.key});

  @override
  State<MyAuctionsPage> createState() => _MyAuctionsPageState();
}

class _MyAuctionsPageState extends State<MyAuctionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  // Auth service instance
  late AuthService _authService;

  // Address data for zip code lookup
  List<Map<String, dynamic>> addressData = [];

  // Form controllers for winner information
  final Map<String, TextEditingController> _controllers = {
    'firstname': TextEditingController(),
    'lastname': TextEditingController(),
    'phone': TextEditingController(),
    'address': TextEditingController(),
    'taxNumber': TextEditingController(),
    'email': TextEditingController(),
    'provinceId': TextEditingController(),
    'districtId': TextEditingController(),
    'subDistrictId': TextEditingController(),
    'sub': TextEditingController(),
    'zipCode': TextEditingController(),
  };

  // Mock data for user's auction history
  final List<Map<String, dynamic>> _activeBids = [
    {
      'id': 'rolex_submariner_001',
      'title': 'Rolex Submariner',
      'myBid': 850000,
      'currentPrice': 860000,
      'timeRemaining': 'เหลือ 2:30:45',
      'image': 'assets/images/m126618lb-0002.png',
      'status': 'active', // active, outbid, winning
      'bidCount': 12,
      'myBidRank': 2, // ตำแหน่งการประมูลของฉัน
      'startingPrice': 800000,
      'description': 'นาฬิกา Rolex Submariner รุ่นคลาสสิก วัสดุคุณภาพสูง มาพร้อมกับกล่องและเอกสารรับประกัน อยู่ในสภาพดีมาก',
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
      'myBid': 45000,
      'currentPrice': 45000,
      'timeRemaining': 'เหลือ 1:15:30',
      'image': 'assets/images/4ebcdc_032401a646044297adbcf3438498a19b~mv2.png',
      'status': 'winning',
      'bidCount': 8,
      'myBidRank': 1,
      'startingPrice': 40000,
      'description': 'iPhone 15 Pro Max สี Titanium Natural 256GB สภาพใหม่',
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
      'id': 'hermes_birkin_005',
      'title': 'Hermès Birkin Bag',
      'myBid': 250000,
      'currentPrice': 255000,
      'timeRemaining': 'เหลือ 4:20:10',
      'image': 'assets/images/db10cd_5d78534c69064ecebbef175602c6bfe0~mv2.png',
      'status': 'outbid',
      'bidCount': 20,
      'myBidRank': 3,
      'startingPrice': 200000,
      'description': 'กระเป๋า Hermès Birkin 30cm สี Black Togo Leather อยู่ในสภาพดีมาก',
      'brand': 'Hermès',
      'model': 'Birkin 30',
      'material': 'Togo Leather',
      'size': '30cm',
      'color': 'ดำ',
      'condition': 'ดีมาก',
      'sellerName': 'Luxury Collection',
      'sellerRating': '4.9',
      'category': 'bags'
    },
  ];

  final List<Map<String, dynamic>> _wonAuctions = [
    {
      'id': 'cartier_santos_010',
      'title': 'Cartier Santos',
      'finalPrice': 680000,
      'myBid': 680000,
      'completedDate': '2 วันที่แล้ว',
      'image': 'assets/images/wssa0063-cartier-santos-de-cartier-medium-model-car0356037.png',
      'status': 'won',
      'sellerName': 'Luxury Timepieces',
      'paymentStatus': 'paid', // paid, pending, overdue
      'auctionId': 'AUCT-2025-010',
    },
    {
      'id': 'apple_watch_ultra_011',
      'title': 'Apple Watch Ultra',
      'finalPrice': 32000,
      'myBid': 32000,
      'completedDate': '1 วันที่แล้ว',
      'image': 'assets/images/noimage.jpg',
      'status': 'won',
      'sellerName': 'Apple Store Thailand',
      'paymentStatus': 'pending',
      'auctionId': 'AUCT-2025-011',
    },
    {
      'id': 'rolex_daytona_012',
      'title': 'Rolex Daytona',
      'finalPrice': 1200000,
      'myBid': 1200000,
      'completedDate': '3 ชั่วโมงที่แล้ว',
      'image': 'assets/images/The-ultimative-Patek-Philippe-Nautilus-Guide.jpg',
      'status': 'won',
      'sellerName': 'Luxury Watches Collection',
      'paymentStatus': 'pending',
      'auctionId': 'AUCT-2025-012',
    },
  ];

  final List<Map<String, dynamic>> _lostAuctions = [
    {
      'id': 'patek_nautilus_006',
      'title': 'Patek Philippe Nautilus',
      'finalPrice': 1500000,
      'myBid': 1450000,
      'completedDate': '3 วันที่แล้ว',
      'image': 'assets/images/The-ultimative-Patek-Philippe-Nautilus-Guide.jpg',
      'status': 'lost',
      'winnerBid': 1500000,
      'sellerName': 'Luxury Watches',
    },
    {
      'id': 'tesla_model_s_007',
      'title': 'Tesla Model S',
      'finalPrice': 3500000,
      'myBid': 3400000,
      'completedDate': '5 วันที่แล้ว',
      'image': 'assets/images/testlamodels.png',
      'status': 'lost',
      'winnerBid': 3500000,
      'sellerName': 'Tesla Thailand',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _authService = AuthService(baseUrl: Config.apiUrlotpsever);
    _loadAddressData();
  }

  Future<void> _loadAddressData() async {
    try {
      final data = await _authService.getAddressData();
      if (mounted) {
        setState(() {
          addressData = data;
        });
      }
    } catch (e) {
      // fallback: do nothing, addressData will be empty
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // Save winner information using auth service
  Future<void> _saveWinnerInfoToServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id') ?? '';
      
      if (userId.isEmpty) {
        throw Exception('ไม่พบข้อมูล ID ผู้ใช้');
      }

      final result = await _authService.saveUser(
        phoneUserId: userId, // ใช้ id แทนเบอร์โทร
        firstname: _controllers['firstname']!.text.trim(),
        lastname: _controllers['lastname']!.text.trim(),
        email: _controllers['email']!.text.trim(),
        phone: _controllers['phone']!.text.replaceAll(RegExp(r'[^0-9]'), ''),
        address: _controllers['address']!.text.trim(),
        provinceId: _controllers['provinceId']!.text.trim(),
        districtId: _controllers['districtId']!.text.trim(),
        subDistrictId: _controllers['subDistrictId']!.text.trim(),
        sub: _controllers['sub']!.text.trim(),
        type: 'individual',
        companyId: '1',
        taxNumber: _controllers['taxNumber']!.text.trim().isNotEmpty ? _controllers['taxNumber']!.text.trim() : '',
        code: 'CUST${DateTime.now().millisecondsSinceEpoch}', // สร้าง code อัตโนมัติ
      );

      if (result != null && result['success'] == true) {
        // บันทึกข้อมูลลง SharedPreferences ด้วย
        await _saveWinnerInfo();
        print('บันทึกข้อมูลผู้ชนะเรียบร้อยแล้ว');
      } else {
        throw Exception(result?['message'] ?? 'เกิดข้อผิดพลาดในการบันทึกข้อมูล');
      }
    } catch (e) {
      print('Error saving winner info: $e');
      rethrow;
    }
  }

  // Save winner information to SharedPreferences
  Future<void> _saveWinnerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('winner_firstname', _controllers['firstname']!.text);
    await prefs.setString('winner_lastname', _controllers['lastname']!.text);
    await prefs.setString('winner_phone', _controllers['phone']!.text.replaceAll(RegExp(r'[^0-9]'), ''));
    await prefs.setString('winner_address', _controllers['address']!.text);
    await prefs.setString('winner_tax_number', _controllers['taxNumber']!.text);
    await prefs.setString('winner_email', _controllers['email']!.text);
    await prefs.setString('winner_province_id', _controllers['provinceId']!.text);
    await prefs.setString('winner_district_id', _controllers['districtId']!.text);
    await prefs.setString('winner_sub_district_id', _controllers['subDistrictId']!.text);
    await prefs.setString('winner_sub', _controllers['sub']!.text);
    await prefs.setString('winner_zip_code', _controllers['zipCode']!.text);
  }

  // Check if winner information exists
  Future<bool> _hasWinnerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final firstname = prefs.getString('winner_firstname') ?? '';
    final lastname = prefs.getString('winner_lastname') ?? '';
    final phone = prefs.getString('winner_phone') ?? '';
    final address = prefs.getString('winner_address') ?? '';
    final provinceId = prefs.getString('winner_province_id') ?? '';
    final districtId = prefs.getString('winner_district_id') ?? '';
    final subDistrictId = prefs.getString('winner_sub_district_id') ?? '';

    return firstname.isNotEmpty &&
           lastname.isNotEmpty &&
           phone.isNotEmpty &&
           address.isNotEmpty &&
           provinceId.isNotEmpty &&
           districtId.isNotEmpty &&
           subDistrictId.isNotEmpty;
  }

  // Get winner information summary
  Future<Map<String, String>> _getWinnerInfoSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': '${prefs.getString('winner_firstname') ?? ''} ${prefs.getString('winner_lastname') ?? ''}'.trim(),
      'phone': prefs.getString('winner_phone') ?? '',
      'address': prefs.getString('winner_address') ?? '',
      'taxNumber': prefs.getString('winner_tax_number') ?? '',
      'email': prefs.getString('winner_email') ?? '',
      'provinceId': prefs.getString('winner_province_id') ?? '',
      'districtId': prefs.getString('winner_district_id') ?? '',
      'subDistrictId': prefs.getString('winner_sub_district_id') ?? '',
      'zipCode': prefs.getString('winner_zip_code') ?? '',
    };
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'winning':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'outbid':
        return Colors.orange;
      case 'won':
        return Colors.green;
      case 'lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'winning':
        return 'กำลังชนะ';
      case 'active':
        return 'กำลังประมูล';
      case 'outbid':
        return 'ถูกแซง';
      case 'won':
        return 'ชนะการประมูล';
      case 'lost':
        return 'ไม่ชนะการประมูล';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  bool _validateForm() {
    if (_controllers['firstname']!.text.trim().isEmpty) {
      _showValidationError('กรุณากรอกชื่อ');
      return false;
    }
    if (_controllers['lastname']!.text.trim().isEmpty) {
      _showValidationError('กรุณากรอกนามสกุล');
      return false;
    }
    if (_controllers['phone']!.text.trim().isEmpty) {
      _showValidationError('กรุณากรอกเบอร์โทรศัพท์');
      return false;
    }
    if (_controllers['address']!.text.trim().isEmpty) {
      _showValidationError('กรุณากรอกที่อยู่');
      return false;
    }
    if (_controllers['provinceId']!.text.trim().isEmpty) {
      _showValidationError('กรุณาเลือกจังหวัด');
      return false;
    }
    if (_controllers['districtId']!.text.trim().isEmpty) {
      _showValidationError('กรุณาเลือกอำเภอ/เขต');
      return false;
    }
    if (_controllers['subDistrictId']!.text.trim().isEmpty) {
      _showValidationError('กรุณาเลือกตำบล/แขวง');
      return false;
    }
    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'รายการประมูลของฉัน',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black, size: 20),
            onPressed: () {
              setState(() {
                // Refresh data
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Modern Tab Bar
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(
                color: Colors.grey[500],
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'กำลังประมูล\n${_activeBids.length}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'ชนะ\n${_wonAuctions.length}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'ไม่ชนะ\n${_lostAuctions.length}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active Bids Tab
                _activeBids.isEmpty
                    ? buildEmptyState(
                        icon: Icons.gavel,
                        title: 'ไม่มีรายการที่กำลังประมูล',
                        subtitle: 'คุณยังไม่ได้เข้าร่วมการประมูลใดๆ',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _activeBids.length,
                        itemBuilder: (context, index) {
                          return ActiveBidCard(
                            auction: _activeBids[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AuctionDetailViewPage(auctionData: _activeBids[index]),
                                ),
                              );
                            },
                            getStatusColor: _getStatusColor,
                            getStatusText: _getStatusText,
                            small: true,
                          );
                        },
                      ),
                
                // Won Auctions Tab
                _wonAuctions.isEmpty
                    ? buildEmptyState(
                        icon: Icons.emoji_events,
                        title: 'ยังไม่มีรายการที่ชนะ',
                        subtitle: 'เข้าร่วมการประมูลเพื่อมีโอกาสชนะ',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _wonAuctions.length,
                        itemBuilder: (context, index) {
                          return buildWonAuctionCard(context, _wonAuctions[index], _hasWinnerInfo, _loadProfileAndShowDialog);
                        },
                      ),
                
                // Lost Auctions Tab
                _lostAuctions.isEmpty
                    ? buildEmptyState(
                        icon: Icons.sentiment_dissatisfied,
                        title: 'ยังไม่มีรายการที่แพ้',
                        subtitle: 'นี่เป็นสัญญาณที่ดี!',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _lostAuctions.length,
                        itemBuilder: (context, index) {
                          return LostAuctionCard(
                            auction: _lostAuctions[index],
                            small: true,
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadProfileAndShowDialog(Map<String, dynamic> auction) async {
    try {
      // ดึง customer ID จาก SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getString('id') ?? '';
      
      if (customerId.isEmpty) {
        _showValidationError('ไม่พบข้อมูล ID ผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
        return;
      }

      // แสดง loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('กำลังดึงข้อมูลโปรไฟล์...'),
              ],
            ),
          );
        },
      );

      // ดึงข้อมูลโปรไฟล์จาก API
      final profile = await _authService.getProfile(customerId);
      
      // ปิด loading dialog
      Navigator.of(context).pop();

      if (profile != null) {
        // ตรวจสอบข้อมูลที่ขาดหายไป
        final missingFields = _checkMissingFields(profile);
        
        if (missingFields.isEmpty) {
          // ข้อมูลครบแล้ว แสดงข้อมูลสรุป
          _showProfileSummaryDialog(auction, profile);
        } else {
          // มีข้อมูลขาดหายไป แสดงฟอร์มให้กรอกข้อมูลที่ขาด
          _showMissingFieldsDialog(auction, profile, missingFields);
        }
      } else {
        _showValidationError('ไม่สามารถดึงข้อมูลโปรไฟล์ได้');
      }
    } catch (e) {
      // ปิด loading dialog ถ้ายังเปิดอยู่
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      _showValidationError('เกิดข้อผิดพลาด: ${e.toString()}');
    }
  }

  // ตรวจสอบข้อมูลที่ขาดหายไป
  List<String> _checkMissingFields(Map<String, dynamic> profile) {
    final missingFields = <String>[];
    
    // ตรวจสอบข้อมูลที่จำเป็น
    if (profile['fullname']?.isEmpty == true || profile['fullname'] == null) {
      missingFields.add('fullname');
    }
    if (profile['phone']?.isEmpty == true || profile['phone'] == null) {
      missingFields.add('phone');
    }
    if (profile['address']?.isEmpty == true || profile['address'] == null) {
      missingFields.add('address');
    }
    if (profile['province_id']?.isEmpty == true || profile['province_id'] == null) {
      missingFields.add('province_id');
    }
    if (profile['district_id']?.isEmpty == true || profile['district_id'] == null) {
      missingFields.add('district_id');
    }
    if (profile['sub_district_id']?.isEmpty == true || profile['sub_district_id'] == null) {
      missingFields.add('sub_district_id');
    }
    
    return missingFields;
  }

  // เติมข้อมูลจาก profile ลงใน controllers
  void _fillControllersWithProfile(Map<String, dynamic> profile) {
    // แยกชื่อและนามสกุลจาก fullname
    final fullname = profile['fullname'] ?? '';
    final nameParts = fullname.split(' ');
    final firstname = nameParts.isNotEmpty ? nameParts.first : '';
    final lastname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    _controllers['firstname']!.text = firstname;
    _controllers['lastname']!.text = lastname;
    _controllers['phone']!.text = profile['phone'] ?? '';
    _controllers['address']!.text = profile['address'] ?? '';
    _controllers['taxNumber']!.text = profile['tax_number'] ?? '';
    _controllers['email']!.text = profile['email'] ?? '';
    _controllers['provinceId']!.text = profile['province_id'] ?? '';
    _controllers['districtId']!.text = profile['district_id'] ?? '';
    _controllers['subDistrictId']!.text = profile['sub_district_id'] ?? '';
    _controllers['sub']!.text = profile['sub'] ?? '';
    // zip code จะถูกเติมอัตโนมัติเมื่อเลือก sub-district
  }

  // แปลงชื่อ field เป็นชื่อที่แสดง
  String _getFieldDisplayName(String field) {
    switch (field) {
      case 'fullname':
        return 'ชื่อ-นามสกุล';
      case 'phone':
        return 'เบอร์โทรศัพท์';
      case 'address':
        return 'ที่อยู่';
      case 'tax_number':
        return 'เลขบัตรประชาชน';
      case 'province_id':
        return 'จังหวัด';
      case 'district_id':
        return 'อำเภอ/เขต';
      case 'sub_district_id':
        return 'ตำบล/แขวง';
      default:
        return field;
    }
  }

  // เพิ่มฟังก์ชันค้นหา zip code จาก addressData
  String? findZipCode(String? provinceId, String? districtId, String? subDistrictId, List<Map<String, dynamic>> addressData) {
    final province = addressData.firstWhere(
      (p) => p['id'].toString() == provinceId,
      orElse: () => {},
    );
    if (province.isEmpty) return null;
    final district = (province['districts'] as List).firstWhere(
      (d) => d['id'].toString() == districtId,
      orElse: () => {},
    );
    if (district.isEmpty) return null;
    final subDistrict = (district['sub_districts'] as List).firstWhere(
      (s) => s['id'].toString() == subDistrictId,
      orElse: () => {},
    );
    if (subDistrict.isEmpty) return null;
    return subDistrict['zip_code']?.toString();
  }

  // แสดง dialog สรุปข้อมูลโปรไฟล์
  void _showProfileSummaryDialog(Map<String, dynamic> auction, Map<String, dynamic> profile) {
    final zip = findZipCode(
      profile['province_id'],
      profile['district_id'],
      profile['sub_district_id'],
      addressData,
    ) ?? '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text('ข้อมูลผู้ชนะการประมูล'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Winner notification
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.celebration, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ยินดีด้วย! คุณชนะการประมูล ${auction['title']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Auction info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoRowWidget(
                        label: 'เลขที่ประมูล',
                        value: auction['auctionId'],
                        isMonospace: true,
                      ),
                      InfoRowWidget(
                        label: 'ราคาที่ชนะ',
                        value: Format.formatCurrency(auction['finalPrice']),
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Profile info summary (ปรับตามที่ต้องการ)
                Text(
                  'ข้อมูลสำหรับการจัดส่ง:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InfoRowWidget(
                        label: 'ชื่อ-สกุล',
                        value: profile['fullname'] ?? '',
                      ),
                      InfoRowWidget(
                        label: 'เบอร์โทร',
                        value: _formatPhoneWithZero(profile['phone']),
                      ),
                      if (profile['email']?.isNotEmpty == true)
                        InfoRowWidget(
                          label: 'อีเมลล์',
                          value: profile['email'] ?? '',
                        ),
                      // InfoRowWidget(
                      //   label: 'เลขบัตรประชาชน',
                      //   value: profile['tax_number'] ?? '',
                      //   isMonospace: true,
                      // ),
                      InfoRowWidget(
                        label: 'ที่อยู่เต็ม',
                        value: _formatFullAddressWithZip(profile, zip),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Text(
                    '✅ ข้อมูลครบถ้วนแล้ว พร้อมสำหรับการจัดส่ง',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ปิด'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // เติมข้อมูลใน controllers และแสดงฟอร์มแก้ไข
                _fillControllersWithProfile(profile);
                AuctionDialogs.showWinnerInfoDialog(
                  context,
                  auction,
                  _controllers,
                  _saveWinnerInfoToServer,
                  _validateForm,
                  _showValidationError,
                );
              },
              icon: const Icon(Icons.edit, size: 10),
              label: const Text('แก้ไขข้อมูล'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                // แสดง payment dialog
                AuctionDialogs.showPaymentDialog(context, auction);
              },
              icon: const Icon(Icons.payment, size: 10),
              label: const Text('ติดต่อชำระเงิน'),
            ),
          ],
        );
      },
    );
  }

  String _formatPhoneWithZero(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    return phone.startsWith('0') ? phone : '0$phone';
  }

  String _formatFullAddressWithZip(Map<String, dynamic> profile, String zip) {
    final address = profile['address'] ?? '';
    final sub = profile['sub'] ?? '';
    final subDistrict = profile['sub_district_name'] ?? '';
    final district = profile['district_name'] ?? '';
    final province = profile['province_name'] ?? '';
    String full = '$address $sub $subDistrict $district $province'.trim();
    if (zip.isNotEmpty) {
      full = '$full $zip';
    }
    return full;
  }

  void _showMissingFieldsDialog(Map<String, dynamic> auction, Map<String, dynamic> profile, List<String> missingFields) {
    // เติมข้อมูลที่มีอยู่แล้วใน controllers
    _fillControllersWithProfile(profile);
    
    // แสดง dialog แจ้งเตือนข้อมูลที่ขาด
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text('ข้อมูลไม่ครบถ้วน'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'กรุณากรอกข้อมูลที่ขาดหายไปเพื่อดำเนินการต่อ:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              ...missingFields.map((field) => Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text(_getFieldDisplayName(field)),
                  ],
                ),
              )).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // แสดงฟอร์มกรอกข้อมูลที่ขาด
                AuctionDialogs.showWinnerInfoDialog(
                  context,
                  auction,
                  _controllers,
                  _saveWinnerInfoToServer,
                  _validateForm,
                  _showValidationError,
                );
              },
              child: const Text('กรอกข้อมูล'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _isAppleTestAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id') ?? '';
    final phoneNumber = prefs.getString('phone') ?? '';
    
    return userId == 'APPLE_TEST_ID' || phoneNumber == '0001112345';
  }
} 