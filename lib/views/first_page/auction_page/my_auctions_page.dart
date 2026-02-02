import 'package:flutter/material.dart';
import 'package:e_auction/views/first_page/detail_page/detail_page.dart';
import 'package:e_auction/views/first_page/auction_page/auction_detail_view_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/services/auth_service/auth_service.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:e_auction/views/first_page/widgets/my_auctions_widget.dart'
    as dialogs;
import 'package:e_auction/views/first_page/widgets/my_auctions_widgets.dart'
    as widgets;
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/services/user_bid_history_service.dart';
import 'package:e_auction/services/winner_service.dart';
import 'package:e_auction/services/product_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:e_auction/views/first_page/auction_page/quantity_reduction_auction_detail_page.dart';
import 'package:e_auction/views/first_page/auction_page/quantity_reduction_auctions_page.dart';

class MyAuctionsPage extends StatefulWidget {
  const MyAuctionsPage({super.key});

  @override
  State<MyAuctionsPage> createState() => _MyAuctionsPageState();
}

class _MyAuctionsPageState extends State<MyAuctionsPage>
    with SingleTickerProviderStateMixin {
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
    // ข้อมูลที่อยู่ใหม่
    'village': TextEditingController(),
    'road': TextEditingController(),
    'postalCode': TextEditingController(),
    'country': TextEditingController(),
  };

  // User's auction history from API
  List<Map<String, dynamic>> _activeBids = [];
  bool _isLoadingActiveBids = true;

  // User's won auctions from API
  List<Map<String, dynamic>> _wonAuctions = [];
  bool _isLoadingWonAuctions = true;

  @override
  void initState() {
    super.initState();
    print('🔍 DEBUG: MyAuctionsPage initState called');
    
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _authService = AuthService(baseUrl: Config.apiUrlotpsever);
    
    // Debug: ตรวจสอบ user ID ใน SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      final userId = prefs.getString('id') ?? '';
      final name = prefs.getString('name') ?? '';
      final email = prefs.getString('email') ?? '';
      final phone = prefs.getString('phone') ?? '';
      
      print('🔍 DEBUG: SharedPreferences data:');
      print('🔍 DEBUG: - User ID: "$userId"');
      print('🔍 DEBUG: - Name: "$name"');
      print('🔍 DEBUG: - Email: "$email"');
      print('🔍 DEBUG: - Phone: "$phone"');
    });
    
    _loadAddressData();
    _loadUserBidHistory();
    _loadUserWonAuctions();

    // ปิดการ auto check และประกาศผู้ชนะอัตโนมัติ (เพราะสินค้ามีเยอะ)
    // _checkAndAnnounceAllEndedAuctions();
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

  // โหลดข้อมูลผู้ชนะของผู้ใช้จาก API
  Future<void> _loadUserWonAuctions() async {
    try {
      print('🔍 DEBUG: Starting _loadUserWonAuctions...');
      setState(() {
        _isLoadingWonAuctions = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id') ?? '';
      print('🔍 DEBUG: User ID for won auctions: "$userId"');

      if (userId.isEmpty) {
        print('❌ DEBUG: User ID is empty for won auctions, returning early');
        setState(() {
          _wonAuctions = [];
          _isLoadingWonAuctions = false;
        });
        return;
      }

      print('🔍 DEBUG: Calling WinnerService.getWinnersByUserId with userId: $userId');
      // ดึงข้อมูลผู้ชนะตาม user_id
      final result = await WinnerService.getWinnersByUserId(userId);
      print('🔍 DEBUG: WinnerService result: $result');

      if (result['status'] == 'success' && result['data'] != null) {
        final winners = result['data'] as List;
        print('🔍 DEBUG: Winners data length: ${winners.length}');
        print('🔍 DEBUG: Winners data: $winners');

        if (winners.isNotEmpty) {
          // แปลงข้อมูลเป็นรูปแบบที่ใช้ในแอป
          final convertedWinners =
              WinnerService.convertWinnersToAppFormat(winners);
          print('🔍 DEBUG: Converted winners length: ${convertedWinners.length}');
          print('🔍 DEBUG: Converted winners: $convertedWinners');

          setState(() {
            _wonAuctions = convertedWinners;
            _isLoadingWonAuctions = false;
          });
        } else {
          print('❌ DEBUG: Winners data is empty');
          setState(() {
            _wonAuctions = [];
            _isLoadingWonAuctions = false;
          });
        }
      } else {
        print('❌ DEBUG: WinnerService result status is not success or data is null');
        print('🔍 DEBUG: Result status: ${result['status']}');
        print('🔍 DEBUG: Result data: ${result['data']}');
        setState(() {
          _wonAuctions = [];
          _isLoadingWonAuctions = false;
        });
      }
    } catch (e) {
      print('❌ DEBUG: Error in _loadUserWonAuctions: $e');
      setState(() {
        _wonAuctions = [];
        _isLoadingWonAuctions = false;
      });
    }
  }

  // โหลดประวัติการประมูลของผู้ใช้จาก API
  Future<void> _loadUserBidHistory() async {
    try {
      print('🔍 DEBUG: Starting _loadUserBidHistory...');
      setState(() {
        _isLoadingActiveBids = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id') ?? '';
      print('🔍 DEBUG: User ID from SharedPreferences: "$userId"');

      if (userId.isEmpty) {
        print('❌ DEBUG: User ID is empty, returning early');
        setState(() {
          _activeBids = [];
          _isLoadingActiveBids = false;
        });
        return;
      }

      print('🔍 DEBUG: Calling UserBidHistoryService.getUserBidHistory with userId: $userId');
      // ดึงประวัติการประมูลจาก API
      final result = await UserBidHistoryService.getUserBidHistory(userId);
      print('🔍 DEBUG: API result: $result');

      if (result['status'] == 'success' && result['data'] != null) {
        final bidHistory = result['data']['bid_history'] as List;
        print('🔍 DEBUG: Bid history length: ${bidHistory.length}');
        print('🔍 DEBUG: Bid history data: $bidHistory');

        if (bidHistory.isNotEmpty) {
          // แปลงข้อมูลเป็นรูปแบบที่ใช้ในแอป
          final convertedBids =
              UserBidHistoryService.convertBidHistoryToAppFormat(bidHistory);
          print('🔍 DEBUG: Converted bids length: ${convertedBids.length}');
          print('🔍 DEBUG: Converted bids: $convertedBids');

          // จัดกลุ่มตาม quotation และหา bid สูงสุด
          final highestBids =
              UserBidHistoryService.getHighestBidsByQuotation(convertedBids);
          print('🔍 DEBUG: Highest bids count: ${highestBids.length}');
          print('🔍 DEBUG: Highest bids: $highestBids');

          // แปลงเป็น List
          final uniqueBids = highestBids.values.toList();
          print('🔍 DEBUG: Unique bids length: ${uniqueBids.length}');
          print('🔍 DEBUG: Unique bids: $uniqueBids');

          setState(() {
            _activeBids = uniqueBids;
            _isLoadingActiveBids = false;
          });

          // ปิดการ auto check และประกาศผู้ชนะอัตโนมัติ (เพราะสินค้ามีเยอะ)
          // await _checkAndAnnounceWinners(uniqueBids, userId);
        } else {
          print('❌ DEBUG: Bid history is empty');
          setState(() {
            _activeBids = [];
            _isLoadingActiveBids = false;
          });
        }
      } else {
        print('❌ DEBUG: API result status is not success or data is null');
        print('🔍 DEBUG: Result status: ${result['status']}');
        print('🔍 DEBUG: Result data: ${result['data']}');
        setState(() {
          _activeBids = [];
          _isLoadingActiveBids = false;
        });
      }
    } catch (e) {
      print('❌ DEBUG: Error in _loadUserBidHistory: $e');
      setState(() {
        _activeBids = [];
        _isLoadingActiveBids = false;
      });
    }
  }

  // เช็คและประกาศผู้ชนะสำหรับ auction ที่หมดเวลาแล้ว
  Future<void> _checkAndAnnounceWinners(
      List<Map<String, dynamic>> auctions, String userId) async {
    try {
      for (final auction in auctions) {
        final endDate = auction['auction_end_date'];
        final endTime = auction['auction_end_time'];
        final auctionId = auction['id'];
        final title = auction['title'];

        // เช็คว่า auction หมดเวลาหรือยัง
        bool isEnded = false;
        if (endDate != null && endDate.isNotEmpty) {
          isEnded = isAuctionEnded(endDate, endTime);
        } else {
          // ถ้าไม่มี end date ในข้อมูล ให้ใช้ API เช็คแทน
          isEnded = true; // ให้ API เป็นตัวตัดสินใจ
        }

        if (isEnded) {
          // เช็คว่าการประมูลนี้ถูกประกาศผู้ชนะแล้วหรือยัง
          try {
            final isAlreadyAnnounced =
                await WinnerService.isWinnerAnnounced(auctionId);

            if (!isAlreadyAnnounced) {
              // เรียกใช้ trigger ประกาศผู้ชนะโดยตรง - ส่งแค่ user_id อย่างเดียว
              print('📢 MY_AUCTIONS: Attempting to announce winner for auction $auctionId');
              final result =
                  await WinnerService.triggerAnnounceWinner(auctionId, userId);

              // ถ้าประกาศสำเร็จ ให้ refresh ข้อมูล
              if (result['status'] == 'success') {
                print('✅ MY_AUCTIONS: Winner announced successfully for auction $auctionId');
                // รีเฟรชข้อมูลหลังจากประกาศผู้ชนะสำเร็จ
                await _loadUserWonAuctions();
              } else {
                final errorMsg = result['message'] ?? result['error'] ?? 'Unknown error';
                print('⚠️ MY_AUCTIONS: Failed to announce winner for auction $auctionId: $errorMsg');
                // ไม่ throw error เพราะอาจเป็นเพราะประกาศไปแล้ว
              }
            } else {
              print('ℹ️ MY_AUCTIONS: Winner already announced for auction $auctionId');
            }
          } catch (e) {
            // ถ้าเช็คไม่ได้ ให้ลองประกาศเลย
            print('⚠️ MY_AUCTIONS: Error checking winner status for auction $auctionId: $e');
            print('📢 MY_AUCTIONS: Attempting to announce winner anyway...');

            try {
              final result =
                  await WinnerService.triggerAnnounceWinner(auctionId, userId);

              if (result['status'] == 'success') {
                print('✅ MY_AUCTIONS: Winner announced successfully (fallback) for auction $auctionId');
                await _loadUserWonAuctions();
              } else {
                final errorMsg = result['message'] ?? result['error'] ?? 'Unknown error';
                print('⚠️ MY_AUCTIONS: Failed to announce winner (fallback) for auction $auctionId: $errorMsg');
              }
            } catch (fallbackError) {
              print('❌ MY_AUCTIONS: Error in fallback announcement for auction $auctionId: $fallbackError');
              // ไม่ throw error ออกไป
            }
          }
        } else {}
      }
    } catch (e) {
      // ไม่แสดง error ให้ user เห็น เพราะเป็น background process
    }
  }

  // ฟังก์ชันใหม่: เช็คและประกาศผู้ชนะสำหรับ auction ทั้งหมดที่หมดเวลาแล้ว
  Future<void> _checkAndAnnounceAllEndedAuctions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id') ?? '';
      
      if (userId.isEmpty) {
        print('⚠️ AUTO: User ID is empty, skipping auto winner announcement');
        return;
      }

      print('🚀 AUTO: Starting auto winner announcement check for all ended auctions...');
      
      // เรียกใช้ฟังก์ชันเช็คและประกาศผู้ชนะสำหรับ auction ทั้งหมดที่หมดเวลาแล้ว
      // เรียกใช้ใน background เพื่อไม่ให้บล็อก UI
      // ใช้ delay เพื่อไม่ให้ทำงานทันทีเมื่อเข้ามาหน้านี้ (ให้โหลดข้อมูลก่อน)
      Future.delayed(Duration(seconds: 2), () {
        WinnerService.checkAndAnnounceAllEndedAuctions(userId).then((_) {
          print('✅ AUTO: Auto winner announcement check completed');
          // รีเฟรชข้อมูลหลังจากเช็คเสร็จ (delay อีกนิดเพื่อให้ API ทำงานเสร็จ)
          Future.delayed(Duration(seconds: 1), () {
            _loadUserWonAuctions();
            _loadUserBidHistory();
          });
        }).catchError((e) {
          print('❌ AUTO: Error in auto winner announcement: $e');
        });
      });
    } catch (e) {
      print('❌ AUTO: Error setting up auto winner announcement: $e');
    }
  }

  // ฟังก์ชันใหม่: ประกาศผู้ชนะด้วยตนเอง (สำหรับทดสอบ)
  Future<void> _manualTriggerWinnerAnnouncement(
      String auctionId, String userId) async {
    try {
      final result =
          await WinnerService.triggerAnnounceWinner(auctionId, userId);

      if (result['status'] == 'success') {
        // รีเฟรชข้อมูล
        await _loadUserWonAuctions();
        await _loadUserBidHistory();
      } else {
        // ไม่ throw error เพราะอาจเป็นเพราะประกาศไปแล้ว
      }
    } catch (e) {
      // ไม่ throw error ออกไป เพราะอาจเป็นเพราะประกาศไปแล้ว
    }
  }

  // ฟังก์ชันใหม่: ประกาศผู้ชนะอัตโนมัติเมื่อเข้ามาหน้านี้
  // Future<void> _autoTriggerWinnerAnnouncement() async {
  //   try {
  //     print('🚀 AUTO: Auto winner announcement triggered when entering page...');

  //     final prefs = await SharedPreferences.getInstance();
  //     final userId = prefs.getString('id') ?? '';

  //     if (userId.isEmpty) {
  //       print('❌ AUTO: No user ID found, skipping auto announcement');
  //       return;
  //     }

  //     print('🚀 AUTO: Announcing winners for user: $userId');

  //     // ประกาศผู้ชนะสำหรับ auction ID 8 (ตามตัวอย่าง)
  //     // เปลี่ยนเป็น try-catch เพื่อไม่ให้ error หยุดการทำงาน
  //     try {
  //       await _manualTriggerWinnerAnnouncement('8', userId);
  //     } catch (e) {
  //       print('⚠️ AUTO: Failed to announce winner for auction 8: $e');
  //       // ไม่ throw error ออกไป เพราะอาจเป็นเพราะประกาศไปแล้ว
  //     }

  //     // สามารถเพิ่ม auction ID อื่นๆ ได้ที่นี่
  //     // await _manualTriggerWinnerAnnouncement('9', userId);
  //     // await _manualTriggerWinnerAnnouncement('10', userId);

  //   } catch (e) {
  //     print('❌ AUTO: Error in auto winner announcement: $e');
  //   }
  // }

  @override
  void dispose() {
    _tabController.dispose();
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // Helper functions that are still needed
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
      case 'unknown':
        return Colors.grey;
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
      case 'unknown':
        return 'ไม่ทราบสถานะ';
      default:
        return 'ไม่ทราบสถานะ';
    }
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

  // แสดง popup dialog สำหรับข้อมูลที่ซ้ำ
  void _showDuplicateFieldDialog(BuildContext rootContext, String fieldName,
      String fieldKey, Map<String, dynamic> auction) {
    final TextEditingController newValueController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: rootContext, // ใช้ context หลัก
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text('ข้อมูลซ้ำ'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$fieldName นี้ถูกใช้ไปแล้ว กรุณาใส่ $fieldName ใหม่:',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: newValueController,
                  decoration: InputDecoration(
                    labelText: fieldName,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'ใส่ $fieldName ใหม่',
                  ),
                  keyboardType: _getKeyboardType(fieldKey),
                ),
                SizedBox(height: 12),
                Text(
                  'หลังจากแก้ไข กรุณากดบันทึกในหน้าหลักอีกครั้ง',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newValue = newValueController.text.trim();
                  if (newValue.isNotEmpty) {
                    _controllers[fieldKey]?.text = newValue;
                    Navigator.of(context).pop(); // ปิด popup
                    final success = await _saveWinnerInfoToServer(auction);
                    if (success) {
                      Navigator.of(rootContext).pop(); // ปิด dialog หลัก
                      dialogs.AuctionDialogs.showPaymentDialog(
                          rootContext, auction);
                    }
                    // ถ้าไม่ success จะวน popup เดิมอีกครั้ง
                  } else {
                    _showValidationError('กรุณาใส่ $fieldName');
                  }
                },
                child: Text('บันทึก'),
              ),
            ],
          );
        },
      );
    });
  }

  // กำหนด keyboard type ตามประเภทข้อมูล
  TextInputType _getKeyboardType(String fieldKey) {
    switch (fieldKey) {
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      case 'taxNumber':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  // Check if winner information exists
  Future<bool> _hasWinnerInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstname = prefs.getString('winner_firstname') ?? '';
      final lastname = prefs.getString('winner_lastname') ?? '';
      final phone = prefs.getString('winner_phone') ?? '';
      final address = prefs.getString('winner_address') ?? '';
      final provinceId = prefs.getString('winner_province_id') ?? '';
      final districtId = prefs.getString('winner_district_id') ?? '';
      final subDistrictId = prefs.getString('winner_sub_district_id') ?? '';

      // ตรวจสอบข้อมูลที่จำเป็น
      final hasRequiredInfo = firstname.isNotEmpty &&
          lastname.isNotEmpty &&
          phone.isNotEmpty &&
          address.isNotEmpty &&
          provinceId.isNotEmpty &&
          districtId.isNotEmpty &&
          subDistrictId.isNotEmpty;

      // ตรวจสอบข้อมูลที่อยู่ใหม่ (ไม่บังคับ แต่แนะนำ)
      final hasOptionalAddressInfo =
          prefs.getString('winner_village')?.isNotEmpty == true ||
              prefs.getString('winner_road')?.isNotEmpty == true ||
              prefs.getString('winner_postal_code')?.isNotEmpty == true;

      return hasRequiredInfo;
    } catch (e) {
      return false;
    }
  }

  // Save winner information using WinnerService
  Future<bool> _saveWinnerInfoToServer([Map<String, dynamic>? auction]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id') ?? '';

      if (userId.isEmpty) {
        throw Exception('ไม่พบข้อมูล ID ผู้ใช้');
      }

      // สร้างข้อมูลผู้ชนะจาก form controllers
      final winnerInfo = WinnerService.createWinnerInfo(
        customerId: userId,
        fullname:
            '${_controllers['firstname']!.text} ${_controllers['lastname']!.text}'
                .trim(),
        email: _controllers['email']!.text,
        phone: _controllers['phone']!.text,
        addr: _controllers['address']!.text,
        provinceId: _controllers['provinceId']!.text,
        districtId: _controllers['districtId']!.text,
        subDistrictId: _controllers['subDistrictId']!.text,
        sub: _controllers['sub']!.text,
        taxNumber: _controllers['taxNumber']!.text,
        // ข้อมูลที่อยู่ใหม่
        village: _controllers['village']!.text,
        road: _controllers['road']!.text,
        postalCode: _controllers['zipCode']!
            .text, // ใช้ zipCode controller สำหรับ postalCode
        country: _controllers['country']!.text.isNotEmpty
            ? _controllers['country']!.text
            : 'Thailand',
      );

      // บันทึกข้อมูลผู้ชนะ
      final result = await WinnerService.saveWinnerInfo(winnerInfo);

      if (result['success'] == true) {
        // บันทึกข้อมูลลง SharedPreferences ด้วย prefix winner_ เพื่อให้ validateWinnerInfo ใช้งานได้
        await prefs.setString(
            'winner_firstname', _controllers['firstname']!.text);
        await prefs.setString(
            'winner_lastname', _controllers['lastname']!.text);
        await prefs.setString('winner_phone', _controllers['phone']!.text);
        await prefs.setString('winner_address', _controllers['address']!.text);
        await prefs.setString(
            'winner_tax_number', _controllers['taxNumber']!.text);
        await prefs.setString('winner_email', _controllers['email']!.text);
        await prefs.setString(
            'winner_province_id', _controllers['provinceId']!.text);
        await prefs.setString(
            'winner_district_id', _controllers['districtId']!.text);
        await prefs.setString(
            'winner_sub_district_id', _controllers['subDistrictId']!.text);
        await prefs.setString('winner_sub', _controllers['sub']!.text);
        await prefs.setString('winner_zip_code', _controllers['zipCode']!.text);
        // บันทึกข้อมูลที่อยู่ใหม่
        await prefs.setString('winner_village', _controllers['village']!.text);
        await prefs.setString('winner_road', _controllers['road']!.text);
        await prefs.setString(
            'winner_postal_code', _controllers['zipCode']!.text);
        await prefs.setString(
            'winner_country',
            _controllers['country']!.text.isNotEmpty
                ? _controllers['country']!.text
                : 'Thailand');
        return true; // บันทึกสำเร็จ
      } else {
        // ตรวจสอบข้อความ error จาก API และแสดง popup dialog แจ้งเตือน
        final message = result['message']?.toString() ?? '';

        if (message.toLowerCase().contains('email already exists') ||
            (message.toLowerCase().contains('อีเมล') &&
                message.toLowerCase().contains('ซ้ำ'))) {
          if (auction != null) {
            _showDuplicateFieldDialog(context, 'อีเมล', 'email', auction);
          } else {
            _showValidationError('อีเมลนี้ถูกใช้ไปแล้ว กรุณาใช้อีเมลอื่น');
          }
          return false;
        } else if (message.toLowerCase().contains('phone already exists') ||
            (message.toLowerCase().contains('เบอร์โทร') &&
                message.toLowerCase().contains('ซ้ำ'))) {
          if (auction != null) {
            _showDuplicateFieldDialog(
                context, 'เบอร์โทรศัพท์', 'phone', auction);
          } else {
            _showValidationError(
                'เบอร์โทรศัพท์นี้ถูกใช้ไปแล้ว กรุณาใช้เบอร์อื่น');
          }
          return false;
        } else if (message
                .toLowerCase()
                .contains('tax number already exists') ||
            (message.toLowerCase().contains('เลขบัตรประชาชน') &&
                message.toLowerCase().contains('ซ้ำ'))) {
          if (auction != null) {
            _showDuplicateFieldDialog(
                context, 'เลขบัตรประชาชน', 'taxNumber', auction);
          } else {
            _showValidationError(
                'เลขบัตรประชาชนนี้ถูกใช้ไปแล้ว กรุณาใช้เลขบัตรอื่น');
          }
          return false;
        } else {
          _showValidationError('บันทึกข้อมูลไม่สำเร็จ: $message');
          return false;
        }
      }
    } catch (e) {
      // แสดง error ที่เกิดจาก network หรือ error อื่นๆ
      _showValidationError('เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}');
      return false; // บันทึกไม่สำเร็จ
    }
  }

  bool _validateForm() {
    // Since we only need user_id, always return true
    return true;
  }

  // Utility: Check if auction has ended (ปรับปรุงให้ถูกต้อง)
  bool isAuctionEnded(String? endDate, [String? endTime]) {
    try {
      String? dateToCheck = endDate;
      if ((dateToCheck == null || dateToCheck.isEmpty) &&
          endTime != null &&
          endTime.isNotEmpty) {
        dateToCheck = endTime;
      }
      if (dateToCheck == null || dateToCheck.isEmpty) return false;

      String dateTimeString = dateToCheck;
      if (endTime != null && endTime.isNotEmpty && !dateToCheck.contains(' ')) {
        dateTimeString = '$dateToCheck $endTime';
      }

      final end = DateTime.parse(dateTimeString);
      final now = DateTime.now();

      return now.isAfter(end);
    } catch (e) {
      return false;
    }
  }

  // เพิ่มฟังก์ชันคำนวณอันดับ
  int getUserBidRank(List<dynamic> bidHistory, String userId) {
    final sorted = List<Map<String, dynamic>>.from(bidHistory)
      ..sort(
          (a, b) => (b['bid_amount'] as num).compareTo(a['bid_amount'] as num));
    final idx =
        sorted.indexWhere((bid) => bid['bidder_id'].toString() == userId);
    return idx >= 0 ? idx + 1 : -1;
  }

  @override
  Widget build(BuildContext context) {
    // Filter lists for each tab using 'auction_end_date' or fallback to 'auction_end_time'
    final List<Map<String, dynamic>> filteredActiveBids =
        _activeBids.where((auction) {
      final endDate = auction['auction_end_date'];
      final endTime = auction['auction_end_time'];
      return !isAuctionEnded(endDate, endTime);
    }).toList();
    // For won tab, use only _wonAuctions from WinnerService
    final List<Map<String, dynamic>> filteredWonAuctions =
        _wonAuctions.where((auction) {
      final endDate = auction['auction_end_date'];
      final endTime = auction['auction_end_time'];
      return isAuctionEnded(endDate, endTime);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'รายการประมูลของฉัน',
          style: TextStyle(
            color: Colors.black,
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
          // ปุ่มรีเฟรช
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black, size: 20),
            onPressed: () {
              _loadUserBidHistory();
              _loadUserWonAuctions();
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
                      'กำลังประมูล\n${filteredActiveBids.length}',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'ชนะ\n${filteredWonAuctions.length}',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                _isLoadingActiveBids
                    ? Center(child: CircularProgressIndicator())
                    : filteredActiveBids.isEmpty
                        ? widgets.buildEmptyState(
                            icon: Icons.gavel,
                            title: 'ไม่มีรายการที่กำลังประมูล',
                            subtitle: 'คุณยังไม่ได้เข้าร่วมการประมูลใดๆ',
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            itemCount: filteredActiveBids.length,
                            itemBuilder: (context, index) {
                              final auction = Map<String, dynamic>.from(
                                  filteredActiveBids[index]);
                              final prefs = SharedPreferences.getInstance();
                              return FutureBuilder<SharedPreferences>(
                                future: prefs,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    auction['myBidRank'] = '-';
                                    return widgets.ActiveBidCard(
                                      auction: auction,
                                      onTap: () async {
                                        // ตรวจสอบ type ของ auction
                                        final typeCode =
                                            auction['quotation_type_code'] ??
                                                auction['type_code'];
                                        final quantityRequested =
                                            auction['quantity_requested'] ?? 0;
                                        final totalAmount =
                                            auction['total_amount'] ?? 0;
                                        final quotationId = auction[
                                                'quotation_more_information_id']
                                            ?.toString();
                                        final auctionType =
                                            auction['quotation_type_code'] ??
                                                '';
                                        final quantityDiscountEnabled = auction[
                                                'quantity_discount_enabled'] ??
                                            '';

                                        // เช็คว่าเป็น AS03 หรือไม่ (ใช้ข้อมูลจาก API)
                                        final isAS03 = typeCode == 'AS03' ||
                                            auctionType ==
                                                'quantity_discount' ||
                                            (quantityDiscountEnabled == 't' &&
                                                quantityRequested > 0);

                                        if (isAS03) {
                                          // สำหรับ AS03 ไปหน้า quantity reduction
                                          final productService = ProductService(
                                              baseUrl: Config.apiUrlAuction);
                                          final quotationId = auction[
                                                  'quotation_more_information_id'] ??
                                              auction['id'];

                                          // ดึงข้อมูลล่าสุดจาก API
                                          final allQuotations =
                                              await productService
                                                  .getAllQuotations();
                                          final matchingQuotation =
                                              allQuotations?.firstWhere(
                                            (q) =>
                                                q['quotation_more_information_id']
                                                    ?.toString() ==
                                                quotationId.toString(),
                                            orElse: () => <String, dynamic>{},
                                          );

                                          if (matchingQuotation != null &&
                                              matchingQuotation.isNotEmpty) {
                                            // ใช้ข้อมูลจาก getAllQuotations() และเพิ่ม type_code
                                            final formattedAuctionData =
                                                productService
                                                    .convertToAppFormat(
                                                        matchingQuotation);
                                            // เพิ่ม type_code เพื่อให้หน้า quantity reduction รู้ว่าเป็น AS03
                                            formattedAuctionData[
                                                'quotation_type_code'] = 'AS03';
                                            formattedAuctionData['type_code'] =
                                                'AS03';

                                            // นำทางไปยัง QuantityReductionAuctionsPage
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    QuantityReductionAuctionsPage(),
                                              ),
                                            );
                                          } else {
                                            // Fallback: ใช้ข้อมูลเดิมและเพิ่ม type_code
                                            final fallbackData =
                                                Map<String, dynamic>.from(
                                                    auction);
                                            fallbackData[
                                                'quotation_type_code'] = 'AS03';
                                            fallbackData['type_code'] = 'AS03';

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    QuantityReductionAuctionsPage(),
                                              ),
                                            );
                                          }
                                        } else {
                                          // สำหรับ auction ปกติ ใช้ logic เดิม
                                          final productService = ProductService(
                                              baseUrl: Config.apiUrlAuction);
                                          final quotationId = auction[
                                                  'quotation_more_information_id'] ??
                                              auction['id'];
                                          // ดึงข้อมูลล่าสุดจาก API (เหมือนหน้า home)
                                          final auctionData =
                                              await productService
                                                  .getAuctionProductById(
                                                      quotationId.toString());
                                          // แปลงข้อมูลให้อยู่ในรูปแบบเดียวกับหน้า home
                                          final formattedAuctionData =
                                              productService.convertToAppFormat(
                                                  auctionData ?? {});
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AuctionDetailViewPage(
                                                      auctionData:
                                                          formattedAuctionData),
                                            ),
                                          );
                                        }
                                      },
                                      getStatusColor: _getStatusColor,
                                      getStatusText: _getStatusText,
                                      small: true,
                                    );
                                  }
                                  final userId =
                                      snapshot.data!.getString('id') ?? '';
                                  return FutureBuilder<List<dynamic>>(
                                    future:
                                        UserBidHistoryService.getUserBidRanking(
                                            auction['id'].toString()),
                                    builder: (context, rankSnapshot) {
                                      if (rankSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        auction['myBidRank'] = '-';
                                      } else if (rankSnapshot.hasData) {
                                        final userRanks = rankSnapshot.data!
                                            .where((e) =>
                                                e['bidder_id'].toString() ==
                                                userId.toString())
                                            .toList();
                                        if (userRanks.isNotEmpty) {
                                          final latest = userRanks.first;
                                          auction['myBidRank'] =
                                              latest['rank']?.toString() ?? '-';
                                        } else {
                                          auction['myBidRank'] = '-';
                                        }
                                      } else {
                                        auction['myBidRank'] = '-';
                                      }
                                      return widgets.ActiveBidCard(
                                        auction: auction,
                                        onTap: () async {
                                          // ตรวจสอบ type ของ auction
                                          final typeCode =
                                              auction['quotation_type_code'] ??
                                                  auction['type_code'];
                                          final quantityRequested =
                                              auction['quantity_requested'] ??
                                                  0;
                                          final totalAmount =
                                              auction['total_amount'] ?? 0;
                                          final quotationId = auction[
                                                  'quotation_more_information_id']
                                              ?.toString();
                                          final auctionType =
                                              auction['auction_type'] ?? '';
                                          final quantityDiscountEnabled = auction[
                                                  'quantity_discount_enabled'] ??
                                              '';

                                          // เช็คว่าเป็น AS03 หรือไม่ (ใช้ข้อมูลจาก API)
                                          final isAS03 = typeCode == 'AS03' ||
                                              auctionType ==
                                                  'quantity_discount' ||
                                              (quantityDiscountEnabled == 't' &&
                                                  quantityRequested > 0);

                                          if (isAS03) {
                                            // สำหรับ AS03 ไปหน้า quantity reduction
                                            final productService =
                                                ProductService(
                                                    baseUrl:
                                                        Config.apiUrlAuction);
                                            final quotationId = auction[
                                                    'quotation_more_information_id'] ??
                                                auction['id'];

                                            // ดึงข้อมูลจาก getAllQuotations() เหมือนหน้า home
                                            final allQuotations =
                                                await productService
                                                    .getAllQuotations();

                                            // หา quotation ที่ตรงกับ ID
                                            final matchingQuotation =
                                                allQuotations?.firstWhere(
                                              (q) =>
                                                  q['quotation_more_information_id']
                                                      ?.toString() ==
                                                  quotationId.toString(),
                                              orElse: () => <String, dynamic>{},
                                            );

                                            if (matchingQuotation != null &&
                                                matchingQuotation.isNotEmpty) {
                                              // ใช้ข้อมูลจาก getAllQuotations() และเพิ่ม type_code
                                              final formattedAuctionData =
                                                  productService
                                                      .convertToAppFormat(
                                                          matchingQuotation);
                                              // เพิ่ม type_code เพื่อให้หน้า quantity reduction รู้ว่าเป็น AS03
                                              formattedAuctionData[
                                                      'quotation_type_code'] =
                                                  'AS03';
                                              formattedAuctionData[
                                                  'type_code'] = 'AS03';

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      QuantityReductionAuctionsPage(),
                                                ),
                                              );
                                            } else {
                                              // Fallback: ใช้ข้อมูลเดิมและเพิ่ม type_code
                                              final fallbackData =
                                                  Map<String, dynamic>.from(
                                                      auction);
                                              fallbackData[
                                                      'quotation_type_code'] =
                                                  'AS03';
                                              fallbackData['type_code'] =
                                                  'AS03';

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      QuantityReductionAuctionsPage(),
                                                ),
                                              );
                                            }
                                          } else {
                                            // สำหรับ auction ปกติ ใช้ logic เดิม
                                            // ใช้ ProductService ในการจัดการรูปภาพ
                                            final productService =
                                                ProductService(
                                                    baseUrl:
                                                        Config.apiUrlAuction);

                                            // ดึงข้อมูลจาก getAllQuotations() เหมือนหน้า home
                                            final allQuotations =
                                                await productService
                                                    .getAllQuotations();
                                            final quotationId = auction[
                                                    'quotation_more_information_id'] ??
                                                auction['id'];

                                            // หา quotation ที่ตรงกับ ID
                                            final matchingQuotation =
                                                allQuotations?.firstWhere(
                                              (q) =>
                                                  q['quotation_more_information_id']
                                                      ?.toString() ==
                                                  quotationId.toString(),
                                              orElse: () => <String, dynamic>{},
                                            );

                                            if (matchingQuotation != null &&
                                                matchingQuotation.isNotEmpty) {
                                              // ใช้ข้อมูลจาก getAllQuotations() เหมือนหน้า home
                                              final formattedAuctionData =
                                                  productService
                                                      .convertToAppFormat(
                                                          matchingQuotation);

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AuctionDetailViewPage(
                                                          auctionData:
                                                              formattedAuctionData),
                                                ),
                                              );
                                            } else {
                                              // Fallback: ใช้ข้อมูลเดิม
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AuctionDetailViewPage(
                                                          auctionData: auction),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        getStatusColor: _getStatusColor,
                                        getStatusText: _getStatusText,
                                        small: true,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                // Won Auctions Tab
                _isLoadingWonAuctions
                    ? Center(child: CircularProgressIndicator())
                    : filteredWonAuctions.isEmpty
                        ? widgets.buildEmptyState(
                            icon: Icons.emoji_events,
                            title: 'ยังไม่มีรายการที่ชนะ',
                            subtitle: 'เข้าร่วมการประมูลเพื่อมีโอกาสชนะ',
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            itemCount: filteredWonAuctions.length,
                            itemBuilder: (context, index) {
                              return widgets.buildWonAuctionCard(
                                  context,
                                  filteredWonAuctions[index],
                                  _hasWinnerInfo,
                                  _loadProfileAndShowDialog);
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
          await _showMissingFieldsDialog(auction, profile, missingFields);
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
    if (profile['province_id']?.isEmpty == true ||
        profile['province_id'] == null) {
      missingFields.add('province_id');
    }
    if (profile['district_id']?.isEmpty == true ||
        profile['district_id'] == null) {
      missingFields.add('district_id');
    }
    if (profile['sub_district_id']?.isEmpty == true ||
        profile['sub_district_id'] == null) {
      missingFields.add('sub_district_id');
    }

    // ตรวจสอบข้อมูลที่อยู่ใหม่ (ไม่บังคับ แต่แนะนำให้กรอก)
    // if (profile['village']?.isEmpty == true || profile['village'] == null) {
    //   missingFields.add('village');
    // }
    // if (profile['road']?.isEmpty == true || profile['road'] == null) {
    //   missingFields.add('road');
    // }
    // if (profile['postal_code']?.isEmpty == true || profile['postal_code'] == null) {
    //   missingFields.add('postal_code');
    // }

    return missingFields;
  }

  // เติมข้อมูลจาก profile ลงใน controllers
  Future<void> _fillControllersWithProfile(Map<String, dynamic> profile) async {
    // แยกชื่อและนามสกุลจาก fullname
    final fullname = profile['fullname'] ?? '';
    final nameParts = fullname.split(' ');
    final firstname = nameParts.isNotEmpty ? nameParts.first : '';
    final lastname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // ปรับเบอร์โทรให้ขึ้นต้นด้วย 0 ถ้าข้อมูลมี 9 หลักและไม่ขึ้นต้นด้วย 0
    final rawPhone = profile['phone'] ?? '';
    final phone = (rawPhone.length == 9 && !rawPhone.startsWith('0'))
        ? '0$rawPhone'
        : rawPhone;

    _controllers['firstname']!.text = firstname;
    _controllers['lastname']!.text = lastname;
    _controllers['phone']!.text = phone;
    _controllers['address']!.text = profile['address'] ?? '';
    _controllers['taxNumber']!.text = profile['tax_number'] ?? '';
    _controllers['email']!.text = profile['email'] ?? '';
    _controllers['provinceId']!.text = profile['province_id'] ?? '';
    _controllers['districtId']!.text = profile['district_id'] ?? '';
    _controllers['subDistrictId']!.text = profile['sub_district_id'] ?? '';
    _controllers['sub']!.text = profile['sub'] ?? '';
    // zip code จะถูกเติมอัตโนมัติเมื่อเลือก sub-district

    // เติมข้อมูลที่อยู่ใหม่
    _controllers['village']!.text = profile['village'] ?? '';
    _controllers['road']!.text = profile['road'] ?? '';
    _controllers['postalCode']!.text =
        profile['postal_code'] ?? profile['zip_code'] ?? '';
    _controllers['country']!.text = profile['country'] ?? 'Thailand';

    // บันทึกข้อมูลลง SharedPreferences ด้วย prefix winner_ เพื่อให้ validateWinnerInfo ใช้งานได้
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('winner_firstname', firstname);
      await prefs.setString('winner_lastname', lastname);
      await prefs.setString('winner_phone', phone);
      await prefs.setString('winner_address', profile['address'] ?? '');
      await prefs.setString('winner_tax_number', profile['tax_number'] ?? '');
      await prefs.setString('winner_email', profile['email'] ?? '');
      await prefs.setString('winner_province_id', profile['province_id'] ?? '');
      await prefs.setString('winner_district_id', profile['district_id'] ?? '');
      await prefs.setString(
          'winner_sub_district_id', profile['sub_district_id'] ?? '');
      await prefs.setString('winner_sub', profile['sub'] ?? '');
      await prefs.setString('winner_zip_code', profile['zip_code'] ?? '');
      // บันทึกข้อมูลที่อยู่ใหม่
      await prefs.setString('winner_village', profile['village'] ?? '');
      await prefs.setString('winner_road', profile['road'] ?? '');
      await prefs.setString('winner_postal_code',
          profile['postal_code'] ?? profile['zip_code'] ?? '');
      await prefs.setString('winner_country', profile['country'] ?? 'Thailand');
    } catch (e) {}
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
      case 'village':
        return 'หมู่';
      case 'road':
        return 'ถนน';
      case 'postal_code':
        return 'รหัสไปรษณีย์';
      case 'country':
        return 'ประเทศ';
      default:
        return field;
    }
  }

  // เพิ่มฟังก์ชันค้นหา zip code จาก addressData
  String? findZipCode(String? provinceId, String? districtId,
      String? subDistrictId, List<Map<String, dynamic>> addressData) {
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
  void _showProfileSummaryDialog(
      Map<String, dynamic> auction, Map<String, dynamic> profile) async {
    // เติมข้อมูลหมู่ ถนน รหัสไปรษณีย์ ประเทศ จาก SharedPreferences ถ้ายังไม่มีใน profile
    final prefs = await SharedPreferences.getInstance();
    profile['village'] =
        profile['village'] ?? prefs.getString('winner_village') ?? '';
    profile['road'] = profile['road'] ?? prefs.getString('winner_road') ?? '';
    profile['postal_code'] =
        profile['postal_code'] ?? prefs.getString('winner_postal_code') ?? '';
    profile['country'] =
        profile['country'] ?? prefs.getString('winner_country') ?? 'Thailand';

    final zip = findZipCode(
          profile['province_id'],
          profile['district_id'],
          profile['sub_district_id'],
          addressData,
        ) ??
        '';
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
                      dialogs.InfoRowWidget(
                        label: 'เลขที่ประมูล',
                        value: auction['auctionId'],
                        isMonospace: true,
                      ),
                      dialogs.InfoRowWidget(
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
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
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
                      dialogs.InfoRowWidget(
                        label: 'ชื่อ-สกุล',
                        value: profile['fullname'] ?? '',
                      ),
                      dialogs.InfoRowWidget(
                        label: 'เบอร์โทร',
                        value: _formatPhoneWithZero(profile['phone']),
                      ),
                      if (profile['email']?.isNotEmpty == true)
                        dialogs.InfoRowWidget(
                          label: 'อีเมลล์',
                          value: profile['email'] ?? '',
                        ),
                      dialogs.InfoRowWidget(
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      // โหลดข้อมูลล่าสุดจาก SharedPreferences ก่อนแสดงฟอร์ม
                      dialogs.AuctionDialogs.showWinnerInfoDialog(
                        context,
                        auction,
                        _controllers,
                        ([Map<String, dynamic>? _]) =>
                            _saveWinnerInfoToServer(auction),
                        _validateForm,
                        _showValidationError,
                      );
                    },
                    icon: Icon(Icons.edit, color: Colors.blue),
                    label: Text('แก้ไขข้อมูล',
                        style: TextStyle(color: Colors.blue)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      dialogs.AuctionDialogs.showPaymentDialog(
                          context, auction);
                    },
                    icon: Icon(Icons.payment, color: Colors.white),
                    label: Text('ติดต่อชำระเงิน',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ปิด'),
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
    final village = profile['village'] ?? '';
    final road = profile['road'] ?? '';
    final sub = profile['sub'] ?? '';
    final subDistrict = profile['sub_district_name'] ?? '';
    final district = profile['district_name'] ?? '';
    final province = profile['province_name'] ?? '';
    final country = profile['country'] ?? 'Thailand';

    // สร้างที่อยู่เต็มรูปแบบ พร้อมตัวย่อ
    final List<String> addressParts = [];
    if (address.isNotEmpty) addressParts.add(address);
    if (village.isNotEmpty) addressParts.add('หมู่ $village');
    if (road.isNotEmpty) addressParts.add('ถ.$road');
    if (sub.isNotEmpty) addressParts.add('ซอย $sub');
    if (subDistrict.isNotEmpty) addressParts.add('ต.$subDistrict');
    if (district.isNotEmpty) addressParts.add('อ.$district');
    if (province.isNotEmpty) addressParts.add('จ.$province');
    if (zip.isNotEmpty) addressParts.add(zip);
    if (country.isNotEmpty) addressParts.add(country);
    return addressParts.join(' ');
  }

  Future<void> _showMissingFieldsDialog(Map<String, dynamic> auction,
      Map<String, dynamic> profile, List<String> missingFields) async {
    // เติมข้อมูลที่มีอยู่แล้วใน controllers
    await _fillControllersWithProfile(profile);

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
              ...missingFields
                  .map((field) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text(_getFieldDisplayName(field)),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // โหลดข้อมูลล่าสุดจาก SharedPreferences ก่อนแสดงฟอร์ม
                dialogs.AuctionDialogs.showWinnerInfoDialog(
                  context,
                  auction,
                  _controllers,
                  ([Map<String, dynamic>? _]) =>
                      _saveWinnerInfoToServer(auction),
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
