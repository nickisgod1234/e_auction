import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_auction/views/config/config_prod.dart';

class UserBidHistoryService {
  static const String baseUrl =
      '${Config.apiUrlAuction}/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php';

  // ดึงประวัติการประมูลของผู้ใช้
  static Future<Map<String, dynamic>> getUserBidHistory(String bidderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=user_bid_history&bidder_id=$bidderId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

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
        throw Exception(
            'Failed to get user bid history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting user bid history: $e');
    }
  }

  // ดึงสถิติการประมูลของผู้ใช้
  static Future<Map<String, dynamic>> getUserBidStats(String bidderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=user_bid_stats&bidder_id=$bidderId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data;
      } else {
        throw Exception('Failed to get user bid stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting user bid stats: $e');
    }
  }

  /// ดึงข้อมูล user bid ranking สำหรับ auction เฉพาะรายการ
  static Future<List<dynamic>> getUserBidRanking(String auctionId) async {
    try {
      final url =
          '${Config.apiUrlAuction}/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=$auctionId&action=user_bid_ranking';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // แปลงข้อมูล bid history เป็นรูปแบบที่ใช้ในแอป
  static List<Map<String, dynamic>> convertBidHistoryToAppFormat(
      List<dynamic> bidHistory) {
    return bidHistory.map((bid) {
      // แปลง quotation_image จาก JSON string เป็น List
      List<String> images = [];
      String imageUrl = 'assets/images/noimage.jpg';

      try {
        if (bid['quotation_image'] != null &&
            bid['quotation_image'].toString().isNotEmpty) {
          final imageData = jsonDecode(bid['quotation_image']);
          if (imageData is List && imageData.isNotEmpty) {
            images = imageData.cast<String>();
            if (images.isNotEmpty && images.first.isNotEmpty) {
              // สร้าง URL รูปภาพ
              imageUrl =
                  'https://cm-mecustomers.com/ERP-Cloudmate/modules/sales/uploads/quotation/${images.first}';
            }
          }
        }

        // ถ้าไม่มีรูปภาพจาก quotation_image ให้ลองใช้ quotation_id ไปดึงข้อมูลจาก API หลัก
        if (imageUrl == 'assets/images/noimage.jpg' &&
            bid['quotation_id'] != null) {
          // ใช้ quotation_id ไปดึงข้อมูลจาก API หลัก (เหมือนที่หน้า home ใช้)
          // แต่เนื่องจากเป็น static method จึงไม่สามารถใช้ async ได้
          // ให้ใช้ quotation_id เป็น fallback
          imageUrl =
              'https://cm-mecustomers.com/ERP-Cloudmate/modules/sales/uploads/quotation/img_6867a407860455.12296295.jpg';
        }
      } catch (e) {
        images = [];
      }

      return {
        'id': bid['quotation_more_information_id']?.toString() ?? '',
        'quotation_more_information_id':
            bid['quotation_more_information_id']?.toString() ?? '',
        'title': bid['short_text'] ??
            bid['quotation_description'] ??
            'ไม่ระบุชื่อสินค้า',
        'myBid': double.tryParse(bid['bid_amount']?.toString() ?? '0') ?? 0,
        'currentPrice':
            double.tryParse(bid['current_price']?.toString() ?? '0') ?? 0,
        'startingPrice':
            double.tryParse(bid['star_price']?.toString() ?? '0') ?? 0,
        'minimumIncrease':
            double.tryParse(bid['minimum_increase']?.toString() ?? '5') ?? 5,
        'bidTime': bid['bid_time'] ?? '',
        'quotationId': bid['quotation_id']?.toString() ?? '',
        'quotationSequence': bid['quotation_sequence'] ?? '',
        'quotationMainId': bid['quotation_main_id']?.toString() ?? '',
        'bidId': bid['bid_id']?.toString() ?? '',
        'bidderName': bid['bidder_name'] ?? '',
        'images': images,
        'image': imageUrl,
        'status': _determineBidStatus(bid),
        'timeRemaining': _calculateTimeRemaining(bid),
        'bidCount': 1, // จะต้องดึงจาก API อื่น
        'myBidRank': 1, // จะต้องดึงจาก API อื่น
        'description': bid['short_text'] ??
            bid['quotation_description'] ??
            'ไม่มีคำอธิบาย',
        'sellerName': 'CloudmateTH', // จะต้องดึงจาก API อื่น
        'sellerRating': '4.5', // จะต้องดึงจาก API อื่น
        'auction_end_date':
            bid['auction_end_date'] ?? bid['auction_end_time'] ?? '',
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
  static Map<String, List<Map<String, dynamic>>> groupBidsByQuotation(
      List<Map<String, dynamic>> bidHistory) {
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
  static Map<String, Map<String, dynamic>> getHighestBidsByQuotation(
      List<Map<String, dynamic>> bidHistory) {
    final grouped = groupBidsByQuotation(bidHistory);
    final highestBids = <String, Map<String, dynamic>>{};

    grouped.forEach((quotationId, bids) {
      if (bids.isNotEmpty) {
        // เรียงตาม bid_amount จากมากไปน้อย
        bids.sort(
            (a, b) => (b['myBid'] as double).compareTo(a['myBid'] as double));
        highestBids[quotationId] = bids.first;
      }
    });

    return highestBids;
  }
}
