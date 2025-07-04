import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_auction/views/config/config_prod.dart';

class WinnerService {
  static const String baseUrl = '${Config.apiUrlAuction}/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php';
  static const String logsBaseUrl = '${Config.apiUrlAuction}/ERP-Cloudmate/modules/sales/controllers/auction_announcement_logs_controller.php';
  
  // ดึงข้อมูลผู้ชนะของแต่ละการประมูล
  static Future<Map<String, dynamic>> getWinnerByAuctionId(String auctionId) async {
    try {
      print('DEBUG: Fetching winner for auction: $auctionId');
      final response = await http.get(
        Uri.parse('$baseUrl?id=$auctionId&action=get_winner'),
      );

      print('DEBUG: Winner API Response Status: ${response.statusCode}');
      print('DEBUG: Winner API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG: Parsed winner data: $data');
        return data;
      } else {
        throw Exception('Failed to get winner: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error getting winner: $e');
      throw Exception('Error getting winner: $e');
    }
  }

  // ดึงข้อมูลผู้ชนะตาม user_id
  static Future<Map<String, dynamic>> getWinnersByUserId(String userId) async {
    try {
      print('DEBUG: Fetching winners for user: $userId');
      final response = await http.get(
        Uri.parse('$baseUrl?action=get_all_winners&winner_bidder_id=$userId'),
      );

      print('DEBUG: User Winners API Response Status: ${response.statusCode}');
      print('DEBUG: User Winners API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG: Parsed user winners data: $data');
        // ถ้า API ส่งกลับมาเป็น List ให้ wrap เป็น Map
        if (data is List) {
          return {
            'status': 'success',
            'data': data,
          };
        }
        if (data is Map<String, dynamic>) {
          return data;
        }
        // กรณีอื่นๆ
        return {
          'status': 'error',
          'message': 'Unknown response format',
          'data': null,
        };
      } else {
        throw Exception('Failed to get user winners: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error getting user winners: $e');
      return {
        'status': 'error',
        'message': e.toString(),
        'data': null,
      };
    }
  }

  // ดึงข้อมูลผู้ชนะทั้งหมด
  static Future<Map<String, dynamic>> getAllWinners() async {
    try {
      print('DEBUG: Fetching all winners');
      final response = await http.get(
        Uri.parse('$baseUrl?action=get_all_winners'),
      );

      print('DEBUG: All Winners API Response Status: ${response.statusCode}');
      print('DEBUG: All Winners API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG: Parsed all winners data: $data');
        return data;
      } else {
        throw Exception('Failed to get all winners: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error getting all winners: $e');
      throw Exception('Error getting all winners: $e');
    }
  }

  // แปลงข้อมูลผู้ชนะเป็นรูปแบบที่ใช้ในแอป
  static List<Map<String, dynamic>> convertWinnersToAppFormat(List<dynamic> winners) {
    return winners.map((winner) {
      return {
        'id': winner['quotation_more_information_id']?.toString() ?? '',
        'title': winner['short_text'] ?? winner['quotation_description'] ?? 'ไม่ระบุชื่อสินค้า',
        'finalPrice': double.tryParse(winner['winning_amount']?.toString() ?? '0') ?? 0,
        'myBid': double.tryParse(winner['winning_amount']?.toString() ?? '0') ?? 0,
        'completedDate': _formatCompletedDate(winner['winner_announced_time']),
        'image': 'assets/images/noimage.jpg', // จะต้องดึงจาก API อื่น
        'status': 'won',
        'sellerName': 'CloudmateTH', // จะต้องดึงจาก API อื่น
        'paymentStatus': 'pending', // จะต้องดึงจาก API อื่น
        'auctionId': winner['quotation_sequence'] ?? '',
        'winnerId': winner['winner_id']?.toString() ?? '',
        'quotationId': winner['quotation_id']?.toString() ?? '',
        'winnerBidderId': winner['winner_bidder_id']?.toString() ?? '',
        'winnerBidderName': winner['winner_bidder_name'] ?? '',
        'winningBidId': winner['winning_bid_id']?.toString() ?? '',
        'auctionEndTime': winner['auction_end_time'] ?? '',
        'winnerAnnouncedTime': winner['winner_announced_time'] ?? '',
        'winnerStatus': winner['status'] ?? '',
        'winnerFirstname': winner['winner_firstname'] ?? '',
        'winnerLastname': winner['winner_lastname'] ?? '',
        'winnerPhone': winner['winner_phone'] ?? '',
        'winnerEmail': winner['winner_email'] ?? '',
        'winnerAddress': winner['winner_address'] ?? '',
        'quotationSequence': winner['quotation_sequence'] ?? '',
        'quotationDescription': winner['quotation_description'] ?? '',
        'shortText': winner['short_text'] ?? '',
        'itemNumber': winner['item_number'] ?? '',
        'quantity': winner['quantity'] ?? '',
        'countUnitId': winner['count_unit_id'] ?? '',
        'description': winner['short_text'] ?? winner['quotation_description'] ?? 'ไม่มีคำอธิบาย',
        'auction_end_date': winner['auction_end_date'] ?? winner['auction_end_time'] ?? '',
        'announcedBy': winner['announced_by']?.toString() ?? '',
        'announcedAt': winner['announced_at'] ?? '',
      };
    }).toList();
  }

