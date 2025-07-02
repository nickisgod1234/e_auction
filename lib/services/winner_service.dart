import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_auction/views/config/config_prod.dart';

class WinnerService {
  static const String baseUrl = '${Config.apiUrllocal}/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php';
  
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
        return data;
      } else {
        throw Exception('Failed to get user winners: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error getting user winners: $e');
      throw Exception('Error getting user winners: $e');
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

  // ประกาศผู้ชนะ
  static Future<Map<String, dynamic>> announceWinner(String auctionId, Map<String, String> winnerInfo) async {
    try {
      print('🚀 ANNOUNCE: Starting winner announcement for auction: $auctionId');
      print('🚀 ANNOUNCE: Winner info: $winnerInfo');
      
      final response = await http.post(
        Uri.parse('$baseUrl?id=$auctionId&action=announce_winner'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'winner_firstname': winnerInfo['firstname'] ?? '',
          'winner_lastname': winnerInfo['lastname'] ?? '',
          'winner_phone': winnerInfo['phone'] ?? '',
          'winner_email': winnerInfo['email'] ?? '',
          'winner_address': winnerInfo['address'] ?? '',
        }),
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

  // เช็คและประกาศผู้ชนะอัตโนมัติ
  static Future<void> checkAndAnnounceWinner(String auctionId, Map<String, String> winnerInfo) async {
    try {
      print('🔍 TRIGGER: Checking auction $auctionId for winner announcement...');
      
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
                  print('🎉 TRIGGER: Winner info: $winnerInfo');
                  
                  final result = await announceWinner(auctionId, winnerInfo);
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
            await _tryAlternativeAuctionDetails(auctionId, winnerInfo);
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

  // ลองดึงข้อมูล auction จาก API อื่น
  static Future<void> _tryAlternativeAuctionDetails(String auctionId, Map<String, String> winnerInfo) async {
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
                  final result = await announceWinner(auctionId, winnerInfo);
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

  // ฟังก์ชัน trigger ประกาศผู้ชนะโดยตรง (ตามที่คุณต้องการ)
  static Future<Map<String, dynamic>> triggerAnnounceWinner(String auctionId, Map<String, String> winnerInfo) async {
    try {
      print('🚀 TRIGGER_DIRECT: Starting direct winner announcement for auction: $auctionId');
      print('🚀 TRIGGER_DIRECT: Winner info: $winnerInfo');
      
      final url = '$baseUrl?id=$auctionId&action=announce_winner';
      print('🚀 TRIGGER_DIRECT: API URL: $url');
      
      // เพิ่ม debug: เช็คว่า auction หมดเวลาหรือยังก่อนเรียก API
      print('🔍 TRIGGER_DIRECT: Checking if auction $auctionId has ended...');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'winner_firstname': winnerInfo['firstname'] ?? '',
          'winner_lastname': winnerInfo['lastname'] ?? '',
          'winner_phone': winnerInfo['phone'] ?? '',
          'winner_email': winnerInfo['email'] ?? '',
          'winner_address': winnerInfo['address'] ?? '',
        }),
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
} 