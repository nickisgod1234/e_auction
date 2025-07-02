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
} 