import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:e_auction/views/config/config_prod.dart';

class WinnerService {
  static String get baseUrl {
    final url = '${Config.apiUrlAuction}/${Config.erpCloudmate}/modules/sales/controllers/list_quotation_type_auction_price_controller.php';
    if (Platform.isAndroid) {
      return url.replaceFirst('https://', 'http://');
    }
    return url;
  }
  
  static String get logsBaseUrl {
    final url = '${Config.apiUrlAuction}/${Config.erpCloudmate}/modules/sales/controllers/auction_announcement_logs_controller.php';
    if (Platform.isAndroid) {
      return url.replaceFirst('https://', 'http://');
    }
    return url;
  }

  static http.Client _getHttpClient() {
    if (Platform.isAndroid) {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true; // ยอมรับ certificate ทั้งหมด
      };
      return IOClient(client);
    } else {
      return http.Client();
    }
  }

  // ดึงข้อมูลผู้ชนะของแต่ละการประมูล
  static Future<Map<String, dynamic>> getWinnerByAuctionId(
      String auctionId) async {
    try {
      final client = _getHttpClient();
      final response = await client.get(
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
      final client = _getHttpClient();
      final response = await client.get(
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
      final client = _getHttpClient();
      final response = await client.get(
        Uri.parse('$baseUrl?action=get_all_winners'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ถ้า API ส่งกลับมาเป็น List โดยตรง ให้ wrap เป็น Map
        if (data is List) {
          return {
            'status': 'success',
            'data': data,
          };
        }
        
        // ถ้าเป็น Map อยู่แล้ว ให้ return ตามเดิม
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

      print('📤 ANNOUNCE: Sending request to announce winner for auction $auctionId');
      print('📤 ANNOUNCE: Request body: ${jsonEncode(requestBody)}');

      final client = _getHttpClient();
      final response = await client.post(
        Uri.parse('$baseUrl?id=$auctionId&action=announce_winner'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 ANNOUNCE: Response status: ${response.statusCode}');
      print('📥 ANNOUNCE: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          print('✅ ANNOUNCE: Winner announced successfully for auction $auctionId');
        } else {
          print('⚠️ ANNOUNCE: API returned non-success status: ${data['status']}');
          print('⚠️ ANNOUNCE: Message: ${data['message'] ?? 'No message'}');
        }
        return data;
      } else {
        // พยายาม parse error message จาก response
        String errorMessage = 'Failed to announce winner: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
          print('❌ ANNOUNCE: Error message from API: $errorMessage');
        } catch (e) {
          print('❌ ANNOUNCE: Could not parse error response: ${response.body}');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ ANNOUNCE: Exception occurred: $e');
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
      final client = _getHttpClient();
      final auctionResponse = await client.get(
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
              print('✅ TRIGGER: Auction $auctionId has ended, checking for winner...');
              // 2. เช็คว่ามีผู้ชนะแล้วหรือยัง
              final winnerResponse = await client.get(
                Uri.parse('$baseUrl?id=$auctionId&action=get_winner'),
              );

              if (winnerResponse.statusCode == 200) {
                final winnerData = jsonDecode(winnerResponse.body);

                // ถ้ายังไม่มีผู้ชนะ
                if (winnerData['status'] != 'success' ||
                    winnerData['data'] == null) {
                  print('📢 TRIGGER: No winner announced yet, announcing now...');
                  final result = await announceWinner(auctionId, userId);
                  if (result['status'] == 'success') {
                    print('✅ TRIGGER: Winner announced successfully for auction $auctionId');
                  } else {
                    print('⚠️ TRIGGER: Failed to announce winner: ${result['message'] ?? 'Unknown error'}');
                  }
                } else {
                  print('ℹ️ TRIGGER: Winner already announced for auction $auctionId');
                }
              } else {
                print('❌ TRIGGER: Failed to check winner status: ${winnerResponse.statusCode}');
              }
            } else {
              print('ℹ️ TRIGGER: Auction $auctionId has not ended yet');
            }
          } else {
            print('⚠️ TRIGGER: No end date found, trying alternative API...');
            // ลองดึงข้อมูลจาก API อื่น
            await _tryAlternativeAuctionDetails(auctionId, userId);
          }
        } else {
          print('❌ TRIGGER: Failed to get auction details: ${auctionData['message'] ?? 'Unknown error'}');
        }
      } else {
        print('❌ TRIGGER: Failed to fetch auction details: ${auctionResponse.statusCode}');
      }
    } catch (e) {
      print('❌ TRIGGER: Error in checkAndAnnounceWinner: $e');
    }
  }

  // ลองดึงข้อมูล auction จาก API อื่น (เรียบง่าย)
  static Future<void> _tryAlternativeAuctionDetails(
      String auctionId, String userId) async {
    try {
      // ลองดึงข้อมูลจาก quotation API
      final client = _getHttpClient();
      final quotationResponse = await client.get(
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
              print('✅ TRIGGER: Auction $auctionId has ended (from alternative API), checking for winner...');
              // เช็คว่ามีผู้ชนะแล้วหรือยัง
              final winnerResponse = await client.get(
                Uri.parse('$baseUrl?id=$auctionId&action=get_winner'),
              );

              if (winnerResponse.statusCode == 200) {
                final winnerData = jsonDecode(winnerResponse.body);

                if (winnerData['status'] != 'success' ||
                    winnerData['data'] == null) {
                  print('📢 TRIGGER: No winner announced yet, announcing now...');
                  final result = await announceWinner(auctionId, userId);
                  if (result['status'] == 'success') {
                    print('✅ TRIGGER: Winner announced successfully for auction $auctionId');
                  } else {
                    print('⚠️ TRIGGER: Failed to announce winner: ${result['message'] ?? 'Unknown error'}');
                  }
                } else {
                  print('ℹ️ TRIGGER: Winner already announced for auction $auctionId');
                }
              } else {
                print('❌ TRIGGER: Failed to check winner status: ${winnerResponse.statusCode}');
              }
            } else {
              print('ℹ️ TRIGGER: Auction $auctionId has not ended yet (from alternative API)');
            }
          } else {
            print('⚠️ TRIGGER: No end date found in alternative API either');
          }
        } else {
          print('❌ TRIGGER: Failed to get quotation details: ${quotationData['message'] ?? 'Unknown error'}');
        }
      } else {
        print('❌ TRIGGER: Failed to fetch quotation details: ${quotationResponse.statusCode}');
      }
    } catch (e) {
      print('❌ TRIGGER: Error in _tryAlternativeAuctionDetails: $e');
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

      print('📤 TRIGGER: Sending request to announce winner for auction $auctionId');
      print('📤 TRIGGER: User ID: $userId');
      print('📤 TRIGGER: Request body: ${jsonEncode(requestBody)}');
      print('📤 TRIGGER: URL: $url');

      final client = _getHttpClient();
      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 TRIGGER: Response status: ${response.statusCode}');
      print('📥 TRIGGER: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('✅ TRIGGER: Winner announced successfully for auction $auctionId');
          return data;
        } else {
          print('⚠️ TRIGGER: API returned non-success status: ${data['status']}');
          print('⚠️ TRIGGER: Message: ${data['message'] ?? data['error'] ?? 'No message'}');
          return data;
        }
      } else {
        // พยายาม parse error message จาก response
        String errorMessage = 'HTTP Error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
          print('❌ TRIGGER: Error message from API: $errorMessage');
        } catch (e) {
          print('❌ TRIGGER: Could not parse error response: ${response.body}');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ TRIGGER: Exception occurred: $e');
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

      final client = _getHttpClient();
      final response = await client.get(uri);

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
      final client = _getHttpClient();
      final response = await client.get(
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
      final client = _getHttpClient();
      final response = await client.get(
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
          '${Config.apiUrl}/HR-API-morket/login_phone_auction/save_user.php';

      print('🔍 WINNER_SERVICE: Sending data to API: ${jsonEncode(winnerInfo)}');

      final client = _getHttpClient();
      final response = await client.post(
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

  // ฟังก์ชันใหม่: ดึงข้อมูล auction ที่หมดเวลาแล้วแต่ยังไม่ประกาศผู้ชนะ (เฉพาะที่มี bid)
  static Future<List<Map<String, dynamic>>> getEndedAuctionsWithoutWinner() async {
    try {
      print('🔍 ADMIN: Fetching ended auctions without winner (with bids only)...');
      
      final client = _getHttpClient();
      final response = await client.get(
        Uri.parse('$baseUrl?action=get_all_auctions'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> auctions = [];
        
        // จัดการ response format ที่แตกต่างกัน
        if (data is List) {
          auctions = data;
        } else if (data is Map<String, dynamic> && data['data'] != null) {
          if (data['data'] is List) {
            auctions = data['data'];
          }
        }

        if (auctions.isEmpty) {
          return [];
        }

        List<Map<String, dynamic>> endedAuctions = [];

        // กรองเฉพาะ auction ที่หมดเวลาแล้ว
        for (final auction in auctions) {
          try {
            final auctionId = auction['quotation_more_information_id']?.toString() ?? 
                             auction['quotation_sequence']?.toString() ?? 
                             auction['id']?.toString() ?? '';
            
            if (auctionId.isEmpty) {
              continue;
            }

            final endDateStr = auction['auction_end_date']?.toString() ?? 
                              auction['auction_end_time']?.toString() ?? '';
            
            if (endDateStr.isEmpty) {
              continue;
            }

            // เช็คว่า auction หมดเวลาหรือยัง
            if (!_isAuctionEnded(endDateStr)) {
              continue;
            }

            // เช็คว่ามีผู้ชนะแล้วหรือยัง
            final isAlreadyAnnounced = await isWinnerAnnounced(auctionId);
            
            if (isAlreadyAnnounced) {
              continue;
            }

            // เช็คว่า auction มี bid หรือไม่ (ใช้ข้อมูลจาก auction object ก่อน)
            // เช็คจาก field ที่มีใน auction object
            final totalBids = auction['total_bids'] ?? auction['number_bids'] ?? 0;
            final numberBidders = auction['number_bidders'] ?? auction['total_bidders'] ?? 0;
            final hasBidFromData = (totalBids is num && totalBids > 0) || 
                                  (numberBidders is num && numberBidders > 0);

            // ถ้าไม่มี bid จากข้อมูล ให้เช็คจาก API
            bool hasBid = hasBidFromData;
            if (!hasBidFromData) {
              hasBid = await hasBids(auctionId);
            }

            // ถ้าไม่มี bid ให้ skip
            if (!hasBid) {
          
              continue;
            }

            // แปลงข้อมูลเป็นรูปแบบที่ใช้ในแอป
            final auctionData = {
              'id': auctionId,
              'quotation_more_information_id': auctionId,
              'quotation_sequence': auction['quotation_sequence'] ?? auctionId,
              'quotation_id': auction['quotation_id']?.toString() ?? '',
              'short_text': auction['short_text'] ?? '',
              'quotation_description': auction['quotation_description'] ?? '',
              'auction_end_date': endDateStr,
              'auction_end_time': endDateStr,
              'quotation_image': auction['quotation_image'],
              'quantity': auction['quantity'] ?? '1',
              'item_number': auction['item_number'] ?? '',
              'total_bids': totalBids,
              'number_bidders': numberBidders,
            };
            
            endedAuctions.add(auctionData);
          } catch (e) {
            print('❌ ADMIN: Error processing auction: $e');
            continue;
          }
        }

        print('✅ ADMIN: Found ${endedAuctions.length} ended auctions without winner (with bids)');
        return endedAuctions;
      } else {
        print('❌ ADMIN: Failed to fetch auctions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ ADMIN: Error in getEndedAuctionsWithoutWinner: $e');
      return [];
    }
  }

  // ฟังก์ชันใหม่: เช็คว่า auction มี bid หรือไม่
  static Future<bool> hasBids(String auctionId) async {
    try {
      final client = _getHttpClient();
      final response = await client.get(
        Uri.parse('$baseUrl?id=$auctionId&action=get_bids'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final bids = data['data'] ?? data['bids'] ?? [];
          return bids is List && bids.isNotEmpty;
        } else if (data is List) {
          return data.isNotEmpty;
        }
      }
      return false;
    } catch (e) {
      print('⚠️ ADMIN: Could not check bids for auction $auctionId: $e');
      // สำหรับ admin page ถ้าเช็คไม่ได้ให้ return false (ไม่แสดง)
      return false;
    }
  }

  // ฟังก์ชันใหม่: เช็คและประกาศผู้ชนะสำหรับ auction ทั้งหมดที่หมดเวลาแล้ว
  static Future<void> checkAndAnnounceAllEndedAuctions(String userId) async {
    try {
      print('🔍 AUTO: Starting to check all ended auctions for winner announcement...');
      
      // ดึงข้อมูล auction ทั้งหมด
      final client = _getHttpClient();
      final response = await client.get(
        Uri.parse('$baseUrl?action=get_all_auctions'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> auctions = [];
        
        // จัดการ response format ที่แตกต่างกัน
        if (data is List) {
          auctions = data;
        } else if (data is Map<String, dynamic> && data['data'] != null) {
          if (data['data'] is List) {
            auctions = data['data'];
          }
        }

        if (auctions.isEmpty) {
          print('ℹ️ AUTO: No auctions found');
          return;
        }

        print('📋 AUTO: Found ${auctions.length} auctions to check');

        int checkedCount = 0;
        int announcedCount = 0;
        int skippedCount = 0;
        int errorCount = 0;

        // กรองเฉพาะ auction ที่หมดเวลาแล้ว
        for (final auction in auctions) {
          try {
            final auctionId = auction['quotation_more_information_id']?.toString() ?? 
                             auction['quotation_sequence']?.toString() ?? 
                             auction['id']?.toString() ?? '';
            
            if (auctionId.isEmpty) {
              continue;
            }

            final endDateStr = auction['auction_end_date']?.toString() ?? 
                              auction['auction_end_time']?.toString() ?? '';
            
            if (endDateStr.isEmpty) {
              continue;
            }

            // เช็คว่า auction หมดเวลาหรือยัง
            if (!_isAuctionEnded(endDateStr)) {
              continue;
            }

            checkedCount++;
            print('🔍 AUTO: Checking auction $auctionId (ended: $endDateStr)');

            // เช็คว่ามีผู้ชนะแล้วหรือยัง
            final isAlreadyAnnounced = await isWinnerAnnounced(auctionId);
            
            if (isAlreadyAnnounced) {
              print('ℹ️ AUTO: Winner already announced for auction $auctionId');
              continue;
            }

            // เช็คว่า auction มี bid หรือไม่ (ถ้าไม่มี bid ก็ไม่สามารถประกาศผู้ชนะได้)
            final hasBid = await hasBids(auctionId);
            if (!hasBid) {
              skippedCount++;
              print('⏭️ AUTO: Skipping auction $auctionId - no bids found');
              continue;
            }

            print('📢 AUTO: No winner announced for auction $auctionId, announcing now...');
            
            try {
              final result = await announceWinner(auctionId, userId);
              
              if (result['status'] == 'success') {
                announcedCount++;
                print('✅ AUTO: Winner announced successfully for auction $auctionId');
              } else {
                errorCount++;
                final errorMsg = result['message'] ?? result['error'] ?? 'Unknown error';
                print('⚠️ AUTO: Failed to announce winner for auction $auctionId: $errorMsg');
                
                // ถ้า error เป็นเพราะไม่มีผู้ชนะหรือไม่มี bid ให้ skip
                if (errorMsg.toString().toLowerCase().contains('no bid') || 
                    errorMsg.toString().toLowerCase().contains('no winner') ||
                    errorMsg.toString().toLowerCase().contains('no bidder')) {
                  skippedCount++;
                  continue;
                }
              }
            } catch (e) {
              errorCount++;
              print('❌ AUTO: Error announcing winner for auction $auctionId: $e');
              
              // ถ้า error เป็น 500 อาจเป็นเพราะไม่มี bid หรือไม่มีผู้ชนะ
              if (e.toString().contains('500')) {
                skippedCount++;
                print('⏭️ AUTO: Skipping auction $auctionId due to 500 error (likely no bids/winner)');
              }
            }
            
            // หน่วงเวลาเพื่อไม่ให้ส่ง request มากเกินไป (เพิ่มเป็น 1 วินาที)
            await Future.delayed(Duration(seconds: 1));
          } catch (e) {
            errorCount++;
            print('❌ AUTO: Error processing auction: $e');
            continue;
          }
        }

        print('✅ AUTO: Summary - Checked: $checkedCount, Announced: $announcedCount, Skipped: $skippedCount, Errors: $errorCount');
      } else {
        print('❌ AUTO: Failed to fetch auctions: ${response.statusCode}');
        
        // ลองใช้ API อื่น
        await _tryGetAuctionsFromAlternativeApi(userId);
      }
    } catch (e) {
      print('❌ AUTO: Error in checkAndAnnounceAllEndedAuctions: $e');
    }
  }

  // ฟังก์ชันช่วย: ลองดึงข้อมูล auction จาก API อื่น
  static Future<void> _tryGetAuctionsFromAlternativeApi(String userId) async {
    try {
      print('🔄 AUTO: Trying alternative API to get auctions...');
      
      final client = _getHttpClient();
      // ลองใช้ API ที่ดึงข้อมูล quotation ทั้งหมด
      final response = await client.get(
        Uri.parse('$baseUrl?action=get_all_quotations'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> quotations = [];
        
        if (data is List) {
          quotations = data;
        } else if (data is Map<String, dynamic> && data['data'] != null) {
          if (data['data'] is List) {
            quotations = data['data'];
          }
        }

        // กรองเฉพาะ auction ที่หมดเวลาแล้ว
        int checkedCount = 0;
        int announcedCount = 0;

        for (final quotation in quotations) {
          try {
            final quotationId = quotation['quotation_more_information_id']?.toString() ?? 
                               quotation['quotation_sequence']?.toString() ?? '';
            
            if (quotationId.isEmpty) {
              continue;
            }

            final endDateStr = quotation['auction_end_date']?.toString() ?? 
                              quotation['auction_end_time']?.toString() ?? '';
            
            if (endDateStr.isEmpty) {
              continue;
            }

            if (!_isAuctionEnded(endDateStr)) {
              continue;
            }

            checkedCount++;
            
            final isAlreadyAnnounced = await isWinnerAnnounced(quotationId);
            
            if (!isAlreadyAnnounced) {
              try {
                final result = await announceWinner(quotationId, userId);
                
                if (result['status'] == 'success') {
                  announcedCount++;
                }
              } catch (e) {
                // Continue to next auction
              }
              
              await Future.delayed(Duration(milliseconds: 500));
            }
          } catch (e) {
            continue;
          }
        }

        print('✅ AUTO: Checked $checkedCount ended auctions from alternative API, announced $announcedCount winners');
      }
    } catch (e) {
      print('❌ AUTO: Error in _tryGetAuctionsFromAlternativeApi: $e');
    }
  }
}