  // แปลงวันที่ให้เป็นรูปแบบที่อ่านง่าย
  static String _formatCompletedDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'ไม่ระบุวันที่';
    }

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} วันที่แล้ว';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ชั่วโมงที่แล้ว';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} นาทีที่แล้ว';
      } else {
        return 'เพิ่งเสร็จสิ้น';
      }
    } catch (e) {
      print('DEBUG: Error parsing date: $e');
      return 'ไม่ระบุวันที่';
    }
  }

  // ตรวจสอบว่าผู้ใช้เป็นผู้ชนะหรือไม่
  static bool isUserWinner(Map<String, dynamic> winner, String userId) {
    final winnerBidderId = winner['winner_bidder_id']?.toString() ?? '';
    return winnerBidderId == userId;
  }

  // กรองเฉพาะผู้ชนะของผู้ใช้
  static List<Map<String, dynamic>> filterUserWinners(List<Map<String, dynamic>> allWinners, String userId) {
    return allWinners.where((winner) => isUserWinner(winner, userId)).toList();
  }

  // ประกาศผู้ชนะ (เรียบง่าย - ส่งแค่ user_id)
  static Future<Map<String, dynamic>> announceWinner(String auctionId, String userId) async {
    try {
      print('🚀 ANNOUNCE: Starting winner announcement for auction: $auctionId');
      print('🚀 ANNOUNCE: Announced by user: $userId');
      
      // ส่งแค่ user_id อย่างเดียว
      final Map<String, dynamic> requestBody = {
        'user_id': int.tryParse(userId) ?? 0,
      };
      
      print('🚀 ANNOUNCE: Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl?id=$auctionId&action=announce_winner'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('🚀 ANNOUNCE: API Response Status: ${response.statusCode}');
      print('🚀 ANNOUNCE: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🚀 ANNOUNCE: Success! Winner announced: ${data['message']}');
        if (data['status'] == 'success') {
          print('🎉 ANNOUNCE: Winner data: ${data['data']}');
        }
        return data;
      } else {
        print('❌ ANNOUNCE: Failed to announce winner: ${response.statusCode}');
        throw Exception('Failed to announce winner: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ANNOUNCE: Error announcing winner: $e');
      throw Exception('Error announcing winner: $e');
    }
  }

  // เช็คและประกาศผู้ชนะอัตโนมัติ (เรียบง่าย)
  static Future<void> checkAndAnnounceWinner(String auctionId, String userId) async {
    try {
      print('🔍 TRIGGER: Checking auction $auctionId for winner announcement...');
      print('🔍 TRIGGER: Announced by user: $userId');
      
      // 1. ดึงข้อมูล auction details จาก API
      final auctionResponse = await http.get(
        Uri.parse('$baseUrl?id=$auctionId&action=get_auction_details'),
      );

      if (auctionResponse.statusCode == 200) {
        final auctionData = jsonDecode(auctionResponse.body);
        print('🔍 TRIGGER: Auction details response: $auctionData');
        
        if (auctionData['status'] == 'success' && auctionData['data'] != null) {
          final auction = auctionData['data'];
          final endDate = auction['auction_end_date'] ?? auction['auction_end_time'] ?? auction['end_date'] ?? auction['end_time'];
          
          print('🔍 TRIGGER: Auction end date/time: $endDate');
          
          if (endDate != null && endDate.isNotEmpty) {
            // เช็คว่า auction หมดเวลาหรือยัง
            if (_isAuctionEnded(endDate)) {
              print('✅ TRIGGER: Auction has ended! Checking for existing winner...');
              
              // 2. เช็คว่ามีผู้ชนะแล้วหรือยัง
              final winnerResponse = await http.get(
                Uri.parse('$baseUrl?id=$auctionId&action=get_winner'),
              );
              
              if (winnerResponse.statusCode == 200) {
                final winnerData = jsonDecode(winnerResponse.body);
                
                print('🔍 TRIGGER: Winner check response: ${winnerData['status']}');
                
                // ถ้ายังไม่มีผู้ชนะ
                if (winnerData['status'] != 'success' || winnerData['data'] == null) {
                  print('🎉 TRIGGER: No winner found! Announcing winner...');
                  print('🎉 TRIGGER: Announced by user: $userId');
                  
                  final result = await announceWinner(auctionId, userId);
                  print('🎉 TRIGGER: Announce result: ${result['status']} - ${result['message']}');
                } else {
                  print('ℹ️ TRIGGER: Winner already announced for auction: $auctionId');
                }
              } else {
                print('❌ TRIGGER: Failed to check winner status: ${winnerResponse.statusCode}');
              }
            } else {
              print('⏰ TRIGGER: Auction not ended yet: $auctionId');
            }
          } else {
            print('❌ TRIGGER: No end date found for auction: $auctionId');
            print('🔍 TRIGGER: Trying alternative API to get auction details...');
            
            // ลองดึงข้อมูลจาก API อื่น
            await _tryAlternativeAuctionDetails(auctionId, userId);
          }
        } else {
          print('❌ TRIGGER: Failed to get auction details: ${auctionData['message']}');
        }
      } else {
        print('❌ TRIGGER: Failed to get auction details: ${auctionResponse.statusCode}');
      }
    } catch (e) {
      print('❌ TRIGGER: Error checking and announcing winner: $e');
    }
  }

  // ลองดึงข้อมูล auction จาก API อื่น (เรียบง่าย)
  static Future<void> _tryAlternativeAuctionDetails(String auctionId, String userId) async {
    try {
      // ลองดึงข้อมูลจาก quotation API
      final quotationResponse = await http.get(
        Uri.parse('$baseUrl?id=$auctionId&action=get_quotation_details'),
      );

      if (quotationResponse.statusCode == 200) {
        final quotationData = jsonDecode(quotationResponse.body);
        print('🔍 TRIGGER: Quotation details response: $quotationData');
        
        if (quotationData['status'] == 'success' && quotationData['data'] != null) {
          final quotation = quotationData['data'];
          final endDate = quotation['auction_end_date'] ?? quotation['auction_end_time'] ?? quotation['end_date'] ?? quotation['end_time'];
          
          print('🔍 TRIGGER: Quotation end date/time: $endDate');
          
          if (endDate != null && endDate.isNotEmpty) {
            if (_isAuctionEnded(endDate)) {
              print('✅ TRIGGER: Auction has ended! Checking for existing winner...');
              
              // เช็คว่ามีผู้ชนะแล้วหรือยัง
              final winnerResponse = await http.get(
                Uri.parse('$baseUrl?id=$auctionId&action=get_winner'),
              );
              
              if (winnerResponse.statusCode == 200) {
                final winnerData = jsonDecode(winnerResponse.body);
                
                if (winnerData['status'] != 'success' || winnerData['data'] == null) {
                  print('🎉 TRIGGER: No winner found! Announcing winner...');
                  final result = await announceWinner(auctionId, userId);
                  print('🎉 TRIGGER: Announce result: ${result['status']} - ${result['message']}');
                } else {
                  print('ℹ️ TRIGGER: Winner already announced for auction: $auctionId');
                }
              }
            } else {
              print('⏰ TRIGGER: Auction not ended yet: $auctionId');
            }
          } else {
            print('❌ TRIGGER: Still no end date found, skipping winner announcement');
          }
        }
      }
    } catch (e) {
      print('❌ TRIGGER: Error trying alternative API: $e');
    }
  }

  // เช็คว่า auction หมดเวลาหรือยัง (ปรับปรุงให้ถูกต้อง)
  static bool _isAuctionEnded(String endDate, [String? endTime]) {
    try {
      String dateTimeString = endDate;
      if (endTime != null && endTime.isNotEmpty) {
        // ถ้า endDate ไม่มีเวลา ให้เพิ่ม endTime
        if (!endDate.contains(' ')) {
          dateTimeString = '$endDate $endTime';
        }
      }
      
      final endDateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      
      print('🔍 TRIGGER: Current time: ${now.toString()}');
      print('🔍 TRIGGER: End time: ${endDateTime.toString()}');
      print('🔍 TRIGGER: Is auction ended? ${now.isAfter(endDateTime)}');
      
      return now.isAfter(endDateTime);
    } catch (e) {
      print('❌ TRIGGER: Error parsing date: $e');
      return false;
    }
  }

  // ฟังก์ชัน trigger ประกาศผู้ชนะโดยตรง (เรียบง่าย - ส่งแค่ user_id)
  static Future<Map<String, dynamic>> triggerAnnounceWinner(String auctionId, String userId) async {
    try {
      print('🚀 TRIGGER_DIRECT: Starting direct winner announcement for auction: $auctionId');
      print('🚀 TRIGGER_DIRECT: Announced by user: $userId');
      
      final url = '$baseUrl?id=$auctionId&action=announce_winner';
      print('🚀 TRIGGER_DIRECT: API URL: $url');
      
      // ส่งแค่ user_id อย่างเดียว
      final Map<String, dynamic> requestBody = {
        'user_id': int.tryParse(userId) ?? 0,
      };
      
      print('🚀 TRIGGER_DIRECT: Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('🚀 TRIGGER_DIRECT: API Response Status: ${response.statusCode}');
      print('🚀 TRIGGER_DIRECT: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('🎉 TRIGGER_DIRECT: Winner announced successfully!');
          print('🎉 TRIGGER_DIRECT: Winner data: ${data['data']}');
          return data;
        } else {
          print('❌ TRIGGER_DIRECT: Failed to announce winner: ${data['message']}');
          return data;
        }
      } else {
        print('❌ TRIGGER_DIRECT: HTTP Error: ${response.statusCode}');
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ TRIGGER_DIRECT: Error announcing winner: $e');
      throw Exception('Error announcing winner: $e');
    }
  }

  // ฟังก์ชันใหม่: ดึง log การประกาศผู้ชนะ
  static Future<List<dynamic>> getAnnouncementLogs({
    String? quotationMoreInformationId,
    String? announcedBy,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      print('📋 LOGS: Fetching announcement logs...');
      
      final queryParams = <String, String>{};
      if (quotationMoreInformationId != null) {
        queryParams['quotation_more_information_id'] = quotationMoreInformationId;
      }
      if (announcedBy != null) {
        queryParams['announced_by'] = announcedBy;
      }
      if (status != null) {
        queryParams['status'] = status;
      }
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom;
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo;
      }

      final uri = Uri.parse(logsBaseUrl).replace(queryParameters: queryParams);
      print('📋 LOGS: API URL: $uri');

      final response = await http.get(uri);
      
      print('📋 LOGS: API Response Status: ${response.statusCode}');
      print('📋 LOGS: API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final logs = data['data'] ?? [];
        print('📋 LOGS: Found ${logs.length} log entries');
        return logs;
      } else {
        print('❌ LOGS: Failed to get announcement logs: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ LOGS: Error getting announcement logs: $e');
      return [];
    }
  }

  // ฟังก์ชันใหม่: ตรวจสอบว่าประกาศผู้ชนะแล้วหรือยัง
  static Future<bool> isWinnerAnnounced(String quotationMoreInformationId) async {
    try {
      print('🔍 CHECK: Checking if winner is announced for auction: $quotationMoreInformationId');
      
      final response = await http.get(
        Uri.parse('$baseUrl?id=$quotationMoreInformationId&action=get_winner'),
      );
      
      print('🔍 CHECK: API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isAnnounced = data['status'] == 'success' && data['data'] != null;
        print('🔍 CHECK: Winner announced: $isAnnounced');
        return isAnnounced;
      } else {
        print('🔍 CHECK: Failed to check winner status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ CHECK: Error checking winner announcement: $e');
      return false;
    }
  }

  // ฟังก์ชันใหม่: ดึงข้อมูลผู้ชนะ
  static Future<Map<String, dynamic>?> getWinnerData(String quotationMoreInformationId) async {
    try {
      print('📊 WINNER: Fetching winner data for auction: $quotationMoreInformationId');
      
      final response = await http.get(
        Uri.parse('$baseUrl?id=$quotationMoreInformationId&action=get_winner'),
      );
      
      print('📊 WINNER: API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          print('📊 WINNER: Winner data found');
          return data['data'];
        } else {
          print('📊 WINNER: No winner data found');
          return null;
        }
      } else {
        print('❌ WINNER: Failed to get winner data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ WINNER: Error getting winner data: $e');
      return null;
    }
  }

  // ฟังก์ชันใหม่: บันทึกข้อมูลผู้ชนะ
  static Future<Map<String, dynamic>> saveWinnerInfo(Map<String, dynamic> winnerInfo) async {
    try {
      print('💾 SAVE: Saving winner information...');
      print('💾 SAVE: Winner info: $winnerInfo');
      
      // แสดงเบอร์โทรศัพท์ที่ทำความสะอาดแล้ว
      final originalPhone = winnerInfo['phone'];
      final cleanPhone = originalPhone.toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (originalPhone != cleanPhone) {
        print('💾 SAVE: Phone number cleaned: "$originalPhone" -> "$cleanPhone"');
        winnerInfo['phone'] = cleanPhone;
      }
      
      final url = '${Config.apiUrl}/HR-API-morket/login_phone_auction/save_user.php';
      print('💾 SAVE: API URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(winnerInfo),
      );

      print('💾 SAVE: API Response Status: ${response.statusCode}');
      print('💾 SAVE: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ SAVE: Winner information saved successfully!');
          print('✅ SAVE: Saved data: ${data['data']}');
          return data;
        } else {
          print('❌ SAVE: Failed to save winner information: ${data['message']}');
          return data;
        }
      } else {
        print('❌ SAVE: HTTP Error: ${response.statusCode}');
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ SAVE: Error saving winner information: $e');
      throw Exception('Error saving winner information: $e');
    }
  }

  // ฟังก์ชันใหม่: สร้างข้อมูลผู้ชนะจาก form
  static Map<String, dynamic> createWinnerInfo({
    required String customerId,
    required String fullname,
    required String email,
    required String phone,
    required String addr,
    required String provinceId,
    required String districtId,
    required String subDistrictId,
    required String sub,
    String type = 'individual',
    String companyId = '1',
    String taxNumber = '',
    String name = '',
    String code = '',
  }) {
    // ทำความสะอาดเบอร์โทรศัพท์ - ลบเครื่องหมายที่ไม่ใช่ตัวเลข
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    return {
      'customer_id': customerId,
      'fullname': fullname,
      'email': email,
      'phone': cleanPhone,
      'addr': addr,
      'province_id': provinceId,
      'district_id': districtId,
      'sub_district_id': subDistrictId,
      'sub': sub,
      'type': type,
      'company_id': companyId,
      'tax_number': taxNumber,
      'name': name.isNotEmpty ? name : fullname.split(' ').first,
      'code': code.isNotEmpty ? code : 'CUST$customerId',
    };
  }
} 