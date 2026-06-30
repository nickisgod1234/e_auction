import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:e_auction/utils/format.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/services/product_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:e_auction/views/first_page/widgets/auction_image_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:e_auction/noti_ios/noti_ios.dart';

class QuantityReductionAuctionDetailPage extends StatefulWidget {
  final Map<String, dynamic> auctionData;

  QuantityReductionAuctionDetailPage({super.key, required this.auctionData});

  @override
  _QuantityReductionAuctionDetailPageState createState() => _QuantityReductionAuctionDetailPageState();
}

class _QuantityReductionAuctionDetailPageState extends State<QuantityReductionAuctionDetailPage> {
  Map<String, dynamic>? _latestAuctionData;
  bool _isJoining = false;
  bool _hasJoined = false;
  late ProductService _productService;
  
  // เพิ่มตัวแปรสำหรับ countdown
  bool _isCountdownActive = false;
  int _countdownSeconds = 15;
  Timer? _countdownTimer;
  int? _pendingBookingQuantity;

  // Image gallery state
  int _selectedImageIndex = 0;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _productService = ProductService(baseUrl: Config.apiUrlAuction);
    _parseImages();
    _checkIfUserHasJoined();
    // โหลดข้อมูลทันทีเมื่อเปิดหน้า
    _loadLatestData();
    print('DEBUG: initState - Loading latest data for AS03');
  }

  @override
  void dispose() {
    super.dispose();
    _countdownTimer?.cancel();
  }

  // Parse images from auctionData
  void _parseImages() {
    _imageUrls = [];
    
    // ใช้ข้อมูลจาก _latestAuctionData ถ้ามี (ข้อมูลล่าสุด) หรือ widget.auctionData (ข้อมูลเริ่มต้น)
    final dataSource = _latestAuctionData ?? widget.auctionData;
    
    // ใช้ images array ที่ parse แล้วจาก product_service
    if (dataSource['images'] != null && dataSource['images'] is List) {
      final imagesList = dataSource['images'] as List;
      if (imagesList.isNotEmpty) {
        for (var img in imagesList) {
          if (img != null && img.toString().isNotEmpty) {
            _imageUrls.add(img.toString());
          }
        }
      }
    }
    
    // ถ้ายังไม่มีรูป ให้ใช้ image เดียว (backward compatibility)
    if (_imageUrls.isEmpty && dataSource['image'] != null) {
      final singleImage = dataSource['image'].toString();
      if (singleImage.isNotEmpty && singleImage != 'assets/images/noimage.jpg') {
        _imageUrls.add(singleImage);
      }
    }
    
    // ถ้ายังไม่มีรูปเลย ให้ parse จาก quotation_image (fallback)
    if (_imageUrls.isEmpty) {
      final quotationImage = dataSource['quotation_image'];
      if (quotationImage != null) {
        try {
          String imageData = quotationImage.toString().trim();
          
          // ลบ quotes นอกสุดถ้ามี (สำหรับกรณี "[\"img.jpg\"]")
          if (imageData.startsWith('"') && imageData.endsWith('"')) {
            imageData = imageData.substring(1, imageData.length - 1);
            // Unescape backslashes
            imageData = imageData.replaceAll('\\"', '"').replaceAll('\\\\', '\\');
          }
          
          // ถ้าเป็น JSON array string ให้ parse
          if (imageData.startsWith('[') && imageData.endsWith(']')) {
            // ลอง parse หลายครั้งในกรณีที่ double encoded
            dynamic parsed = imageData;
            for (int i = 0; i < 3; i++) {
              try {
                if (parsed is String) {
                  parsed = jsonDecode(parsed);
                } else {
                  break;
                }
              } catch (e) {
                break;
              }
            }
            
            if (parsed is List && parsed.isNotEmpty) {
              for (var img in parsed) {
                if (img != null && img.toString().isNotEmpty) {
                  // Clean the image name
                  String imgName = img.toString()
                      .replaceAll('"', '')
                      .replaceAll('\\', '')
                      .trim();
                  if (imgName.isNotEmpty) {
                    _imageUrls.add(_buildImageUrl(imgName));
                  }
                }
              }
            }
          } else if (imageData.isNotEmpty && 
                     imageData != '[]' && 
                     imageData != '"[]"') {
            // ถ้าเป็น string เดียว
            imageData = imageData
                .replaceAll('"', '')
                .replaceAll('\\', '')
                .trim();
            
            if (imageData.isNotEmpty) {
              _imageUrls.add(_buildImageUrl(imageData));
            }
          }
        } catch (e) {
          print('Error parsing images in quantity_reduction_auction_detail_page: $e');
        }
      }
    }
    
    // ถ้ายังไม่มีรูปเลย ให้ใช้ noimage.jpg
    if (_imageUrls.isEmpty) {
      _imageUrls.add('assets/images/noimage.jpg');
    }
  }
  
  // Build image URL from image name
  String _buildImageUrl(String imageName) {
    if (imageName.isEmpty || 
        imageName == '[]' || 
        imageName == 'assets/images/noimage.jpg' ||
        imageName.startsWith('http://') ||
        imageName.startsWith('https://') ||
        imageName.startsWith('assets/')) {
      return imageName;
    }
    
    // Check if it's a valid image extension
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final hasValidExtension = validExtensions.any((ext) => 
        imageName.toLowerCase().endsWith(ext));
    
    if (!hasValidExtension) {
      return 'assets/images/noimage.jpg';
    }
    
    // Build full URL
    String baseUrl = 'https://cm-mecustomers.com/${Config.erpCloudmate}/modules/sales/uploads/quotation/$imageName';
    
    // Convert to HTTP for Android
    if (Platform.isAndroid) {
      baseUrl = baseUrl.replaceFirst('https://', 'http://');
    }
    
    return baseUrl;
  }

  Future<void> _loadLatestData() async {
    try {
      final quotationId = widget.auctionData['quotation_more_information_id']?.toString() ??
          widget.auctionData['id'].toString();
      
      // ใช้ ProductService ในการโหลดข้อมูลใหม่
      final allQuotations = await _productService.getAllQuotations();
      if (allQuotations != null) {
        // หา quotation ที่ตรงกับ ID
        final targetQuotation = allQuotations.firstWhere(
          (quotation) => quotation['quotation_more_information_id'] == quotationId,
          orElse: () => {},
        );
        
        if (targetQuotation.isNotEmpty) {
          // เรียก API bid history แยก
          final bidHistoryData = await _loadBidHistory(quotationId);
          
          setState(() {
            _latestAuctionData = targetQuotation;
            // เพิ่ม bid_history จาก API แยก
            if (bidHistoryData != null) {
              _latestAuctionData!['bid_history'] = bidHistoryData;
            }
            // Parse images ใหม่เมื่อโหลดข้อมูลล่าสุด
            _parseImages();
          });
          print('DEBUG: _loadLatestData - Loaded data from ProductService: $_latestAuctionData');
        } else {
          print('DEBUG: Quotation not found with ID: $quotationId');
        }
      } else {
        print('DEBUG: Failed to load quotations from ProductService');
      }
    } catch (e) {
      print('DEBUG: Error loading latest data: $e');
    }
  }

  Future<List<dynamic>?> _loadBidHistory(String quotationId) async {
    try {
      final url = '${_getBaseUrl()}/${Config.erpCloudmate}/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=$quotationId&action=bid_history';
      
      print('DEBUG: Calling bid history API: $url');
      final response = await _getHttpClient().get(Uri.parse(url));
      
      print('DEBUG: Bid history response status: ${response.statusCode}');
      print('DEBUG: Bid history response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Bid History API Response: $data');
        
        if (data is List) {
          print('DEBUG: Bid history is List with ${data.length} items');
          return data;
        }
      }
    } catch (e) {
      print('DEBUG: Error loading bid history: $e');
    }
    return null;
  }

  Future<void> _checkIfUserHasJoined() async {
    // ตรวจสอบว่าผู้ใช้เคยจองไปแล้วหรือไม่ (เพื่อแสดงจำนวนที่จองไปแล้ว)
    // แต่ไม่ disable ปุ่ม เพราะสามารถจองเพิ่มได้หลายครั้ง
    final prefs = await SharedPreferences.getInstance();
    final quotationId = widget.auctionData['quotation_more_information_id']?.toString() ?? 
                       widget.auctionData['id'].toString();
    
    // ตรวจสอบจาก SharedPreferences หรือ API
    final joinedAuctions = prefs.getStringList('joined_quantity_reduction_auctions') ?? [];
    
    setState(() {
      // ตั้งค่า _hasJoined เพื่อแสดงจำนวนที่จองไปแล้ว แต่ไม่ disable ปุ่ม
      _hasJoined = joinedAuctions.contains(quotationId);
    });
  }

  Future<void> _joinAuction(int quantity) async {
    setState(() {
      _isJoining = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final quotationId = widget.auctionData['quotation_more_information_id']?.toString() ?? 
                         widget.auctionData['id'].toString();
      final userId = prefs.getString('id') ?? '';
      // ใช้ 'phone_number' แทน 'phone' เพราะ UserDataManager เก็บด้วย key 'phone_number'
      final phoneNumber = prefs.getString('phone_number') ?? '';
      
      if (phoneNumber.isEmpty) {
        print('WARNING: Phone number is empty from SharedPreferences');
      }
      
      // ตรวจสอบว่าเป็น AS03 หรือไม่
      final typeCode = widget.auctionData['quotation_type_code'];
      if (typeCode == 'AS03') {
        // ส่ง POST request ไปยัง API สำหรับการจอง (ใช้ action=place_bid)
        final client = _getHttpClient();
        final baseUrl = _getBaseUrl();
        final currentPrice = _latestAuctionData?['current_price'] ?? widget.auctionData['currentPrice'] ?? 500;
        
        final apiUrl = '$baseUrl/${Config.erpCloudmate}/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=$quotationId&action=place_bid';
        
        print('DEBUG: Sending booking request to: $apiUrl');
        print('DEBUG: User ID: $userId');
        print('DEBUG: Phone Number: $phoneNumber');
        print('DEBUG: Request body: {"bidder_id": $userId, "bidder_name": "$phoneNumber", "bid_amount": $currentPrice, "quantity_requested": $quantity}');
        
        final response = await client.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'bidder_id': int.tryParse(userId) ?? 0,
            'bidder_name': phoneNumber,
            'bid_amount': double.tryParse(currentPrice.toString()) ?? 500.0,
            'quantity_requested': quantity,
          }),
        );

        print('DEBUG: Response status: ${response.statusCode}');
        print('DEBUG: Response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('DEBUG: Booking response: $responseData');
          
          // Response structure: {status: 'success', data: {auction: {...}, bidder: {...}}}
          if (responseData is Map && responseData['status'] == 'success') {
            final data = responseData['data'];
            if (data is Map && data.containsKey('auction')) {
              final auctionData = data['auction'];
              
              // อัปเดตข้อมูลจาก response
              setState(() {
                _latestAuctionData = Map<String, dynamic>.from(auctionData);
              });
              
              // อัปเดตข้อมูลจาก API เพื่อให้ข้อมูลเป็นปัจจุบัน (รวม bid_history)
              await _loadLatestData();
              
              // เพิ่มการเข้าร่วมใน SharedPreferences (เพื่อแสดงว่าจองไปแล้ว)
              final joinedAuctions = prefs.getStringList('joined_quantity_reduction_auctions') ?? [];
              if (!joinedAuctions.contains(quotationId)) {
                joinedAuctions.add(quotationId);
                await prefs.setStringList('joined_quantity_reduction_auctions', joinedAuctions);
              }
              // ไม่ต้องบันทึก booked_quantity เพราะจะคำนวณจาก bid_history แทน

              setState(() {
                _hasJoined = true; // ตั้งค่าเพื่อแสดงจำนวนที่จองไปแล้ว แต่ไม่ disable ปุ่ม
                _isJoining = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('จองสินค้าสำเร็จ! จำนวน: $quantity รายการ'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              throw Exception('Invalid response structure: missing auction data');
            }
          } else if (responseData is Map && responseData['status'] == 'error') {
            throw Exception('Booking failed: ${responseData['message'] ?? 'Unknown error'}');
          } else {
            // Fallback: ถ้า response เป็นรูปแบบเก่า (มี quotation_more_information_id โดยตรง)
            if (responseData is Map && responseData.containsKey('quotation_more_information_id')) {
              setState(() {
                _latestAuctionData = Map<String, dynamic>.from(responseData);
              });
              await _loadLatestData();
              
              final joinedAuctions = prefs.getStringList('joined_quantity_reduction_auctions') ?? [];
              if (!joinedAuctions.contains(quotationId)) {
                joinedAuctions.add(quotationId);
                await prefs.setStringList('joined_quantity_reduction_auctions', joinedAuctions);
              }
              await prefs.setInt('booked_quantity_${quotationId}', quantity);

              setState(() {
                _hasJoined = true;
                _isJoining = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('จองสินค้าสำเร็จ! จำนวน: $quantity รายการ'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              throw Exception('Invalid response structure: ${response.body}');
            }
          }
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } else {
        // สำหรับ auction types อื่นๆ ใช้ logic เดิม
        // เพิ่มการเข้าร่วมใน SharedPreferences
        final joinedAuctions = prefs.getStringList('joined_quantity_reduction_auctions') ?? [];
        if (!joinedAuctions.contains(quotationId)) {
          joinedAuctions.add(quotationId);
          await prefs.setStringList('joined_quantity_reduction_auctions', joinedAuctions);
        }

        // ตั้งค่าจำนวนสินค้าเริ่มต้น
        final initialQuantity = widget.auctionData['quantity'] ?? 0;
        await prefs.setInt('quantity_${quotationId}', initialQuantity);
        await prefs.setInt('booked_quantity_${quotationId}', quantity);

        setState(() {
          _hasJoined = true;
          _isJoining = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('จองสินค้าสำเร็จ! จำนวน: $quantity รายการ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isJoining = false;
      });
      
      print('DEBUG: Booking error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('รีเซทการเข้าร่วม'),
        content: Text('คุณต้องการรีเซทการเข้าร่วมการประมูลนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetAuctionParticipation();
            },
            child: Text('รีเซท'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAuctionParticipation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quotationId = widget.auctionData['quotation_more_information_id']?.toString() ?? 
                         widget.auctionData['id'].toString();
      
      // ลบการเข้าร่วมจาก SharedPreferences
      final joinedAuctions = prefs.getStringList('joined_quantity_reduction_auctions') ?? [];
      joinedAuctions.remove(quotationId);
      await prefs.setStringList('joined_quantity_reduction_auctions', joinedAuctions);
      
      // ลบข้อมูลจำนวนสินค้า
      await prefs.remove('quantity_${quotationId}');
      await prefs.remove('booked_quantity_${quotationId}');

      setState(() {
        _hasJoined = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('รีเซทการจองสำเร็จ'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // แสดง Custom Toast Message
  void _showCustomToast(BuildContext context, String message, {bool isSuccess = true}) {
    if (!mounted) return;
    try {
      final overlay = Overlay.of(context, rootOverlay: true);
      if (overlay == null) return;
      final overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isSuccess ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle : Icons.error,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      overlay.insert(overlayEntry);
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          overlayEntry.remove();
        }
      });
    } catch (e) {
      // ป้องกันแอป crash เงียบๆ
    }
  }



  // ส่งแจ้งเตือนเมื่อเข้าร่วมสำเร็จ
  Future<void> _sendJoinNotification() async {
    try {
      final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await plugin.initialize(initializationSettings);
      
      await sendQuantityReductionJoinNotification(
        plugin,
        widget.auctionData['title'] ?? 'สินค้า',
        widget.auctionData['quantity']?.toString() ?? '0',
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Helper method to get HTTP client for Android/iOS
  http.Client _getHttpClient() {
    if (Platform.isAndroid) {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true; // Accept all certificates
      };
      return IOClient(client);
    } else {
      return http.Client();
    }
  }

  // Helper method to get base URL for Android/iOS
  String _getBaseUrl() {
    // ใช้ production URL สำหรับ auction API
    final url = Config.apiUrlAuction;
    if (Platform.isAndroid) {
      // สำหรับ Android ใช้ http แทน https
      return url.replaceFirst('https://', 'http://');
    }
    return url;
  }

  // Helper method to parse any value to double
  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int? _safeToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // ลบ whitespace และ quotes
      final cleanValue = value.trim().replaceAll('"', '').replaceAll("'", '');
      print('DEBUG: _safeToInt - Original: "$value", Cleaned: "$cleanValue"');
      return int.tryParse(cleanValue);
    }
    return null;
  }

  String _formatBidTime(String bidTime) {
    try {
      final dateTime = DateTime.parse(bidTime);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds} วินาทีที่ผ่านมา';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} นาทีที่ผ่านมา';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ชั่วโมงที่ผ่านมา';
      } else {
        return '${difference.inDays} วันที่ผ่านมา';
      }
    } catch (e) {
      return bidTime; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    // แปลงข้อมูลให้เป็น type ที่ถูกต้อง
    final currentPriceRaw = _latestAuctionData?['current_price'] ?? widget.auctionData['currentPrice'] ?? 0;
    final startingPriceRaw = _latestAuctionData?['star_price'] ?? widget.auctionData['startingPrice'] ?? 0;
    
    // ใช้ข้อมูลจาก ProductService
    int maxQuantity, currentQuantitySold, remainingQuantity;
    
    if (_latestAuctionData != null) {
      // ใช้ข้อมูลจาก ProductService
      maxQuantity = _safeToInt(_latestAuctionData!['max_quantity_available']) ?? 
                   _safeToInt(widget.auctionData['quantity']) ?? 0;
      currentQuantitySold = _safeToInt(_latestAuctionData!['current_quantity_sold']) ?? 0;
      remainingQuantity = maxQuantity - currentQuantitySold;
      
      print('DEBUG: ProductService Data - max_quantity_available: ${_latestAuctionData!['max_quantity_available']}, current_quantity_sold: ${_latestAuctionData!['current_quantity_sold']}');
      print('DEBUG: Calculated - maxQuantity: $maxQuantity, currentQuantitySold: $currentQuantitySold, remainingQuantity: $remainingQuantity');
      
      // ถ้าไม่มีข้อมูลใน API ให้ใช้ข้อมูลจาก widget
      if (maxQuantity == 0) {
        maxQuantity = widget.auctionData['quantity'] ?? 0;
        remainingQuantity = maxQuantity;
      }
      if (remainingQuantity < 0) {
        remainingQuantity = 0;
      }
    } else {
      print('DEBUG: _latestAuctionData is null, using widget data');
      // ใช้ข้อมูลจาก widget
      maxQuantity = widget.auctionData['quantity'] ?? 0;
      currentQuantitySold = 0;
      remainingQuantity = maxQuantity;
    }

    // แปลงเป็น double
    final currentPrice = _parseToDouble(currentPriceRaw);
    final startingPrice = _parseToDouble(startingPriceRaw);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ประมูลแบบลดจำนวน',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // ปุ่ม refresh ข้อมูล
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () {
              _loadLatestData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('กำลังอัปเดตข้อมูล...'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            tooltip: 'รีเฟรชข้อมูล',
          ),
          // ปุ่มรีเซทสำหรับทดสอบ
          // IconButton(
          //   icon: const Icon(Icons.restart_alt, color: Colors.orange),
          //   onPressed: () {
          //     _showResetConfirmationDialog();
          //   },
          //   tooltip: 'รีเซทการเข้าร่วม (สำหรับทดสอบ)',
          // ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            _buildProductImage(),

            // Product Info
            _buildProductInfo(),

            // Basic Info (แสดงข้อมูลพื้นฐานก่อน)
            _buildBasicInfo(currentPrice, startingPrice, maxQuantity, remainingQuantity, currentQuantitySold),

            // Product Details
            // _buildProductDetails(),

            // Item Notes
            _buildItemNotes(),

            // Seller Info
            _buildSellerInfo(),

            // Bottom spacing
            SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: _isCountdownActive 
        ? Container(
            margin: EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // แสดง countdown และจำนวนที่กำลังจะจอง
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ยกเลิกได้ใน $_countdownSeconds วินาที',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_pendingBookingQuantity != null)
                        Text(
                          'กำลังจอง: $_pendingBookingQuantity รายการ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                // ปุ่มยกเลิก
                FloatingActionButton.extended(
                  onPressed: _cancelBooking,
                  backgroundColor: Colors.red,
                  icon: Icon(Icons.cancel),
                  label: Text('ยกเลิกการจอง'),
                ),
              ],
            ),
          )
        : _isAuctionEnded()
            ? Container(
                margin: EdgeInsets.only(bottom: 16),
                child: FloatingActionButton.extended(
                  onPressed: null,
                  backgroundColor: Colors.grey,
                  icon: Icon(Icons.block),
                  label: Text('สิ้นสุดการประมูล'),
                ),
              )
            : FutureBuilder<int>(
                future: _getBookedQuantity(),
                builder: (context, snapshot) {
                  final bookedQuantity = snapshot.data ?? 0;
                  final maxQuantity = _getMaxAvailableQuantity();
                  final hasBooked = bookedQuantity > 0;
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    child: FloatingActionButton.extended(
                      onPressed: _isAuctionEnded() ? null : _showBookingDialog,
                      backgroundColor: _isAuctionEnded() ? Colors.grey : Colors.purple,
                      icon: Icon(hasBooked ? Icons.add_shopping_cart : Icons.book_online),
                      label: Text(
                        _isAuctionEnded()
                            ? 'สิ้นสุดการประมูล'
                            : hasBooked
                                ? 'จองเพิ่ม (จองแล้ว $bookedQuantity รายการ)' 
                                : 'เข้าร่วมการจอง (เหลือ $maxQuantity รายการ)',
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Future<int> _getBookedQuantity() async {
    // คำนวณจำนวนรวมจาก bid history ของ user นี้ (ไม่ต้องเช็ค _hasJoined เพราะสามารถจองเพิ่มได้)
    if (_latestAuctionData != null && _latestAuctionData!['bid_history'] != null) {
      int totalBookedQuantity = 0;
      final bidHistory = _latestAuctionData!['bid_history'] as List;
      
      // ใช้ bidder_id ที่เก็บไว้ใน SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('id') ?? '';
      
      for (var bid in bidHistory) {
        final bidderId = bid['bidder_id']?.toString();
        if (bidderId == currentUserId) { // ใช้ bidder_id ของ user ปัจจุบัน
          final quantityRequested = _safeToInt(bid['quantity_requested']) ?? 0;
          totalBookedQuantity += quantityRequested;
          print('DEBUG: Adding bid quantity: $quantityRequested for bidder_id: $bidderId');
        }
      }
      
      print('DEBUG: Total booked quantity calculated: $totalBookedQuantity for user: $currentUserId');
      return totalBookedQuantity;
    }
    
    return 0; // ถ้ายังไม่มี bid_history ให้ return 0
  }

  // คำนวณจำนวน MAX ที่สามารถจองได้
  int _getMaxAvailableQuantity() {
    if (_latestAuctionData != null) {
      final maxQuantity = _safeToInt(_latestAuctionData!['max_quantity_available']) ?? 
                         _safeToInt(_latestAuctionData!['remaining_quantity']) ?? 0;
      final currentQuantitySold = _safeToInt(_latestAuctionData!['current_quantity_sold']) ?? 0;
      final remainingQuantity = maxQuantity - currentQuantitySold;
      
      if (remainingQuantity > 0) {
        return remainingQuantity;
      }
    }
    
    // Fallback: ใช้ข้อมูลจาก widget
    return _safeToInt(widget.auctionData['quantity']) ?? 
           _safeToInt(widget.auctionData['max_quantity_available']) ?? 0;
  }

  // จองสินค้าด้วยจำนวน MAX ทันที
  Future<void> _bookWithMaxQuantity() async {
    final maxQuantity = _getMaxAvailableQuantity();
    
    if (maxQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่มีสินค้าให้จอง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // แสดง confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.book_online, color: Colors.purple, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'ยืนยันการจอง',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คุณต้องการจองสินค้า ${widget.auctionData['title']} จำนวน $maxQuantity รายการ (จำนวนสูงสุดที่มี) หรือไม่?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💰 ราคาปัจจุบัน: ${Format.formatCurrency(_latestAuctionData?['current_price'] ?? widget.auctionData['currentPrice'] ?? 0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '📦 จำนวนที่จะจอง: $maxQuantity รายการ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('ยืนยัน'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _joinAuction(maxQuantity);
    }
  }

  // คำนวณยอดรวมที่จองไปแล้ว (จำนวนที่จอง × ราคาปัจจุบัน)
  // Future<double> _getTotalBookedAmount() async {
  //   if (_latestAuctionData != null && _latestAuctionData!['bid_history'] != null) {
  //     // ใช้ราคาปัจจุบัน (ไม่ใช่ราคาใน bid)
  //     final currentPrice = _parseToDouble(_latestAuctionData!['current_price'] ?? widget.auctionData['currentPrice'] ?? 0);
      
  //     // คำนวณจำนวนที่จองทั้งหมด
  //     int totalBookedQuantity = 0;
  //     final bidHistory = _latestAuctionData!['bid_history'] as List;
      
  //     // ใช้ bidder_id ที่เก็บไว้ใน SharedPreferences
  //     final prefs = await SharedPreferences.getInstance();
  //     final currentUserId = prefs.getString('id') ?? '';
      
  //     for (var bid in bidHistory) {
  //       final bidderId = bid['bidder_id']?.toString();
  //       if (bidderId == currentUserId) {
  //         final quantityRequested = _safeToInt(bid['quantity_requested']) ?? 0;
  //         totalBookedQuantity += quantityRequested;
  //       }
  //     }
      
  //     // คำนวณยอดรวม = จำนวนที่จอง × ราคาปัจจุบัน
  //     final totalAmount = totalBookedQuantity * currentPrice;
      
  //     print('DEBUG: Total booked quantity: $totalBookedQuantity, Current price: $currentPrice, Total amount: $totalAmount');
  //     return totalAmount;
  //   }
  //   return 0.0;
  // }

  // ตรวจสอบสถานะการประมูล (หมดเวลา หรือ ครบจำนวน)
  bool _isAuctionEnded() {
    // ตรวจสอบว่าครบจำนวนหรือไม่
    if (_latestAuctionData != null) {
      final maxQuantity = _safeToInt(_latestAuctionData!['max_quantity_available']) ?? 0;
      final currentQuantitySold = _safeToInt(_latestAuctionData!['current_quantity_sold']) ?? 0;
      
      if (currentQuantitySold >= maxQuantity && maxQuantity > 0) {
        return true; // ครบจำนวนแล้ว
      }
    }
    
    // ตรวจสอบว่าหมดเวลาหรือไม่
    final endDateStr = _latestAuctionData?['auction_end_date']?.toString() ?? 
                      widget.auctionData['auction_end_date']?.toString() ??
                      widget.auctionData['end_date']?.toString();
    
    if (endDateStr != null && endDateStr.isNotEmpty) {
      try {
        final endDate = DateTime.parse(endDateStr);
        final now = DateTime.now();
        if (now.isAfter(endDate)) {
          return true; // หมดเวลาแล้ว
        }
      } catch (e) {
        print('DEBUG: Error parsing end date: $e');
      }
    }
    
    return false;
  }

  // ตรวจสอบว่าหมดเวลาก่อนครบจำนวนหรือไม่ (ให้สินค้าหายไป)
  bool _isTimeEndedBeforeQuantityComplete() {
    // ตรวจสอบว่าหมดเวลาหรือไม่
    final endDateStr = _latestAuctionData?['auction_end_date']?.toString() ?? 
                      widget.auctionData['auction_end_date']?.toString() ??
                      widget.auctionData['end_date']?.toString();
    
    if (endDateStr != null && endDateStr.isNotEmpty) {
      try {
        final endDate = DateTime.parse(endDateStr);
        final now = DateTime.now();
        if (now.isAfter(endDate)) {
          // ตรวจสอบว่าครบจำนวนหรือยัง
          if (_latestAuctionData != null) {
            final maxQuantity = _safeToInt(_latestAuctionData!['max_quantity_available']) ?? 0;
            final currentQuantitySold = _safeToInt(_latestAuctionData!['current_quantity_sold']) ?? 0;
            
            // ถ้าหมดเวลาแต่ยังไม่ครบจำนวน = ให้สินค้าหายไป
            if (currentQuantitySold < maxQuantity) {
              return true;
            }
          }
        }
      } catch (e) {
        print('DEBUG: Error parsing end date: $e');
      }
    }
    
    return false;
  }

  // รับเหตุผลที่สิ้นสุดการประมูล
  String _getAuctionEndReason() {
    // ตรวจสอบว่าครบจำนวนหรือไม่
    if (_latestAuctionData != null) {
      final maxQuantity = _safeToInt(_latestAuctionData!['max_quantity_available']) ?? 0;
      final currentQuantitySold = _safeToInt(_latestAuctionData!['current_quantity_sold']) ?? 0;
      
      if (currentQuantitySold >= maxQuantity && maxQuantity > 0) {
        return 'สินค้าครบจำนวนแล้ว ($currentQuantitySold/$maxQuantity รายการ)';
      }
    }
    
    // ตรวจสอบว่าหมดเวลาหรือไม่
    final endDateStr = _latestAuctionData?['auction_end_date']?.toString() ?? 
                      widget.auctionData['auction_end_date']?.toString() ??
                      widget.auctionData['end_date']?.toString();
    
    if (endDateStr != null && endDateStr.isNotEmpty) {
      try {
        final endDate = DateTime.parse(endDateStr);
        final now = DateTime.now();
        if (now.isAfter(endDate)) {
          return 'หมดเวลาการประมูลแล้ว';
        }
      } catch (e) {
        print('DEBUG: Error parsing end date: $e');
      }
    }
    
    return 'สิ้นสุดการประมูล';
  }

  Widget _buildProductImage() {
    return Column(
      children: [
        // Main Image
        Container(
          width: double.infinity,
          height: 300,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  if (_imageUrls.isNotEmpty && _imageUrls.length > 1) {
                    _showImageGallery();
                  }
                },
                child: _buildAuctionImage(
                  _imageUrls.isNotEmpty ? _imageUrls[_selectedImageIndex] : 'assets/images/noimage.jpg',
                  width: double.infinity,
                  height: 300,
                ),
              ),
              // ป้ายประเภทสินค้าในรูป
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_down, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'ประมูลแบบลดจำนวน',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Thumbnail Gallery - แสดงเมื่อมีมากกว่า 1 รูป
        if (_imageUrls.length > 1)
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedImageIndex == index
                            ? Colors.purple
                            : Colors.grey[300]!,
                        width: _selectedImageIndex == index ? 3 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildAuctionImage(
                        _imageUrls[index],
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAuctionImage(String? imagePath, {double width = double.infinity, double height = 300}) {
    return AuctionImageWidget(
      imagePath: imagePath,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }

  // Show image gallery in full screen
  void _showImageGallery() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: _selectedImageIndex),
                itemCount: _imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Center(
                      child: _buildAuctionImage(
                        _imageUrls[index],
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  );
                },
              ),
              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              // Image counter
              if (_imageUrls.length > 1)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_selectedImageIndex + 1} / ${_imageUrls.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.auctionData['title'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.auctionData['description'] ?? 'ไม่มีคำอธิบาย',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(dynamic currentPrice, dynamic startingPrice, dynamic maxQuantity, dynamic remainingQuantity, int currentQuantitySold) {
    // Convert to proper types
    final currentPriceDouble = (currentPrice is int) ? currentPrice.toDouble() : (currentPrice is double) ? currentPrice : 0.0;
    final startingPriceDouble = (startingPrice is int) ? startingPrice.toDouble() : (startingPrice is double) ? startingPrice : 0.0;
    
    // ใช้ข้อมูลจาก ProductService
    int quantityInt, remainingQuantityInt;
    
    if (_latestAuctionData != null) {
      // ใช้ maxQuantity ที่ส่งมาจาก build method
      quantityInt = _safeToInt(maxQuantity) ?? 0;
      remainingQuantityInt = _safeToInt(remainingQuantity) ?? 0;
      
      print('DEBUG: _buildBasicInfo - maxQuantity received: $maxQuantity');
      print('DEBUG: _buildBasicInfo - quantityInt: $quantityInt');
      print('DEBUG: _buildBasicInfo - remainingQuantityInt: $remainingQuantityInt');
    } else {
      quantityInt = _safeToInt(maxQuantity) ?? 0;
      remainingQuantityInt = _safeToInt(remainingQuantity) ?? 0;
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.attach_money, color: Colors.purple, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ราคาปัจจุบัน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      Format.formatCurrency(currentPriceDouble),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   'ยอดรวมที่จอง',
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.purple[700],
                    //   ),
                    // ),
                    // SizedBox(height: 4),
                    // FutureBuilder<double>(
                    //   future: _getTotalBookedAmount(),
                    //   builder: (context, snapshot) {
                    //     final totalAmount = snapshot.data ?? 0.0;
                    //     return Text(
                    //       Format.formatCurrency(totalAmount),
                    //       style: TextStyle(
                    //         fontSize: 24,
                    //         fontWeight: FontWeight.bold,
                    //         color: Colors.purple[700],
                    //       ),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
            ],
          ),
          // แสดงสถานะสิ้นสุดการประมูล
          if (_isAuctionEnded()) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[700], size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สิ้นสุดการประมูล',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _getAuctionEndReason(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2, color: Colors.purple, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'จำนวนสินค้า',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'เหลือ $remainingQuantityInt จาก $quantityInt รายการ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (currentQuantitySold > 0)
                      Text(
                        'ขายแล้ว: $currentQuantitySold รายการ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    // แสดงจำนวนที่ผู้ใช้จองไปแล้ว
                    FutureBuilder<int>(
                      future: _getBookedQuantity(),
                      builder: (context, snapshot) {
                        final myBookedQuantity = snapshot.data ?? 0;
                        if (myBookedQuantity > 0) {
                          return Container(
                            margin: EdgeInsets.only(top: 4),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_pin, color: Colors.purple, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'คุณจองแล้ว: $myBookedQuantity รายการ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.purple[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                    // แสดงข้อมูล bidder ล่าสุด
                    if (_latestAuctionData != null && _latestAuctionData!['bid_history'] != null && _latestAuctionData!['bid_history'].isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, color: Colors.blue, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'ผู้จองล่าสุด:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            // เรียงลำดับ bid_history ให้ล่าสุดอยู่ด้านบน และแสดง 5 คนล่าสุด
                            Builder(
                              builder: (context) {
                                final bidHistory = (_latestAuctionData!['bid_history'] as List)
                                    .map((bid) => Map<String, dynamic>.from(bid))
                                    .toList();
                                
                                // เรียงตาม bid_time หรือ created_at (ล่าสุดก่อน)
                                bidHistory.sort((a, b) {
                                  final timeA = a['bid_time']?.toString() ?? a['created_at']?.toString() ?? '';
                                  final timeB = b['bid_time']?.toString() ?? b['created_at']?.toString() ?? '';
                                  try {
                                    final dateA = DateTime.parse(timeA);
                                    final dateB = DateTime.parse(timeB);
                                    return dateB.compareTo(dateA); // ล่าสุดก่อน
                                  } catch (e) {
                                    return 0;
                                  }
                                });
                                
                                // แสดง 5 คนล่าสุด
                                final latestBids = bidHistory.take(5).toList();
                                
                                return Column(
                                  children: latestBids.map((bid) {
                              final bidderName = bid['bidder_name']?.toString() ?? 'ไม่ระบุ';
                              final quantityRequested = _safeToInt(bid['quantity_requested']) ?? 0;
                              final bidTime = bid['bid_time']?.toString() ?? '';
                              
                              // จัดรูปแบบเบอร์โทรศัพท์ให้มี 0 นำหน้าและปิดด้วย XXXX
                              String formattedBidderName = bidderName;
                              if (bidderName.length == 9 && !bidderName.startsWith('0')) {
                                // ถ้าเป็นเบอร์ 9 หลักและไม่มี 0 นำหน้า ให้เพิ่ม 0 นำหน้า
                                formattedBidderName = '0$bidderName';
                              } else if (bidderName.length == 10 && bidderName.startsWith('0')) {
                                // ถ้าเป็นเบอร์ 10 หลักและมี 0 นำหน้าแล้ว ให้ใช้ตามเดิม
                                formattedBidderName = bidderName;
                              } else if (bidderName.length == 10 && !bidderName.startsWith('0')) {
                                // ถ้าเป็นเบอร์ 10 หลักและไม่มี 0 นำหน้า ให้เพิ่ม 0 นำหน้า
                                formattedBidderName = '0$bidderName';
                              }
                              
                              // ปิดเบอร์ด้วย XXXX 4 ตัวท้าย
                              if (formattedBidderName.length >= 6) {
                                final prefix = formattedBidderName.substring(0, formattedBidderName.length - 4);
                                formattedBidderName = '${prefix}XXXX';
                              }
                              
                              return Padding(
                                padding: EdgeInsets.only(bottom: 2),
                                child: Row(
                                  children: [
                                    Text(
                                      '• $formattedBidderName: $quantityRequested ชิ้น',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                    if (bidTime.isNotEmpty) ...[
                                      Spacer(),
                                      Text(
                                        _formatBidTime(bidTime),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: quantityInt > 0 ? (quantityInt - remainingQuantityInt) / quantityInt : 0.0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildProductDetails() {
  //   return Container(
  //     margin: const EdgeInsets.all(16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'รายละเอียดสินค้า',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         Container(
  //           padding: const EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(12),
  //             border: Border.all(color: Colors.grey.withOpacity(0.3)),
  //           ),
  //           child: Column(
  //             children: [
  //               _buildDetailRow('แบรนด์', widget.auctionData['brand'] ?? 'ไม่ระบุ'),
  //               _buildDetailRow('รุ่น', widget.auctionData['model'] ?? 'ไม่ระบุ'),
  //               _buildDetailRow('วัสดุ', widget.auctionData['material'] ?? 'ไม่ระบุ'),
  //               _buildDetailRow('ขนาด', widget.auctionData['size'] ?? 'ไม่ระบุ'),
  //               _buildDetailRow('สี', widget.auctionData['color'] ?? 'ไม่ระบุ'),
  //               _buildDetailRow('สภาพ', widget.auctionData['condition'] ?? 'ไม่ระบุ'),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSellerInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลผู้ขาย',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: context.customTheme.primaryColor,
                  child: Text(
                    (widget.auctionData['sellerName']?.length ?? 0) >= 2
                        ? widget.auctionData['sellerName']!.substring(0, 2)
                        : (widget.auctionData['sellerName'] ?? 'CM'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.auctionData['sellerName'] ?? 'CloudmateTH',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.auctionData['sellerRating'] ?? '4.5'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemNotes() {
    final itemNote = widget.auctionData['item_note'];
    if (itemNote == null || itemNote.toString().isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.note, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'หมายเหตุ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    itemNote.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // แสดง Dialog สำหรับการจอง
  void _showBookingDialog() async {
    final TextEditingController quantityController = TextEditingController();
    
    // ใช้ _getMaxAvailableQuantity() เพื่อคำนวณจำนวนที่เหลือ
    final availableQuantity = _getMaxAvailableQuantity();
    
    if (availableQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่มีสินค้าให้จอง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // ดึงจำนวนที่จองไปแล้ว
    final bookedQuantity = await _getBookedQuantity();
    final isAdditionalBooking = bookedQuantity > 0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isAdditionalBooking ? Icons.add_shopping_cart : Icons.book_online, 
                color: Colors.purple, 
                size: 24
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                isAdditionalBooking ? 'จองเพิ่ม' : 'เข้าร่วมการจอง',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAdditionalBooking 
                  ? 'คุณต้องการจองเพิ่มสินค้า ${widget.auctionData['title']} หรือไม่?'
                  : 'คุณต้องการจองสินค้า ${widget.auctionData['title']} หรือไม่?',
              style: TextStyle(fontSize: 16),
            ),
            // แสดงจำนวนที่จองไปแล้ว (ถ้ามี)
            if (isAdditionalBooking) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'คุณจองไปแล้ว:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '$bookedQuantity รายการ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16),
            Text(
              'จำนวนที่ต้องการจอง:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'ระบุจำนวน (สูงสุด $availableQuantity)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.shopping_cart),
              ),
            ),
            SizedBox(height: 12),
            // แสดงจำนวนที่เหลือ
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, color: Colors.blue[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'จำนวนสินค้าที่เหลือ:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$availableQuantity รายการ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 กติกาการจอง:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• กรุณาระบุจำนวนที่ต้องการจอง (ไม่เกิน $availableQuantity รายการ)'),
                  Text('• เมื่อจองแล้ว จะมีเวลา 15 วินาทีในการยกเลิก'),
                  Text('• ราคาจะลดลงอัตโนมัติตามเวลาที่กำหนด'),
                  Text('• ผู้ที่จองก่อนจะได้สิทธิ์ซื้อก่อน'),
                  SizedBox(height: 8),
                  Text(
                    '💰 ราคาปัจจุบัน: ${Format.formatCurrency(_latestAuctionData?['current_price'] ?? widget.auctionData['currentPrice'] ?? 0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text) ?? 0;
              if (quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('กรุณาระบุจำนวนที่ต้องการจอง'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (quantity > availableQuantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('จำนวนที่จองเกินกว่าที่มี (สูงสุด $availableQuantity)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _startBookingCountdown(quantity);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('จองเลย'),
          ),
        ],
      ),
    );
  }

  double _calculateTotalAmount() {
    if (_latestAuctionData != null && _latestAuctionData!['bid_history'] != null) {
      // คำนวณ total_amount จาก bid_history ของ bidder_id: 13
      double totalAmount = 0.0;
      final bidHistory = _latestAuctionData!['bid_history'] as List;
      
      for (var bid in bidHistory) {
        final bidderId = bid['bidder_id']?.toString();
        if (bidderId == '13') { // ใช้เฉพาะ bidder_id: 13
          final totalAmountFromBid = _parseToDouble(bid['total_amount']);
          totalAmount += totalAmountFromBid;
          print('DEBUG: Adding bid total_amount: $totalAmountFromBid for bidder_id: $bidderId');
        }
      }
      
      print('DEBUG: Total amount calculated: $totalAmount');
      return totalAmount;
    } else if (_latestAuctionData != null) {
      // คำนวณจากจำนวนที่ขายแล้ว × ราคาปัจจุบัน
      final currentQuantitySold = _safeToInt(_latestAuctionData!['current_quantity_sold']) ?? 0;
      final currentPrice = _parseToDouble(_latestAuctionData!['current_price'] ?? widget.auctionData['currentPrice'] ?? 0);
      
      return currentQuantitySold * currentPrice;
    } else {
      // คำนวณจากราคาปัจจุบัน × จำนวนที่เหลือ
      final currentPrice = _parseToDouble(_latestAuctionData?['current_price'] ?? widget.auctionData['currentPrice'] ?? 0);
      final quantity = _safeToInt(_latestAuctionData?['remaining_quantity'] ?? widget.auctionData['quantity'] ?? 0) ?? 0;
      return currentPrice * quantity;
    }
  }

  // เริ่ม countdown สำหรับการจอง
  void _startBookingCountdown(int quantity) {
    setState(() {
      _isCountdownActive = true;
      _countdownSeconds = 15;
      _pendingBookingQuantity = quantity;
    });
    
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });
      
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _executeBooking();
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เริ่มจอง! คุณมีเวลา 15 วินาทีในการยกเลิก (จำนวน: $quantity รายการ)'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'ยกเลิก',
          textColor: Colors.white,
          onPressed: _cancelBooking,
        ),
      ),
    );
  }
  
  // ยกเลิกการจอง
  void _cancelBooking() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountdownActive = false;
      _countdownSeconds = 15;
      _pendingBookingQuantity = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ยกเลิกการจองแล้ว'),
        backgroundColor: Colors.grey,
      ),
    );
  }
  
  // ส่งข้อมูลการจองไปยัง API
  void _executeBooking() {
    if (_pendingBookingQuantity != null) {
      _joinAuction(_pendingBookingQuantity!);
      setState(() {
        _isCountdownActive = false;
        _pendingBookingQuantity = null;
      });
    }
  }
} 