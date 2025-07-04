import 'package:flutter/material.dart';
import 'package:e_auction/views/first_page/detail_page/detail_page.dart';
import 'package:e_auction/views/first_page/auction_page/auction_detail_view_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/services/auth_service/auth_service.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:e_auction/views/first_page/widgets/my_auctions_widget.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/services/user_bid_history_service.dart';
import 'package:e_auction/services/winner_service.dart';
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

  // User's auction history from API
  List<Map<String, dynamic>> _activeBids = [];
  bool _isLoadingActiveBids = true;

  // User's won auctions from API
  List<Map<String, dynamic>> _wonAuctions = [];
  bool _isLoadingWonAuctions = true;

 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _authService = AuthService(baseUrl: Config.apiUrlotpsever);
    _loadAddressData();
    _loadUserBidHistory();
    _loadUserWonAuctions();
    
    // ประกาศผู้ชนะอัตโนมัติเมื่อเข้ามาหน้านี้
    // _autoTriggerWinnerAnnouncement();
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
      setState(() {
        _isLoadingWonAuctions = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id') ?? '';
      
      if (userId.isEmpty) {
        setState(() {
          _wonAuctions = [];
          _isLoadingWonAuctions = false;
        });
        return;
      }
      
      // ดึงข้อมูลผู้ชนะตาม user_id
      print('🐞 DEBUG: เริ่มเรียก WinnerService.getWinnersByUserId($userId)');
      final result = await WinnerService.getWinnersByUserId(userId);
      print('🐞 DEBUG: WinnerService.getWinnersByUserId($userId) result = ' + result.toString());
      
      if (result['status'] == 'success' && result['data'] != null) {
        final winners = result['data'] as List;
        
        if (winners.isNotEmpty) {
          // แปลงข้อมูลเป็นรูปแบบที่ใช้ในแอป
          final convertedWinners = WinnerService.convertWinnersToAppFormat(winners);
          
          setState(() {
            _wonAuctions = convertedWinners;
            _isLoadingWonAuctions = false;
          });
        } else {
          setState(() {
            _wonAuctions = [];
            _isLoadingWonAuctions = false;
          });
        }
      } else {
        setState(() {
          _wonAuctions = [];
          _isLoadingWonAuctions = false;
        });
      }
    } catch (e) {
      setState(() {
        _wonAuctions = [];
        _isLoadingWonAuctions = false;
      });
    }
  }

  // โหลดประวัติการประมูลของผู้ใช้จาก API
  Future<void> _loadUserBidHistory() async {
    try {
      setState(() {
        _isLoadingActiveBids = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id') ?? '';
      
      if (userId.isEmpty) {
        setState(() {
          _activeBids = [];
          _isLoadingActiveBids = false;
        });
        return;
      }
      
      // ดึงประวัติการประมูลจาก API
      final result = await UserBidHistoryService.getUserBidHistory(userId);
      
      if (result['status'] == 'success' && result['data'] != null) {
        final bidHistory = result['data']['bid_history'] as List;
        
        if (bidHistory.isNotEmpty) {
          // แปลงข้อมูลเป็นรูปแบบที่ใช้ในแอป
          final convertedBids = UserBidHistoryService.convertBidHistoryToAppFormat(bidHistory);
          
          // จัดกลุ่มตาม quotation และหา bid สูงสุด
          final highestBids = UserBidHistoryService.getHighestBidsByQuotation(convertedBids);
          
          // แปลงเป็น List
          final uniqueBids = highestBids.values.toList();
          
          setState(() {
            _activeBids = uniqueBids;
            _isLoadingActiveBids = false;
          });

          // เช็คและประกาศผู้ชนะสำหรับ auction ที่หมดเวลาแล้ว
          await _checkAndAnnounceWinners(uniqueBids, userId);
        } else {
          setState(() {
            _activeBids = [];
            _isLoadingActiveBids = false;
          });
        }
      } else {
        setState(() {
          _activeBids = [];
          _isLoadingActiveBids = false;
        });
      }
    } catch (e) {
      setState(() {
        _activeBids = [];
        _isLoadingActiveBids = false;
      });
    }
  }

  // เช็คและประกาศผู้ชนะสำหรับ auction ที่หมดเวลาแล้ว
  Future<void> _checkAndAnnounceWinners(List<Map<String, dynamic>> auctions, String userId) async {
    try {
      print('📱 MY_AUCTIONS: Starting winner check for ${auctions.length} auctions...');
      
      for (final auction in auctions) {
        final endDate = auction['auction_end_date'];
        final endTime = auction['auction_end_time'];
        final auctionId = auction['id'];
        final title = auction['title'];
        
        print('📱 MY_AUCTIONS: Checking auction "$title" (ID: $auctionId)');
        print('📱 MY_AUCTIONS: End date: $endDate, End time: $endTime');
        
        // เช็คว่า auction หมดเวลาหรือยัง
        bool isEnded = false;
        if (endDate != null && endDate.isNotEmpty) {
          isEnded = isAuctionEnded(endDate, endTime);
        } else {
          print('📱 MY_AUCTIONS: No end date in auction data, will check via API...');
          // ถ้าไม่มี end date ในข้อมูล ให้ใช้ API เช็คแทน
          isEnded = true; // ให้ API เป็นตัวตัดสินใจ
        }
        
        if (isEnded) {
          print('📱 MY_AUCTIONS: Auction "$title" has ended! Checking if already announced...');
          
          // เช็คว่าการประมูลนี้ถูกประกาศผู้ชนะแล้วหรือยัง
          try {
            final isAlreadyAnnounced = await WinnerService.isWinnerAnnounced(auctionId);
            
            if (!isAlreadyAnnounced) {
              print('📱 MY_AUCTIONS: Auction "$title" not announced yet! Triggering winner announcement...');
              
              // เรียกใช้ trigger ประกาศผู้ชนะโดยตรง - ส่งแค่ user_id อย่างเดียว
              final result = await WinnerService.triggerAnnounceWinner(auctionId, userId);
              print('📱 MY_AUCTIONS: Trigger result: ${result['status']} - ${result['message']}');
              
              // ถ้าประกาศสำเร็จ ให้ refresh ข้อมูล
              if (result['status'] == 'success') {
                print('📱 MY_AUCTIONS: Winner announced successfully! Refreshing data...');
                // รีเฟรชข้อมูลหลังจากประกาศผู้ชนะสำเร็จ
                await _loadUserWonAuctions();
              } else {
                print('⚠️ MY_AUCTIONS: Winner announcement failed: ${result['message']}');
                // ไม่ throw error เพราะอาจเป็นเพราะประกาศไปแล้ว
              }
            } else {
              print('📱 MY_AUCTIONS: Auction "$title" already announced, skipping...');
            }
          } catch (e) {
            print('❌ MY_AUCTIONS: Error checking winner announcement status: $e');
            // ถ้าเช็คไม่ได้ ให้ลองประกาศเลย
            print('📱 MY_AUCTIONS: Trying to announce winner anyway...');
            try {
              final result = await WinnerService.triggerAnnounceWinner(auctionId, userId);
              print('📱 MY_AUCTIONS: Fallback trigger result: ${result['status']} - ${result['message']}');
              if (result['status'] == 'success') {
                await _loadUserWonAuctions();
              } else {
                print('⚠️ MY_AUCTIONS: Fallback announcement failed: ${result['message']}');
              }
            } catch (fallbackError) {
              print('⚠️ MY_AUCTIONS: Fallback announcement also failed: $fallbackError');
              // ไม่ throw error ออกไป
            }
          }
        } else {
          print('⏰ MY_AUCTIONS: Auction "$title" not ended yet');
        }
      }
      
      print('📱 MY_AUCTIONS: Winner check completed for all auctions');
    } catch (e) {
      print('❌ MY_AUCTIONS: Error in winner check: $e');
      // ไม่แสดง error ให้ user เห็น เพราะเป็น background process
    }
  }

  // ฟังก์ชันใหม่: ประกาศผู้ชนะด้วยตนเอง (สำหรับทดสอบ)
  Future<void> _manualTriggerWinnerAnnouncement(String auctionId, String userId) async {
    try {
      print('🔧 MANUAL: Manual winner announcement triggered for auction: $auctionId');
      print('🔧 MANUAL: Announced by user: $userId');
      
      final result = await WinnerService.triggerAnnounceWinner(auctionId, userId);
      print('🔧 MANUAL: Trigger result: ${result['status']} - ${result['message']}');
      
      if (result['status'] == 'success') {
        print('🎉 MANUAL: Winner announced successfully!');
        // รีเฟรชข้อมูล
        await _loadUserWonAuctions();
        await _loadUserBidHistory();
      } else {
        print('⚠️ MANUAL: Winner announcement failed: ${result['message']}');
        // ไม่ throw error เพราะอาจเป็นเพราะประกาศไปแล้ว
      }
    } catch (e) {
      print('⚠️ MANUAL: Error in manual winner announcement: $e');
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
      
      print('🔍 HAS_WINNER_INFO: Checking winner info...');
      print('🔍 HAS_WINNER_INFO: firstname: ${firstname.isNotEmpty ? "✓" : "✗"}');
      print('🔍 HAS_WINNER_INFO: lastname: ${lastname.isNotEmpty ? "✓" : "✗"}');
      print('🔍 HAS_WINNER_INFO: phone: ${phone.isNotEmpty ? "✓" : "✗"}');
      print('🔍 HAS_WINNER_INFO: address: ${address.isNotEmpty ? "✓" : "✗"}');
      print('🔍 HAS_WINNER_INFO: provinceId: ${provinceId.isNotEmpty ? "✓" : "✗"}');
      print('🔍 HAS_WINNER_INFO: districtId: ${districtId.isNotEmpty ? "✓" : "✗"}');
      print('🔍 HAS_WINNER_INFO: subDistrictId: ${subDistrictId.isNotEmpty ? "✓" : "✗"}');
      print('🔍 HAS_WINNER_INFO: Has complete info: $hasRequiredInfo');
      
      return hasRequiredInfo;
    } catch (e) {
      print('❌ HAS_WINNER_INFO: Error checking winner info: $e');
      return false;
    }
  }

  // Save winner information using WinnerService
  Future<void> _saveWinnerInfoToServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id') ?? '';
      
      if (userId.isEmpty) {
        throw Exception('ไม่พบข้อมูล ID ผู้ใช้');
      }

      // สร้างข้อมูลผู้ชนะจาก form controllers
      final winnerInfo = WinnerService.createWinnerInfo(
        customerId: userId,
        fullname: '${_controllers['firstname']!.text} ${_controllers['lastname']!.text}'.trim(),
        email: _controllers['email']!.text,
        phone: _controllers['phone']!.text,
        addr: _controllers['address']!.text,
        provinceId: _controllers['provinceId']!.text,
        districtId: _controllers['districtId']!.text,
        subDistrictId: _controllers['subDistrictId']!.text,
        sub: _controllers['sub']!.text,
        taxNumber: _controllers['taxNumber']!.text,
      );

      // บันทึกข้อมูลผู้ชนะ
      final result = await WinnerService.saveWinnerInfo(winnerInfo);
      
      if (result['success'] == true) {
        print('✅ บันทึกข้อมูลผู้ชนะเรียบร้อยแล้ว');
        print('✅ ข้อมูลที่บันทึก: ${result['data']}');
        
        // บันทึกข้อมูลลง SharedPreferences ด้วย prefix winner_ เพื่อให้ validateWinnerInfo ใช้งานได้
        await prefs.setString('winner_firstname', _controllers['firstname']!.text);
        await prefs.setString('winner_lastname', _controllers['lastname']!.text);
        await prefs.setString('winner_phone', _controllers['phone']!.text);
        await prefs.setString('winner_address', _controllers['address']!.text);
        await prefs.setString('winner_tax_number', _controllers['taxNumber']!.text);
        await prefs.setString('winner_email', _controllers['email']!.text);
        await prefs.setString('winner_province_id', _controllers['provinceId']!.text);
        await prefs.setString('winner_district_id', _controllers['districtId']!.text);
        await prefs.setString('winner_sub_district_id', _controllers['subDistrictId']!.text);
        await prefs.setString('winner_sub', _controllers['sub']!.text);
        await prefs.setString('winner_zip_code', _controllers['zipCode']!.text);
        
        print('✅ บันทึกข้อมูลลง SharedPreferences เรียบร้อยแล้ว');
      } else {
        throw Exception('บันทึกข้อมูลไม่สำเร็จ: ${result['message']}');
      }
    } catch (e) {
      print('Error saving winner info: $e');
      rethrow;
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
      if ((dateToCheck == null || dateToCheck.isEmpty) && endTime != null && endTime.isNotEmpty) {
        dateToCheck = endTime;
      }
      if (dateToCheck == null || dateToCheck.isEmpty) return false;
      
      String dateTimeString = dateToCheck;
      if (endTime != null && endTime.isNotEmpty && !dateToCheck.contains(' ')) {
        dateTimeString = '$dateToCheck $endTime';
      }
      
      final end = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      
      print('📱 MY_AUCTIONS: Current time: ${now.toString()}');
      print('📱 MY_AUCTIONS: End time: ${end.toString()}');
      print('📱 MY_AUCTIONS: Is auction ended? ${now.isAfter(end)}');
      
      return now.isAfter(end);
    } catch (e) {
      print('❌ MY_AUCTIONS: Error parsing date: $e');
      return false;
    }
  }

  // เพิ่มฟังก์ชันคำนวณอันดับ
  int getUserBidRank(List<dynamic> bidHistory, String userId) {
    final sorted = List<Map<String, dynamic>>.from(bidHistory)
      ..sort((a, b) => (b['bid_amount'] as num).compareTo(a['bid_amount'] as num));
    final idx = sorted.indexWhere((bid) => bid['bidder_id'].toString() == userId);
    return idx >= 0 ? idx + 1 : -1;
  }

  @override
  Widget build(BuildContext context) {
    // Filter lists for each tab using 'auction_end_date' or fallback to 'auction_end_time'
    final List<Map<String, dynamic>> filteredActiveBids = _activeBids.where((auction) {
      final endDate = auction['auction_end_date'];
      final endTime = auction['auction_end_time'];
      return !isAuctionEnded(endDate, endTime);
    }).toList();
    // For won tab, use only _wonAuctions from WinnerService
    final List<Map<String, dynamic>> filteredWonAuctions = _wonAuctions.where((auction) {
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
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'ชนะ\n${filteredWonAuctions.length}',
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
                _isLoadingActiveBids
                    ? Center(child: CircularProgressIndicator())
                    : filteredActiveBids.isEmpty
                        ? buildEmptyState(
                            icon: Icons.gavel,
                            title: 'ไม่มีรายการที่กำลังประมูล',
                            subtitle: 'คุณยังไม่ได้เข้าร่วมการประมูลใดๆ',
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            itemCount: filteredActiveBids.length,
                            itemBuilder: (context, index) {
                              final auction = Map<String, dynamic>.from(filteredActiveBids[index]);
                              final prefs = SharedPreferences.getInstance();
                              return FutureBuilder<SharedPreferences>(
                                future: prefs,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    auction['myBidRank'] = '-';
                                    return ActiveBidCard(
                                      auction: auction,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AuctionDetailViewPage(auctionData: auction),
                                          ),
                                        );
                                      },
                                      getStatusColor: _getStatusColor,
                                      getStatusText: _getStatusText,
                                      small: true,
                                    );
                                  }
                                  final userId = snapshot.data!.getString('id') ?? '';
                                  return FutureBuilder<List<dynamic>>(
                                    future: UserBidHistoryService.getUserBidRanking(auction['id'].toString()),
                                    builder: (context, rankSnapshot) {
                                      if (rankSnapshot.connectionState == ConnectionState.waiting) {
                                        auction['myBidRank'] = '-';
                                      } else if (rankSnapshot.hasData) {
                                        print('DEBUG: userId type = ${userId.runtimeType}, value = $userId');
                                        for (var e in rankSnapshot.data!) {
                                          print('DEBUG: bidder_id type = ${e['bidder_id'].runtimeType}, value = ${e['bidder_id']}');
                                        }
                                        final userRanks = rankSnapshot.data!
                                            .where((e) => e['bidder_id'].toString() == userId.toString())
                                            .toList();
                                        if (userRanks.isNotEmpty) {
                                          final latest = userRanks.first;
                                          auction['myBidRank'] = latest['rank']?.toString() ?? '-';
                                        } else {
                                          auction['myBidRank'] = '-';
                                        }
                                      } else {
                                        auction['myBidRank'] = '-';
                                      }
                                      return ActiveBidCard(
                                        auction: auction,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AuctionDetailViewPage(auctionData: auction),
                                            ),
                                          );
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
                        ? buildEmptyState(
                            icon: Icons.emoji_events,
                            title: 'ยังไม่มีรายการที่ชนะ',
                            subtitle: 'เข้าร่วมการประมูลเพื่อมีโอกาสชนะ',
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            itemCount: filteredWonAuctions.length,
                            itemBuilder: (context, index) {
                              return buildWonAuctionCard(context, filteredWonAuctions[index], _hasWinnerInfo, _loadProfileAndShowDialog);
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
  Future<void> _fillControllersWithProfile(Map<String, dynamic> profile) async {
    // แยกชื่อและนามสกุลจาก fullname
    final fullname = profile['fullname'] ?? '';
    final nameParts = fullname.split(' ');
    final firstname = nameParts.isNotEmpty ? nameParts.first : '';
    final lastname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    // ปรับเบอร์โทรให้ขึ้นต้นด้วย 0 ถ้าข้อมูลมี 9 หลักและไม่ขึ้นต้นด้วย 0
    final rawPhone = profile['phone'] ?? '';
    final phone = (rawPhone.length == 9 && !rawPhone.startsWith('0')) ? '0$rawPhone' : rawPhone;

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
      await prefs.setString('winner_sub_district_id', profile['sub_district_id'] ?? '');
      await prefs.setString('winner_sub', profile['sub'] ?? '');
      await prefs.setString('winner_zip_code', profile['zip_code'] ?? '');
      
      print('✅ บันทึกข้อมูลโปรไฟล์ลง SharedPreferences เรียบร้อยแล้ว');
    } catch (e) {
      print('❌ Error saving profile to SharedPreferences: $e');
    }
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _fillControllersWithProfile(profile);
                      AuctionDialogs.showWinnerInfoDialog(
                        context,
                        auction,
                        _controllers,
                        _saveWinnerInfoToServer,
                        _validateForm,
                        _showValidationError,
                      );
                    },
                    icon: Icon(Icons.edit, color: Colors.blue),
                    label: Text('แก้ไขข้อมูล', style: TextStyle(color: Colors.blue)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      AuctionDialogs.showPaymentDialog(context, auction);
                    },
                    icon: Icon(Icons.payment, color: Colors.white),
                    label: Text('ติดต่อชำระเงิน', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Future<void> _showMissingFieldsDialog(Map<String, dynamic> auction, Map<String, dynamic> profile, List<String> missingFields) async {
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
              onPressed: () async {
                Navigator.of(context).pop();
                // เติมข้อมูลที่มีอยู่แล้วใน controllers ก่อนแสดงฟอร์ม
                await _fillControllersWithProfile(profile);
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