import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_auction/views/config/config_prod.dart';

class UserBidHistoryService {
  static const String baseUrl = '${Config.apiUrlAuction}/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php';
  
  // ดึงประวัติการประมูลของผู้ใช้
  static Future<Map<String, dynamic>> getUserBidHistory(String bidderId) async {
    try {
      print('DEBUG: Fetching bid history for user: $bidderId');
      final response = await http.get(
        Uri.parse('$baseUrl?action=user_bid_history&bidder_id=$bidderId'),
      );

      print('DEBUG: API Response Status: ${response.statusCode}');
      print('DEBUG: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG: Parsed data: $data');
        
        // Handle case where API returns List instead of Map
        if (data is List) {
          return {
            'status': 'success',
            'data': {
              'bid_history': data,
            },
          };
        } else if (data is Map<String, dynamic>) {
          return data;
        } else {
          return {
            'status': 'success',
            'data': {
              'bid_history': [],
            },
          };
        }
      } else {
        throw Exception('Failed to get user bid history: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error getting user bid history: $e');
      throw Exception('Error getting user bid history: $e');
    }
  }

  // ดึงสถิติการประมูลของผู้ใช้
  static Future<Map<String, dynamic>> getUserBidStats(String bidderId) async {
    try {
      print('DEBUG: Fetching bid stats for user: $bidderId');
      final response = await http.get(
        Uri.parse('$baseUrl?action=user_bid_stats&bidder_id=$bidderId'),
      );

      print('DEBUG: Stats API Response Status: ${response.statusCode}');
      print('DEBUG: Stats API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG: Parsed stats data: $data');
        return data;
      } else {
        throw Exception('Failed to get user bid stats: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error getting user bid stats: $e');
      throw Exception('Error getting user bid stats: $e');
    }
  }

  /// ดึงข้อมูล user bid ranking สำหรับ auction เฉพาะรายการ
  static Future<List<dynamic>> getUserBidRanking(String auctionId) async {
    try {
      final url = '${Config.apiUrlAuction}/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=$auctionId&action=user_bid_ranking';
      print('DEBUG: Fetching user bid ranking: $url');
      final response = await http.get(Uri.parse(url));
      print('DEBUG: User bid ranking response: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else {
          print('DEBUG: Unexpected user bid ranking response format');
          return [];
        }
      } else {
        print('DEBUG: Failed to fetch user bid ranking: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('DEBUG: Error fetching user bid ranking: $e');
      return [];
    }
  }

  // แปลงข้อมูล bid history เป็นรูปแบบที่ใช้ในแอป
  static List<Map<String, dynamic>> convertBidHistoryToAppFormat(List<dynamic> bidHistory) {
    return bidHistory.map((bid) {
      // แปลง quotation_image จาก JSON string เป็น List
      List<String> images = [];
      try {
        final imageData = jsonDecode(bid['quotation_image'] ?? '[]');
        if (imageData is List) {
          images = imageData.cast<String>();
        }
      } catch (e) {
        print('DEBUG: Error parsing quotation_image: $e');
        images = [];
      }

      return {
        'id': bid['quotation_more_information_id']?.toString() ?? '',
        'title': bid['short_text'] ?? bid['quotation_description'] ?? 'ไม่ระบุชื่อสินค้า',
        'myBid': double.tryParse(bid['bid_amount']?.toString() ?? '0') ?? 0,
        'currentPrice': double.tryParse(bid['current_price']?.toString() ?? '0') ?? 0,
        'startingPrice': double.tryParse(bid['star_price']?.toString() ?? '0') ?? 0,
        'minimumIncrease': double.tryParse(bid['minimum_increase']?.toString() ?? '5') ?? 5,
        'bidTime': bid['bid_time'] ?? '',
        'quotationId': bid['quotation_id']?.toString() ?? '',
        'quotationSequence': bid['quotation_sequence'] ?? '',
        'quotationMainId': bid['quotation_main_id']?.toString() ?? '',
        'bidId': bid['bid_id']?.toString() ?? '',
        'bidderName': bid['bidder_name'] ?? '',
        'images': images,
        'image': images.isNotEmpty ? images.first : 'assets/images/noimage.jpg',
        'status': _determineBidStatus(bid),
        'timeRemaining': _calculateTimeRemaining(bid),
        'bidCount': 1, // จะต้องดึงจาก API อื่น
        'myBidRank': 1, // จะต้องดึงจาก API อื่น
        'description': bid['short_text'] ?? bid['quotation_description'] ?? 'ไม่มีคำอธิบาย',
        'sellerName': 'CloudmateTH', // จะต้องดึงจาก API อื่น
        'sellerRating': '4.5', // จะต้องดึงจาก API อื่น
        'auction_end_date': bid['auction_end_date'] ?? bid['auction_end_time'] ?? '',
      };
    }).toList();
  }

  // กำหนดสถานะการประมูล
  static String _determineBidStatus(Map<String, dynamic> bid) {
    // ตรวจสอบว่าเป็น bid ล่าสุดหรือไม่
    // ถ้าเป็น bid ล่าสุด = 'winning', ถ้าไม่ใช่ = 'outbid'
    // ต้องเปรียบเทียบกับ bid อื่นๆ ในรายการเดียวกัน
    return 'active'; // ค่าเริ่มต้น
  }

  // คำนวณเวลาที่เหลือ
  static String _calculateTimeRemaining(Map<String, dynamic> bid) {
    // ต้องดึงข้อมูล end_date จาก API อื่น
    return 'เหลือ 2:30:45'; // ค่าเริ่มต้น
  }

  // จัดกลุ่ม bid history ตาม quotation
  static Map<String, List<Map<String, dynamic>>> groupBidsByQuotation(List<Map<String, dynamic>> bidHistory) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (final bid in bidHistory) {
      final quotationId = bid['quotationId'] ?? '';
      if (!grouped.containsKey(quotationId)) {
        grouped[quotationId] = [];
      }
      grouped[quotationId]!.add(bid);
    }
    
    return grouped;
  }

  // หา bid สูงสุดของแต่ละ quotation
  static Map<String, Map<String, dynamic>> getHighestBidsByQuotation(List<Map<String, dynamic>> bidHistory) {
    final grouped = groupBidsByQuotation(bidHistory);
    final highestBids = <String, Map<String, dynamic>>{};
    
    grouped.forEach((quotationId, bids) {
      if (bids.isNotEmpty) {
        // เรียงตาม bid_amount จากมากไปน้อย
        bids.sort((a, b) => (b['myBid'] as double).compareTo(a['myBid'] as double));
        highestBids[quotationId] = bids.first;
      }
    });
    
    return highestBids;
  }
} 