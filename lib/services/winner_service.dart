import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_auction/views/config/config_prod.dart';

class WinnerService {
  static const String baseUrl =
      '${Config.apiUrlAuction}/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php';
  static const String logsBaseUrl =
      '${Config.apiUrlAuction}/ERP-Cloudmate/modules/sales/controllers/auction_announcement_logs_controller.php';

  // ดึงข้อมูลผู้ชนะของแต่ละการประมูล
  static Future<Map<String, dynamic>> getWinnerByAuctionId(
      String auctionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?id=$auctionId&action=get_winner'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data;
      } else {
        throw Exception('Failed to get winner: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting winner: $e');
    }
  }

  // ดึงข้อมูลผู้ชนะตาม user_id
  static Future<Map<String, dynamic>> getWinnersByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=get_all_winners&winner_bidder_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

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
      final response = await http.get(
        Uri.parse('$baseUrl?action=get_all_winners'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data;
      } else {
        throw Exception('Failed to get all winners: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting all winners: $e');
    }
  }

  // แปลงข้อมูลผู้ชนะเป็นรูปแบบที่ใช้ในแอป
  static List<Map<String, dynamic>> convertWinnersToAppFormat(
      List<dynamic> winners) {
    return winners.map((winner) {
      // สร้างข้อมูลที่อยู่เต็มรูปแบบ
      final addressData = {
        'addr': winner['winner_address'] ?? winner['addr'] ?? '',
        'village': winner['winner_village'] ?? winner['village'] ?? '',
        'road': winner['winner_road'] ?? winner['road'] ?? '',
        'sub': winner['winner_sub'] ?? winner['sub'] ?? '',
        'postal_code': winner['winner_postal_code'] ?? winner['postal_code'] ?? '',
        'country': winner['winner_country'] ?? winner['country'] ?? 'Thailand',
      };

      return {
        'id': winner['quotation_more_information_id']?.toString() ?? '',
        'title': winner['short_text'] ??
            winner['quotation_description'] ??
            'ไม่ระบุชื่อสินค้า',
        'finalPrice':
            double.tryParse(winner['winning_amount']?.toString() ?? '0') ?? 0,
        'myBid':
            double.tryParse(winner['winning_amount']?.toString() ?? '0') ?? 0,
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
        // ข้อมูลที่อยู่ใหม่
        'winnerVillage': winner['winner_village'] ?? winner['village'] ?? '',
        'winnerRoad': winner['winner_road'] ?? winner['road'] ?? '',
        'winnerPostalCode': winner['winner_postal_code'] ?? winner['postal_code'] ?? '',
        'winnerCountry': winner['winner_country'] ?? winner['country'] ?? 'Thailand',
        'winnerSub': winner['winner_sub'] ?? winner['sub'] ?? '',
        // สร้างที่อยู่เต็มรูปแบบ
        'winnerFullAddress': buildFullAddress(addressData),
        'quotationSequence': winner['quotation_sequence'] ?? '',
        'quotationDescription': winner['quotation_description'] ?? '',
        'shortText': winner['short_text'] ?? '',
        'itemNumber': winner['item_number'] ?? '',
        'quantity': winner['quantity'] ?? '',
        'countUnitId': winner['count_unit_id'] ?? '',
        'description': winner['short_text'] ??
            winner['quotation_description'] ??
            'ไม่มีคำอธิบาย',
        'auction_end_date':
            winner['auction_end_date'] ?? winner['auction_end_time'] ?? '',
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
      return 'ไม่ระบุวันที่';
    }
  }

  // ตรวจสอบว่าผู้ใช้เป็นผู้ชนะหรือไม่
  static bool isUserWinner(Map<String, dynamic> winner, String userId) {
    final winnerBidderId = winner['winner_bidder_id']?.toString() ?? '';
    return winnerBidderId == userId;
  }

  // กรองเฉพาะผู้ชนะของผู้ใช้
  static List<Map<String, dynamic>> filterUserWinners(
      List<Map<String, dynamic>> allWinners, String userId) {
    return allWinners.where((winner) => isUserWinner(winner, userId)).toList();
  }

  // ประกาศผู้ชนะ (เรียบง่าย - ส่งแค่ user_id)
  static Future<Map<String, dynamic>> announceWinner(
      String auctionId, String userId) async {
    try {
      // ส่งแค่ user_id อย่างเดียว
      final Map<String, dynamic> requestBody = {
        'user_id': int.tryParse(userId) ?? 0,
      };

      final response = await http.post(
        Uri.parse('$baseUrl?id=$auctionId&action=announce_winner'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {}
        return data;
      } else {
        throw Exception('Failed to announce winner: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error announcing winner: $e');
    }
  }

  // เช็คและประกาศผู้ชนะอัตโนมัติ (เรียบง่าย)
  static Future<void> checkAndAnnounceWinner(
      String auctionId, String userId) async {
    try {
      print(
          '🔍 TRIGGER: Checking auction $auctionId for winner announcement...');
      print('🔍 TRIGGER: Announced by user: $userId');

      // 1. ดึงข้อมูล auction details จาก API
      final auctionResponse = await http.get(
        Uri.parse('$baseUrl?id=$auctionId&action=get_auction_details'),
      );

      if (auctionResponse.statusCode == 200) {
        final auctionData = jsonDecode(auctionResponse.body);

        if (auctionData['status'] == 'success' && auctionData['data'] != null) {
          final auction = auctionData['data'];
          final endDate = auction['auction_end_date'] ??
              auction['auction_end_time'] ??
              auction['end_date'] ??
              auction['end_time'];

          if (endDate != null && endDate.isNotEmpty) {
            // เช็คว่า auction หมดเวลาหรือยัง
            if (_isAuctionEnded(endDate)) {
              // 2. เช็คว่ามีผู้ชนะแล้วหรือยัง
              final winnerResponse = await http.get(
                Uri.parse('$baseUrl?id=$auctionId&action=get_winner'),
              );

              if (winnerResponse.statusCode == 200) {
                final winnerData = jsonDecode(winnerResponse.body);

                // ถ้ายังไม่มีผู้ชนะ
                if (winnerData['status'] != 'success' ||
                    winnerData['data'] == null) {
                  final result = await announceWinner(auctionId, userId);
                } else {}
              } else {}
            } else {}
          } else {
            // ลองดึงข้อมูลจาก API อื่น
            await _tryAlternativeAuctionDetails(auctionId, userId);
          }
        } else {}
      } else {}
    } catch (e) {}
  }

  // ลองดึงข้อมูล auction จาก API อื่น (เรียบง่าย)
  static Future<void> _tryAlternativeAuctionDetails(
      String auctionId, String userId) async {
    try {
      // ลองดึงข้อมูลจาก quotation API
      final quotationResponse = await http.get(
        Uri.parse('$baseUrl?id=$auctionId&action=get_quotation_details'),
      );

      if (quotationResponse.statusCode == 200) {
        final quotationData = jsonDecode(quotationResponse.body);

        if (quotationData['status'] == 'success' &&
            quotationData['data'] != null) {
          final quotation = quotationData['data'];
          final endDate = quotation['auction_end_date'] ??
              quotation['auction_end_time'] ??
              quotation['end_date'] ??
              quotation['end_time'];

          if (endDate != null && endDate.isNotEmpty) {
            if (_isAuctionEnded(endDate)) {
              // เช็คว่ามีผู้ชนะแล้วหรือยัง
              final winnerResponse = await http.get(
                Uri.parse('$baseUrl?id=$auctionId&action=get_winner'),
              );

              if (winnerResponse.statusCode == 200) {
                final winnerData = jsonDecode(winnerResponse.body);

                if (winnerData['status'] != 'success' ||
                    winnerData['data'] == null) {
                  final result = await announceWinner(auctionId, userId);
                } else {}
              }
            } else {}
          } else {}
        }
      }
    } catch (e) {}
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

      return now.isAfter(endDateTime);
    } catch (e) {
      return false;
    }
  }

  // ฟังก์ชัน trigger ประกาศผู้ชนะโดยตรง (เรียบง่าย - ส่งแค่ user_id)
  static Future<Map<String, dynamic>> triggerAnnounceWinner(
      String auctionId, String userId) async {
    try {
      final url = '$baseUrl?id=$auctionId&action=announce_winner';

      // ส่งแค่ user_id อย่างเดียว
      final Map<String, dynamic> requestBody = {
        'user_id': int.tryParse(userId) ?? 0,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data;
        } else {
          return data;
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
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
      final queryParams = <String, String>{};
      if (quotationMoreInformationId != null) {
        queryParams['quotation_more_information_id'] =
            quotationMoreInformationId;
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

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final logs = data['data'] ?? [];

        return logs;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ฟังก์ชันใหม่: ตรวจสอบว่าประกาศผู้ชนะแล้วหรือยัง
  static Future<bool> isWinnerAnnounced(
      String quotationMoreInformationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?id=$quotationMoreInformationId&action=get_winner'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isAnnounced = data['status'] == 'success' && data['data'] != null;

        return isAnnounced;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ฟังก์ชันใหม่: ดึงข้อมูลผู้ชนะ
  static Future<Map<String, dynamic>?> getWinnerData(
      String quotationMoreInformationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?id=$quotationMoreInformationId&action=get_winner'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return data['data'];
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ฟังก์ชันใหม่: บันทึกข้อมูลผู้ชนะ
  static Future<Map<String, dynamic>> saveWinnerInfo(
      Map<String, dynamic> winnerInfo) async {
    try {
      // แสดงเบอร์โทรศัพท์ที่ทำความสะอาดแล้ว
      final originalPhone = winnerInfo['phone'];
      final cleanPhone =
          originalPhone.toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (originalPhone != cleanPhone) {
        winnerInfo['phone'] = cleanPhone;
      }

      // ตรวจสอบและเพิ่มข้อมูลที่อยู่ที่จำเป็น
      winnerInfo = _validateAndCompleteAddressInfo(winnerInfo);

      final url =
          '${Config.apiUrllocal}/HR-API-morket/login_phone_auction/save_user.php';

      print('🔍 WINNER_SERVICE: Sending data to API: ${jsonEncode(winnerInfo)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(winnerInfo),
      );

      print('🔍 WINNER_SERVICE: API Response Status: ${response.statusCode}');
      print('🔍 WINNER_SERVICE: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          return data;
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving winner information: $e');
    }
  }

  // ฟังก์ชันใหม่: ตรวจสอบและเพิ่มข้อมูลที่อยู่ที่จำเป็น
  static Map<String, dynamic> _validateAndCompleteAddressInfo(
      Map<String, dynamic> winnerInfo) {
    // ตรวจสอบและเพิ่มข้อมูลที่จำเป็น
    winnerInfo['village'] = winnerInfo['village'] ?? '';
    winnerInfo['road'] = winnerInfo['road'] ?? '';
    winnerInfo['postal_code'] = winnerInfo['postal_code'] ?? '';
    winnerInfo['country'] = winnerInfo['country'] ?? 'Thailand';

    // ตรวจสอบและทำความสะอาดรหัสไปรษณีย์
    if (winnerInfo['postal_code'] != null && winnerInfo['postal_code'].toString().isNotEmpty) {
      final postalCode = winnerInfo['postal_code'].toString().trim();
      if (postalCode.length == 5 && int.tryParse(postalCode) != null) {
        winnerInfo['postal_code'] = postalCode;
      } else {
        print('⚠️ WINNER_SERVICE: Invalid postal code format: $postalCode');
      }
    }

    return winnerInfo;
  }

  // ฟังก์ชันใหม่: สร้างที่อยู่เต็มรูปแบบ
  static String buildFullAddress(Map<String, dynamic> customerData) {
    final List<String> addressParts = [];

    // เพิ่มส่วนต่างๆ ของที่อยู่
    if (customerData['addr'] != null && customerData['addr'].toString().isNotEmpty) {
      addressParts.add(customerData['addr'].toString());
    }

    if (customerData['village'] != null && customerData['village'].toString().isNotEmpty) {
      addressParts.add('หมู่ ${customerData['village']}');
    }

    if (customerData['road'] != null && customerData['road'].toString().isNotEmpty) {
      addressParts.add('ถนน${customerData['road']}');
    }

    if (customerData['sub'] != null && customerData['sub'].toString().isNotEmpty) {
      addressParts.add('ซอย ${customerData['sub']}');
    }

    if (customerData['postal_code'] != null && customerData['postal_code'].toString().isNotEmpty) {
      addressParts.add('${customerData['postal_code']}');
    }

    if (customerData['country'] != null && customerData['country'].toString().isNotEmpty) {
      addressParts.add(customerData['country'].toString());
    }

    return addressParts.join(' ');
  }

  // ฟังก์ชันใหม่: ตรวจสอบความถูกต้องของข้อมูลที่อยู่
  static Map<String, String> validateAddressData(Map<String, dynamic> addressData) {
    final Map<String, String> errors = {};

    // ตรวจสอบเบอร์โทรศัพท์
    if (addressData['phone'] == null || addressData['phone'].toString().isEmpty) {
      errors['phone'] = 'กรุณากรอกเบอร์โทรศัพท์';
    } else {
      final phone = addressData['phone'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (phone.length < 9 || phone.length > 10) {
        errors['phone'] = 'เบอร์โทรศัพท์ไม่ถูกต้อง';
      }
    }

    // ตรวจสอบอีเมล
    if (addressData['email'] != null && addressData['email'].toString().isNotEmpty) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(addressData['email'].toString())) {
        errors['email'] = 'รูปแบบอีเมลไม่ถูกต้อง';
      }
    }

    // ตรวจสอบรหัสไปรษณีย์
    if (addressData['postal_code'] != null && addressData['postal_code'].toString().isNotEmpty) {
      final postalCode = addressData['postal_code'].toString().trim();
      if (postalCode.length != 5 || int.tryParse(postalCode) == null) {
        errors['postal_code'] = 'รหัสไปรษณีย์ต้องเป็นตัวเลข 5 หลัก';
      }
    }

    // ตรวจสอบชื่อ-นามสกุล
    if (addressData['fullname'] == null || addressData['fullname'].toString().trim().isEmpty) {
      errors['fullname'] = 'กรุณากรอกชื่อ-นามสกุล';
    }

    return errors;
  }

  // ฟังก์ชันใหม่: สร้างข้อมูลผู้ชนะจาก API response
  static Map<String, dynamic> createWinnerFromApiResponse(Map<String, dynamic> apiData) {
    // สร้างข้อมูลที่อยู่
    final addressData = {
      'addr': apiData['winner_address'] ?? apiData['addr'] ?? '',
      'village': apiData['winner_village'] ?? apiData['village'] ?? '',
      'road': apiData['winner_road'] ?? apiData['road'] ?? '',
      'sub': apiData['winner_sub'] ?? apiData['sub'] ?? '',
      'postal_code': apiData['winner_postal_code'] ?? apiData['postal_code'] ?? '',
      'country': apiData['winner_country'] ?? apiData['country'] ?? 'Thailand',
    };

    return {
      'customer_id': apiData['winner_bidder_id']?.toString() ?? '',
      'fullname': '${apiData['winner_firstname'] ?? ''} ${apiData['winner_lastname'] ?? ''}'.trim(),
      'email': apiData['winner_email'] ?? '',
      'phone': apiData['winner_phone'] ?? '',
      'addr': addressData['addr'],
      'province_id': apiData['winner_province_id'] ?? apiData['province_id'] ?? '',
      'district_id': apiData['winner_district_id'] ?? apiData['district_id'] ?? '',
      'sub_district_id': apiData['winner_sub_district_id'] ?? apiData['sub_district_id'] ?? '',
      'sub': addressData['sub'],
      'type': apiData['winner_type'] ?? apiData['type'] ?? 'individual',
      'company_id': apiData['winner_company_id'] ?? apiData['company_id'] ?? '1',
      'tax_number': apiData['winner_tax_number'] ?? apiData['tax_number'] ?? '',
      'name': apiData['winner_firstname'] ?? '',
      'code': apiData['winner_code'] ?? apiData['code'] ?? '',
      'village': addressData['village'],
      'road': addressData['road'],
      'postal_code': addressData['postal_code'],
      'country': addressData['country'],
      // ข้อมูลเพิ่มเติม
      'winner_id': apiData['winner_id']?.toString() ?? '',
      'auction_id': apiData['quotation_sequence'] ?? '',
      'quotation_id': apiData['quotation_id']?.toString() ?? '',
      'winning_amount': apiData['winning_amount']?.toString() ?? '',
      'winner_announced_time': apiData['winner_announced_time'] ?? '',
      'full_address': buildFullAddress(addressData),
    };
  }

  // ฟังก์ชันใหม่: แปลงข้อมูลผู้ชนะเป็นรูปแบบสำหรับแสดงผล
  static Map<String, dynamic> convertWinnerToDisplayFormat(Map<String, dynamic> winner) {
    final addressData = {
      'addr': winner['winner_address'] ?? winner['addr'] ?? '',
      'village': winner['winner_village'] ?? winner['village'] ?? '',
      'road': winner['winner_road'] ?? winner['road'] ?? '',
      'sub': winner['winner_sub'] ?? winner['sub'] ?? '',
      'postal_code': winner['winner_postal_code'] ?? winner['postal_code'] ?? '',
      'country': winner['winner_country'] ?? winner['country'] ?? 'Thailand',
    };

    return {
      'id': winner['quotation_more_information_id']?.toString() ?? '',
      'title': winner['short_text'] ?? winner['quotation_description'] ?? 'ไม่ระบุชื่อสินค้า',
      'finalPrice': double.tryParse(winner['winning_amount']?.toString() ?? '0') ?? 0,
      'myBid': double.tryParse(winner['winning_amount']?.toString() ?? '0') ?? 0,
      'completedDate': _formatCompletedDate(winner['winner_announced_time']),
      'image': 'assets/images/noimage.jpg',
      'status': 'won',
      'sellerName': 'CloudmateTH',
      'paymentStatus': 'pending',
      // ข้อมูลผู้ชนะ
      'winnerName': '${winner['winner_firstname'] ?? ''} ${winner['winner_lastname'] ?? ''}'.trim(),
      'winnerPhone': winner['winner_phone'] ?? '',
      'winnerEmail': winner['winner_email'] ?? '',
      'winnerAddress': winner['winner_address'] ?? '',
      'winnerVillage': addressData['village'],
      'winnerRoad': addressData['road'],
      'winnerPostalCode': addressData['postal_code'],
      'winnerCountry': addressData['country'],
      'winnerSub': addressData['sub'],
      'winnerFullAddress': buildFullAddress(addressData),
      // ข้อมูลการประมูล
      'auctionId': winner['quotation_sequence'] ?? '',
      'quotationId': winner['quotation_id']?.toString() ?? '',
      'auctionEndTime': winner['auction_end_time'] ?? '',
      'winnerAnnouncedTime': winner['winner_announced_time'] ?? '',
      'description': winner['short_text'] ?? winner['quotation_description'] ?? 'ไม่มีคำอธิบาย',
    };
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
    String village = '',
    String road = '',
    String postalCode = '',
    String country = 'Thailand',
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
      'village': village,
      'road': road,
      'postal_code': postalCode,
      'country': country,
    };
  }
}
