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
import 'package:e_auction/services/winner_service.dart';
import 'package:e_auction/views/first_page/widgets/auction_image_widget.dart';
import 'package:e_auction/noti_ios/noti_ios.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:e_auction/views/first_page/widgets/auction_bid_dialog.dart';
import 'package:e_auction/views/first_page/widgets/auction_pending_bid_dialog.dart';
import 'package:e_auction/services/coupon_service.dart';
import 'package:e_auction/views/first_page/coupon_page/my_coupons_page.dart';


class AuctionDetailViewPage extends StatefulWidget {
  final Map<String, dynamic> auctionData;

  AuctionDetailViewPage({super.key, required this.auctionData});

  @override
  _AuctionDetailViewPageState createState() => _AuctionDetailViewPageState();
}

class _AuctionDetailViewPageState extends State<AuctionDetailViewPage> {
  final GlobalKey<_RealtimeAuctionPriceWidgetState> realtimePriceKey =
      GlobalKey<_RealtimeAuctionPriceWidgetState>();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  Map<String, dynamic>? _latestAuctionData;

  // Add a static variable to track the disclaimer popup state
  static bool _hideDisclaimer = false;
  
  // Timer สำหรับอัปเดตเวลาที่เหลือในการยกเลิก
  Timer? _cancelTimer;
  
  // เพิ่มตัวแปรสำหรับระบบ hold bid
  Map<String, dynamic>? _pendingBid;
  Timer? _pendingBidTimer;
  bool _isPendingBidConfirmed = false;
  
  // Image gallery state
  int _selectedImageIndex = 0;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _parseImages();
  }
  
  // Parse images from auctionData
  void _parseImages() {
    _imageUrls = [];
    
    // ใช้ images array ที่ parse แล้วจาก product_service
    if (widget.auctionData['images'] != null && widget.auctionData['images'] is List) {
      final imagesList = widget.auctionData['images'] as List;
      if (imagesList.isNotEmpty) {
        for (var img in imagesList) {
          if (img != null && img.toString().isNotEmpty) {
            _imageUrls.add(img.toString());
          }
        }
      }
    }
    
    // ถ้ายังไม่มีรูป ให้ใช้ image เดียว (backward compatibility)
    if (_imageUrls.isEmpty && widget.auctionData['image'] != null) {
      final singleImage = widget.auctionData['image'].toString();
      if (singleImage.isNotEmpty && singleImage != 'assets/images/noimage.jpg') {
        _imageUrls.add(singleImage);
      }
    }
    
    // ถ้ายังไม่มีรูปเลย ให้ parse จาก quotation_image (fallback)
    if (_imageUrls.isEmpty) {
      final quotationImage = widget.auctionData['quotation_image'];
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
          print('Error parsing images in auction_detail_view_page: $e');
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
    String baseUrl = 'https://cm-mecustomers.com/ERP-Cloudmate/modules/sales/uploads/quotation/$imageName';
    
    // Convert to HTTP for Android
    if (Platform.isAndroid) {
      baseUrl = baseUrl.replaceFirst('https://', 'http://');
    }
    
    return baseUrl;
  }

  // แสดง Custom Toast Message
  void _showCustomToast(BuildContext context, String message,
      {bool isSuccess = true}) {
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

    // แสดง Custom Success Dialog
  void _showSuccessDialog(BuildContext context, String message) {

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, color: Colors.green, size: 48),
                ),
                SizedBox(height: 16),
                Text(
                  'สำเร็จ!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('ตกลง',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('🔍 DEBUG: Error showing success dialog: $e');
    }
  }

  // แสดง Dialog เมื่อได้รับคูปอง
  void _showCouponReceivedDialog(BuildContext context, dynamic coupon) {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_offer, color: Colors.orange, size: 48),
                ),
                SizedBox(height: 16),
                Text(
                  '🎉 คุณได้รับคูปองส่วนลด!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                SizedBox(height: 16),
                // Coupon Code
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'รหัสคูปอง',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        coupon.code ?? '',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Coupon Details
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (coupon.discountPercent != null)
                        Text(
                          'ส่วนลด ${coupon.discountPercent}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      if (coupon.maxDiscountAmount != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'สูงสุด ${Format.formatCurrency(coupon.maxDiscountAmount.toInt())}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      if (coupon.minPurchaseAmount != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'ขั้นต่ำ ${Format.formatCurrency(coupon.minPurchaseAmount.toInt())}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('ปิด'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyCouponsPage(),
                            ),
                          );
                        },
                        child: Text('ดูคูปองของฉัน',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('🔍 DEBUG: Error showing coupon dialog: $e');
      // Fallback to toast
      _showCustomToast(
        context,
        '🎉 คุณได้รับคูปองส่วนลด! รหัส: ${coupon.code}',
        isSuccess: true,
      );
    }
  }

  // เพิ่มเมธอดสำหรับแสดง dialog ลงประมูล
  void _showBidDialog(BuildContext context) async {
    final productService = ProductService(baseUrl: _getBaseUrl());
    final quotationId =
        widget.auctionData['quotation_more_information_id']?.toString() ??
            widget.auctionData['id'].toString();

    // ตรวจสอบประเภทการประมูล
    final quotationTypeCode = widget.auctionData['quotation_type_code']?.toString() ?? '';
    
    // ถ้าเป็น AS02 (Reverse Auction) ให้ใช้ dialog แบบราคาลด
    if (quotationTypeCode == 'AS02') {
      _showReverseAuctionBidDialog(context);
      return;
    }

    try {
      final url =
          '${_getBaseUrl()}/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=$quotationId';

      final client = _getHttpClient();
      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null && data['quotation_more_information_id'] != null) {
          final latestData = data;

          // แสดง dialog ลงประมูลโดยใช้ widget ที่แยกออกไปแล้ว
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AuctionBidDialog(
                auctionData: widget.auctionData,
                latestData: latestData,
                onBidConfirmed: (bidData) async {
                  Navigator.pop(context); // ปิด dialog

                  // เก็บข้อมูลการประมูลไว้ใน pending
                  final prefs = await SharedPreferences.getInstance();
                  final bidderId = prefs.getString('id') ?? '';
                  final bidderName = prefs.getString('phone_number') ?? '';

                  _pendingBid = {
                    'quotationId': quotationId,
                    'minimumIncrease': bidData['minimumIncrease'].toString(),
                    'bidAmount': bidData['bidAmount'].toString(),
                    'bidderId': bidderId,
                    'bidderName': bidderName,
                    'currentPrice': int.tryParse(latestData['current_price']?.toString() ?? '0') ?? 0,
                    'productTitle': widget.auctionData['title'],
                    'timestamp': DateTime.now().toIso8601String(),
                    'isReverseAuction': true, // เพิ่ม flag สำหรับ Reverse Auction
                  };

                  // แสดง dialog ยืนยันการประมูล
                  _showPendingBidConfirmationDialog(context);
                },
                onCancel: () {
                  Navigator.pop(context);
                },
              );
            },
          );
        } else {
          _showCustomToast(context, 'ไม่สามารถโหลดข้อมูลล่าสุดได้', isSuccess: false);
        }
      } else {
        _showCustomToast(context, 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้', isSuccess: false);
      }
    } catch (e) {
      _showCustomToast(context, 'เกิดข้อผิดพลาด: $e', isSuccess: false);
    }
  }

  // แสดง dialog สำหรับ Reverse Auction (AS02)
  void _showReverseAuctionBidDialog(BuildContext context) async {
    final productService = ProductService(baseUrl: _getBaseUrl());
    final quotationId =
        widget.auctionData['quotation_more_information_id']?.toString() ??
            widget.auctionData['id'].toString();

    try {
      final url =
          '${_getBaseUrl()}/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=$quotationId';

      final client = _getHttpClient();
      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null && data['quotation_more_information_id'] != null) {
          final latestData = data;



          // แสดง dialog ลงประมูลโดยใช้ AuctionBidDialog (รองรับ AS02 แล้ว)
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AuctionBidDialog(
                auctionData: widget.auctionData,
                latestData: latestData,
                onBidConfirmed: (bidData) async {
                  Navigator.pop(context); // ปิด dialog

                  // เก็บข้อมูลการประมูลไว้ใน pending
                  final prefs = await SharedPreferences.getInstance();
                  final bidderId = prefs.getString('id') ?? '';
                  final bidderName = prefs.getString('phone_number') ?? '';

                  _pendingBid = {
                    'quotationId': quotationId,
                    'minimumIncrease': bidData['minimumIncrease'].toString(),
                    'bidAmount': bidData['bidAmount'].toString(),
                    'bidderId': bidderId,
                    'bidderName': bidderName,
                    'currentPrice': int.tryParse(latestData['current_price']?.toString() ?? '0') ?? 0,
                    'productTitle': widget.auctionData['title'],
                    'timestamp': DateTime.now().toIso8601String(),
                    'isReverseAuction': true, // เพิ่ม flag สำหรับ Reverse Auction
                  };

                  // แสดง dialog ยืนยันการประมูล
                  _showPendingBidConfirmationDialog(context);
                },
                onCancel: () {
                  Navigator.pop(context);
                },
              );
            },
          );
        } else {
          _showCustomToast(context, 'ไม่สามารถโหลดข้อมูลล่าสุดได้', isSuccess: false);
        }
      } else {
        _showCustomToast(context, 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้', isSuccess: false);
      }
    } catch (e) {
      _showCustomToast(context, 'เกิดข้อผิดพลาด: $e', isSuccess: false);
    }
  }

  // เพิ่มเมธอดสำหรับแสดง dialog ยืนยันการประมูลที่ pending
  void _showPendingBidConfirmationDialog(BuildContext context) {
    print('🔍 DEBUG: _showPendingBidConfirmationDialog called');
    print('🔍 DEBUG: _pendingBid: $_pendingBid');
    if (_pendingBid == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AuctionPendingBidDialog(
          pendingBid: _pendingBid!,
          onCancel: () {
            Navigator.pop(context);
            _cancelPendingBid();
          },
          onConfirm: () {
            Navigator.pop(context);
            _confirmPendingBid(context);
          },
        );
      },
    );
  }

  // เพิ่มเมธอดสำหรับยืนยันการประมูลที่ pending
  void _confirmPendingBid(BuildContext context) async {
    if (_pendingBid == null) return;

    setState(() {
      _isPendingBidConfirmed = true;
    });

    try {
      final productService = ProductService(baseUrl: _getBaseUrl());
      
      // ตรวจสอบว่าเป็น Reverse Auction หรือไม่
      final isReverseAuction = _pendingBid!['isReverseAuction'] == true;
      
      print('🔔 BID_SUCCESS: Starting bid process... (Reverse Auction: $isReverseAuction)');
      final result = await productService.placeBid(
        quotationId: _pendingBid!['quotationId'],
        minimumIncrease: _pendingBid!['minimumIncrease'],
        bidAmount: _pendingBid!['bidAmount'],
        bidderId: _pendingBid!['bidderId'],
        bidderName: _pendingBid!['bidderName'],
      );
      print('🔔 BID_SUCCESS: Bid result: $result');

      if (result != null && result['status'] == 'success') {
        print('🔔 BID_SUCCESS: Bid was successful!');
        // รอให้แน่ใจว่า loading dialog ปิดสนิทแล้ว
        await Future.delayed(Duration(milliseconds: 100));
        
        print('🔔 BID_SUCCESS: Showing success dialog...');
        
        // แสดงข้อความตามประเภทการประมูล
        final successMessage = isReverseAuction 
          ? 'เสนอราคาสำเร็จ! ${result['data']['calculation'] ?? ''}'
          : 'ลงประมูลสำเร็จ! ${result['data']['calculation'] ?? ''}';
        
        // ใช้ print แทน dialog เพื่อหลีกเลี่ยง context issues
        print('🎉 SUCCESS: $successMessage');
        print('🔍 DEBUG: Success message logged to console');
        
        // สร้างคูปองให้ผู้ใช้เมื่อประมูลสำเร็จ
        try {
          print('🎫 COUPON: กำลังสร้างคูปองให้ผู้ใช้...');
          final couponService = CouponService();
          final quotationId = _pendingBid!['quotationId'].toString();
          final quotationTitle = widget.auctionData['title']?.toString();
          
          final coupon = await couponService.createBidRewardCoupon(
            userId: _pendingBid!['bidderId'],
            userName: _pendingBid!['bidderName'],
            userPhone: _pendingBid!['bidderName'], // ใช้ bidderName เป็น phone
            quotationId: quotationId,
            quotationTitle: quotationTitle,
          );
          
          if (coupon != null) {
            print('🎫 COUPON: สร้างคูปองสำเร็จ - Code: ${coupon.code}');
            // แสดง dialog แจ้งเตือนว่าผู้ใช้ได้รับคูปอง
            if (mounted) {
              _showCouponReceivedDialog(context, coupon);
            }
          } else {
            print('❌ COUPON: ไม่สามารถสร้างคูปองได้');
          }
        } catch (e) {
          print('❌ COUPON: Error creating coupon: $e');
        }
        
        // ส่งแจ้งเตือนเมื่อ bid สำเร็จ
        print('🔔 BID_SUCCESS: About to send notification...');
        try {
          print('🔔 BID_SUCCESS: Starting notification process...');
          
          final productTitle = widget.auctionData['title'] ?? 'สินค้า';
          final latestPrice = Format.formatCurrency(int.tryParse(_pendingBid!['bidAmount']) ?? 0);
          final bidderName = _pendingBid!['bidderName'] ?? '';
          
          print('🔔 BID_SUCCESS: Product: $productTitle');
          print('🔔 BID_SUCCESS: Price: $latestPrice');
          print('🔔 BID_SUCCESS: Bidder: $bidderName');
          print('🔔 BID_SUCCESS: Is Reverse Auction: $isReverseAuction');
          
          // สร้าง plugin instance ใหม่
          final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
          
          // ตั้งค่า Android
          const AndroidInitializationSettings initializationSettingsAndroid =
              AndroidInitializationSettings('@mipmap/ic_launcher');
          
          // ตั้งค่า iOS
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
          print('🔔 BID_SUCCESS: Plugin initialized successfully');
          
          print('🔔 BID_SUCCESS: Calling sendBidSuccessNotification...');
          await sendBidSuccessNotification(
            plugin,
            productTitle,
            latestPrice,
            bidderName,
          );
          
          print('🎉 BID_SUCCESS: Notification sent successfully!');
        } catch (e) {
          print('❌ BID_SUCCESS: Error sending notification: $e');
          print('❌ BID_SUCCESS: Error details: ${e.toString()}');
        }

          // ดึงข้อมูลล่าสุดและอัปเดต real-time
          try {
            final latestUrl =
                '${_getBaseUrl()}/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=${_pendingBid!['quotationId']}';
            final client = _getHttpClient();
            final latestResponse = await client.get(Uri.parse(latestUrl));

                      if (latestResponse.statusCode == 200) {
              final latestData = jsonDecode(latestResponse.body);
              if (latestData != null && latestData['quotation_more_information_id'] != null) {
                setState(() {
                  _latestAuctionData = latestData;
                  _pendingBid = null;
                  _isPendingBidConfirmed = false;
                });
                realtimePriceKey.currentState?.updateAuctionData(latestData);
              }
            }
          } catch (e) {}
      } else {
        _showCustomToast(context, 'เกิดข้อผิดพลาดในการประมูล', isSuccess: false);
        setState(() {
          _isPendingBidConfirmed = false;
        });
      }
    } catch (e) {
      _showCustomToast(context, 'เกิดข้อผิดพลาด: $e', isSuccess: false);
      setState(() {
        _isPendingBidConfirmed = false;
      });
    }
  }

  // เพิ่มเมธอดสำหรับยกเลิกการประมูลที่ pending
  void _cancelPendingBid() {
    setState(() {
      _pendingBid = null;
      _isPendingBidConfirmed = false;
    });
    _showCustomToast(context, 'ยกเลิกการประมูลสำเร็จ', isSuccess: true);
  }

  void _showDisclaimerDialog(BuildContext context, VoidCallback onAccept) {
    bool dontShowAgain = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ข้อสงวนสิทธิ์ของบริษัทฯ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'บริษัทฯ ขอสงวนสิทธิ์ในการยกเลิกหรือเลื่อนการประมูลโดยไม่ต้องแจ้งเหตุผล'),
                  SizedBox(height: 8),
                  Text(
                      'คำตัดสินของคณะกรรมการหรือผู้แทนบริษัทฯ ถือเป็นที่สิ้นสุด'),
                  SizedBox(height: 8),
                  Text(
                      'บริษัทฯ ไม่รับผิดชอบต่อความเสียหายหรือข้อพิพาทที่อาจเกิดขึ้นหลังจากการส่งมอบสินค้า'),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: dontShowAgain,
                        onChanged: (val) {
                          setState(() {
                            dontShowAgain = val ?? false;
                          });
                        },
                      ),
                      Expanded(child: Text('ไม่ต้องแสดงอีกจนกว่าจะปิดแอป')),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _hideDisclaimer = dontShowAgain;
                    Navigator.of(context).pop();
                    onAccept();
                  },
                  child: Text('ยอมรับและดำเนินการต่อ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onBidPressed(BuildContext context) {
    if (_hideDisclaimer) {
      _showBidDialog(context);
    } else {
      _showDisclaimerDialog(context, () => _showBidDialog(context));
    }
  }

  // เพิ่มเมธอดสำหรับตรวจสอบว่าผู้ใช้เป็นผู้ประมูลล่าสุดหรือไม่
  Future<bool> _isCurrentUserLatestBidder() async {
    if (_latestAuctionData == null || _latestAuctionData!['bid_history'] == null) {
      return false;
    }
    
    final bidHistory = _latestAuctionData!['bid_history'] as List;
    if (bidHistory.isEmpty) return false;
    
    final latestBid = bidHistory.last;
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('phone_number') ?? '';
    
    // ตรวจสอบว่า bidder_name ตรงกับ phone_number ของผู้ใช้หรือไม่
    return latestBid['bidder_name'] == userPhone;
  }

  // เพิ่มเมธอดสำหรับตรวจสอบเวลาที่เหลือในการยกเลิก
  Future<bool> _canCancelBid() async {
    final isLatestBidder = await _isCurrentUserLatestBidder();
    if (!isLatestBidder) return false;
    
    if (_latestAuctionData == null || _latestAuctionData!['bid_history'] == null) {
      return false;
    }
    
    final bidHistory = _latestAuctionData!['bid_history'] as List;
    if (bidHistory.isEmpty) return false;
    
    final latestBid = bidHistory.last;
    final bidTime = latestBid['bid_time'];
    if (bidTime == null) return false;
    
    try {
      final bidDateTime = DateTime.parse(bidTime);
      final now = DateTime.now();
      final difference = now.difference(bidDateTime);
      
      // อนุญาตให้ยกเลิกได้ภายใน 30 นาที
      return difference.inMinutes < 30;
    } catch (e) {
      return false;
    }
  }

  // เพิ่มเมธอดสำหรับคำนวณเวลาที่เหลือ
  String _getRemainingCancelTime() {
    if (_latestAuctionData == null || _latestAuctionData!['bid_history'] == null) {
      return '';
    }
    
    final bidHistory = _latestAuctionData!['bid_history'] as List;
    if (bidHistory.isEmpty) return '';
    
    final latestBid = bidHistory.last;
    final bidTime = latestBid['bid_time'];
    if (bidTime == null) return '';
    
    try {
      final bidDateTime = DateTime.parse(bidTime);
      final now = DateTime.now();
      final difference = now.difference(bidDateTime);
      final remainingMinutes = 30 - difference.inMinutes;
      
      if (remainingMinutes <= 0) return '';
      
      final remainingSeconds = 60 - difference.inSeconds % 60;
      return '${remainingMinutes}:${remainingSeconds.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  // เพิ่มเมธอดสำหรับแสดง dialog ยกเลิกการประมูล
  void _showCancelBidDialog(BuildContext context) {
    // ดึงข้อมูลการประมูลล่าสุด
    String currentBidAmount = '0';
    String previousPrice = '0';
    
    if (_latestAuctionData != null && _latestAuctionData!['bid_history'] != null) {
      final bidHistory = _latestAuctionData!['bid_history'] as List;
      if (bidHistory.isNotEmpty) {
        currentBidAmount = Format.formatCurrency(
          int.tryParse(bidHistory.last['bid_amount']?.toString() ?? '0') ?? 0
        );
        
        // คำนวณราคาก่อนหน้า
        if (bidHistory.length > 1) {
          previousPrice = Format.formatCurrency(
            int.tryParse(bidHistory[bidHistory.length - 2]['bid_amount']?.toString() ?? '0') ?? 0
          );
        } else {
          previousPrice = Format.formatCurrency(
            int.tryParse(_latestAuctionData!['star_price']?.toString() ?? '0') ?? 0
          );
        }
      }
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
    final url = Config.apiUrlAuction;
    if (Platform.isAndroid) {
      return url.replaceFirst('https://', 'http://');
    }
    return url;
  }

  // ตรวจสอบว่าเป็น Reverse Auction (AS02) หรือไม่
  bool _isReverseAuction() {
    final quotationTypeCode = widget.auctionData['quotation_type_code']?.toString() ?? '';
    return quotationTypeCode == 'AS02';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // ป้องกัน keyboard บัง content
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'รายละเอียดสินค้า',
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
            _buildProductInfo(context),

            // Realtime Auction Price
            RealtimeAuctionPriceWidget(
              key: realtimePriceKey,
              quotationId: widget.auctionData['quotation_more_information_id']
                      ?.toString() ??
                  widget.auctionData['id'].toString(),
              baseUrl: Config.apiUrlAuction,
              auctionTitle: widget.auctionData['title']?.toString() ??
                  widget.auctionData['short_text']?.toString() ??
                  '',
            ),

            // Product Details
            // _buildProductDetails(context),

            // Item Notes
            _buildItemNotes(context),

            // Seller Info
            _buildSellerInfo(context),

            // Bottom spacing
            SizedBox(
                height: 100), // เพิ่มระยะห่างด้านล่างสำหรับ floating button
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ข้อมูลราคาขั้นต่ำ (ปรับตามประเภทการประมูล)
            Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isReverseAuction() ? Colors.red.withOpacity(0.9) : Colors.blue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _isReverseAuction() ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _isReverseAuction() 
                  ? 'ลดขั้นต่ำ: ${Format.formatCurrency(_latestAuctionData?['minimum_increase'] ?? widget.auctionData['minimum_increase'] ?? 0)}'
                  : 'ขั้นต่ำ: ${Format.formatCurrency(_latestAuctionData?['minimum_increase'] ?? widget.auctionData['minimum_increase'] ?? 0)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // ปุ่มลงประมูลหลัก (ปรับสีตามประเภทการประมูล)
            Container(
              width: 200,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isReverseAuction() 
                    ? [Colors.red, Colors.red.shade700]
                    : [Colors.green, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _isReverseAuction() ? Colors.red.withOpacity(0.4) : Colors.green.withOpacity(0.4),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _onBidPressed(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isReverseAuction() ? Icons.trending_down : Icons.gavel,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _isReverseAuction() ? 'เสนอราคา' : 'ลงประมูล',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ปุ่มยกเลิกการประมูล (แสดงเฉพาะเมื่อเป็นผู้ประมูลล่าสุดและยังอยู่ในช่วง 30 นาที)
           
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
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
                  if (_imageUrls.isNotEmpty) {
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
              if (widget.auctionData['quotation_type_description'] != null && 
                  widget.auctionData['quotation_type_description'].toString().isNotEmpty)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          widget.auctionData['quotation_type_description'].toString(),
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
        // Thumbnail Gallery - แสดงเสมอตามจำนวนรูปที่มี
        if (_imageUrls.isNotEmpty)
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
                            ? context.customTheme.primaryColor
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
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              if (_imageUrls.length > 1)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _imageUrls.length,
                        (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedImageIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                          ),
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

  Widget _buildAuctionImage(String? imagePath,
      {double width = double.infinity, double height = 300}) {
    return AuctionImageWidget(
      imagePath: imagePath,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }

  Widget _buildProductInfo(BuildContext context) {
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

  Widget _buildProductDetails(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายละเอียดสินค้า',
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
            child: Column(
              children: [
                _buildDetailRow(
                    'แบรนด์', widget.auctionData['brand'] ?? 'ไม่ระบุ'),
                _buildDetailRow(
                    'รุ่น', widget.auctionData['model'] ?? 'ไม่ระบุ'),
                _buildDetailRow(
                    'วัสดุ', widget.auctionData['material'] ?? 'ไม่ระบุ'),
                _buildDetailRow(
                    'ขนาด', widget.auctionData['size'] ?? 'ไม่ระบุ'),
                _buildDetailRow('สี', widget.auctionData['color'] ?? 'ไม่ระบุ'),
                _buildDetailRow(
                    'สภาพ', widget.auctionData['condition'] ?? 'ไม่ระบุ'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo(BuildContext context) {
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

  Widget _buildItemNotes(BuildContext context) {
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
}

class RealtimeAuctionPriceWidget extends StatefulWidget {
  final String quotationId;
  final String baseUrl;
  final String? auctionTitle;

  const RealtimeAuctionPriceWidget({
    Key? key,
    required this.quotationId,
    required this.baseUrl,
    this.auctionTitle,
  }) : super(key: key);

  // Helper method to get HTTP client for Android
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

  // Helper method to get base URL for Android
  static String _getBaseUrl(String originalUrl) {
    if (Platform.isAndroid) {
      return originalUrl.replaceFirst('https://', 'http://');
    }
    return originalUrl;
  }

  @override
  _RealtimeAuctionPriceWidgetState createState() =>
      _RealtimeAuctionPriceWidgetState();
}

class _RealtimeAuctionPriceWidgetState
    extends State<RealtimeAuctionPriceWidget> {
  Timer? _timer;
  Map<String, dynamic>? _auctionData;
  bool isLoading = true;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;
  String? _currentUserId;
  String? _currentUserPhone;
  String? _lastProcessedBidKey;
  bool _hasSeededBidHistory = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadCurrentUser();
    _loadAuctionData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      _loadAuctionData();
    });
  }

  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(initializationSettings);
      _notificationsInitialized = true;
      print('🔔 BID_SUCCESS: Notification plugin initialized in realtime widget');
    } catch (e) {
      print('❌ BID_SUCCESS: Failed to initialize notifications: $e');
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('id');
      _currentUserPhone = prefs.getString('phone_number');
      print(
          '🔔 BID_SUCCESS: Loaded current user info (id=$_currentUserId, phone=$_currentUserPhone)');
    } catch (e) {
      print('❌ BID_SUCCESS: Failed to load current user info: $e');
    }
  }

  Future<void> _ensureNotificationSetup() async {
    if (!_notificationsInitialized) {
      await _initializeNotifications();
    }

    if ((_currentUserId == null || _currentUserId!.isEmpty) &&
        (_currentUserPhone == null || _currentUserPhone!.isEmpty)) {
      await _loadCurrentUser();
    }
  }

  String _buildBidKey(Map<String, dynamic> bid) {
    final bidId = bid['bid_id']?.toString();
    if (bidId != null && bidId.isNotEmpty) return bidId;

    final bidTime = bid['bid_time']?.toString() ?? '';
    final bidAmount = bid['bid_amount']?.toString() ?? '';
    final bidder =
        bid['bidder_id']?.toString() ?? bid['bidder_name']?.toString() ?? '';
    return '$bidTime|$bidAmount|$bidder';
  }

  bool _isBidFromCurrentUser(Map<String, dynamic> bid) {
    final bidderId = bid['bidder_id']?.toString();
    final bidderName = bid['bidder_name']?.toString();

    if (bidderId != null &&
        bidderId.isNotEmpty &&
        _currentUserId != null &&
        _currentUserId!.isNotEmpty &&
        bidderId == _currentUserId) {
      return true;
    }

    if (bidderName != null &&
        bidderName.isNotEmpty &&
        _currentUserPhone != null &&
        _currentUserPhone!.isNotEmpty &&
        bidderName == _currentUserPhone) {
      return true;
    }

    return false;
  }

  Future<void> _handleBidNotifications(Map<String, dynamic> data) async {
    try {
      final bidHistory = data['bid_history'];
      if (bidHistory == null || bidHistory is! List || bidHistory.isEmpty) {
        return;
      }

      final latestBidRaw = bidHistory.last;
      if (latestBidRaw is! Map<String, dynamic>) {
        return;
      }

      await _ensureNotificationSetup();

      final bidKey = _buildBidKey(latestBidRaw);

      if (!_hasSeededBidHistory) {
        _lastProcessedBidKey = bidKey;
        _hasSeededBidHistory = true;
        return;
      }

      if (bidKey == _lastProcessedBidKey) {
        return;
      }

      if (_isBidFromCurrentUser(latestBidRaw)) {
        _lastProcessedBidKey = bidKey;
        return;
      }

      if (!_notificationsInitialized) {
        print(
            '⚠️ BID_SUCCESS: Notifications not initialized, skipping notification');
        _lastProcessedBidKey = bidKey;
        return;
      }

      final productTitle = (widget.auctionTitle != null &&
              widget.auctionTitle!.isNotEmpty)
          ? widget.auctionTitle!
          : data['short_text']?.toString() ??
              data['title']?.toString() ??
              'การประมูล';
      final latestPrice = Format.formatCurrency(latestBidRaw['bid_amount']);
      final bidderName =
          latestBidRaw['bidder_name']?.toString() ?? 'ผู้ร่วมประมูล';

      try {
        await sendBidSuccessNotification(
          _notificationsPlugin,
          productTitle,
          latestPrice,
          bidderName,
        );
        print('🎉 BID_SUCCESS: Notification sent for new bid ($bidKey)');
      } catch (e) {
        print('❌ BID_SUCCESS: Error sending bid notification: $e');
      }

      _lastProcessedBidKey = bidKey;
    } catch (e) {
      print('❌ BID_SUCCESS: Error handling bid notifications: $e');
    }
  }

  Future<void> _loadAuctionData() async {
    try {
      final client = RealtimeAuctionPriceWidget._getHttpClient();
      final baseUrl = RealtimeAuctionPriceWidget._getBaseUrl(widget.baseUrl);
      final response = await client.get(
        Uri.parse(
            '$baseUrl/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=${widget.quotationId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          await _handleBidNotifications(data);
          
          // Print เบอร์โทรศัพท์ทั้งหมดที่ bid ในสินค้านี้
          if (data['bid_history'] != null && data['bid_history'] is List) {
            final bidHistory = data['bid_history'] as List;
            print('📱 ========== เบอร์โทรศัพท์ที่ Bid ในสินค้านี้ ==========');
            print('📱 สินค้า: ${widget.auctionTitle ?? data['short_text'] ?? data['title'] ?? 'ไม่ระบุ'}');
            print('📱 Quotation ID: ${widget.quotationId}');
            print('📱 จำนวนผู้ประมูลทั้งหมด: ${bidHistory.length} คน');
            print('📱 ----------------------------------------');
            
            // เก็บ unique เบอร์โทรศัพท์
            final Set<String> uniquePhones = {};
            
            for (int i = 0; i < bidHistory.length; i++) {
              final bid = bidHistory[i];
              final bidderName = bid['bidder_name']?.toString() ?? 'ไม่ระบุ';
              final bidAmount = bid['bid_amount']?.toString() ?? '0';
              final bidTime = bid['bid_time']?.toString() ?? 'ไม่ระบุ';
              
              // เพิ่มเบอร์เข้า unique set
              if (bidderName != 'ไม่ระบุ' && bidderName.isNotEmpty) {
                uniquePhones.add(bidderName);
              }
              
              print('📱 [${i + 1}] เบอร์: $bidderName | ราคา: ${Format.formatCurrency(int.tryParse(bidAmount) ?? 0)} | เวลา: $bidTime');
            }
            
            print('📱 ----------------------------------------');
            print('📱 เบอร์โทรศัพท์ที่ไม่ซ้ำกัน: ${uniquePhones.length} เบอร์');
            print('📱 เบอร์ทั้งหมด: ${uniquePhones.toList().join(", ")}');
            print('📱 ========================================');
          }
        }
        setState(() {
          if (data is Map<String, dynamic> &&
              data['quotation_more_information_id'] != null) {
            _auctionData = data;
          } else {
            _auctionData = null;
          }
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '-';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final formattedString = dateTime.toString().substring(0, 19);
      return formattedString;
    } catch (e) {
      return '-';
    }
  }

  String _maskPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return 'ไม่ระบุ';

    // ลบ whitespace และตรวจสอบว่าเป็นตัวเลขทั้งหมดหรือไม่
    final cleaned = phoneNumber.trim();
    
    // ตรวจสอบว่าเป็นตัวเลขทั้งหมดหรือไม่
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      // ถ้าไม่ใช่ตัวเลขทั้งหมด ให้แสดงตามปกติ
      return phoneNumber;
    }
    
    // ลบ 0 นำหน้าทั้งหมดที่เกิน 1 ตัว
    // เช่น "000000805944670" -> "805944670" หรือ "0000008059" -> "8059"
    String normalized = cleaned;
    if (cleaned.startsWith('0')) {
      // นับจำนวน 0 นำหน้า
      int leadingZeros = 0;
      for (int i = 0; i < cleaned.length; i++) {
        if (cleaned[i] == '0') {
          leadingZeros++;
        } else {
          break;
        }
      }
      
      // ถ้ามี 0 นำหน้ามากกว่า 1 ตัว ให้ลบออกเหลือแค่ 1 ตัว
      // แต่ถ้าเป็น 0 ทั้งหมด ให้แสดงตามปกติ
      if (leadingZeros > 1 && leadingZeros < cleaned.length) {
        // ลบ 0 นำหน้าทั้งหมด แล้วเพิ่ม 0 กลับไป 1 ตัว (ถ้าความยาวพอ)
        normalized = cleaned.substring(leadingZeros);
        // ถ้า normalized ยังมี 8-9 หลัก ให้เพิ่ม 0 นำหน้า 1 ตัว
        if (normalized.length >= 8 && normalized.length <= 9) {
          normalized = '0$normalized';
        }
      }
    }
    
    // ตรวจสอบว่าเป็นเบอร์โทรศัพท์ (มีตัวเลข 8-10 หลัก)
    // รองรับเบอร์ 8 หลัก (เช่น 80594467), 9 หลัก (เช่น 805944670), และ 10 หลัก (เช่น 0805944670)
    if (normalized.length >= 8 && normalized.length <= 10) {
      if (normalized.length >= 4) {
        // Mask 4 หลักสุดท้าย
        final prefix = normalized.substring(0, normalized.length - 4);
        // ตรวจสอบว่า prefix ไม่ใช่ 0 ทั้งหมด (กรณีข้อมูลผิดปกติ)
        if (RegExp(r'^0+$').hasMatch(prefix)) {
          // ถ้า prefix เป็น 0 ทั้งหมด อาจเป็นข้อมูลผิดปกติ ให้แสดงตามปกติ
          return phoneNumber;
        }
        return '$prefix****';
      } else {
        return '****';
      }
    }

    // ถ้าไม่ใช่เบอร์โทรศัพท์ ให้แสดงตามปกติ
    return phoneNumber;
  }

  void updateAuctionData(Map<String, dynamic> newData) {
    setState(() {
      _auctionData = newData;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, color: Colors.green, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ราคาปัจจุบัน (Real-time)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // สรุปข้อมูลการประมูล
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ราคาปัจจุบัน',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                    SizedBox(height: 4),
                    Text(
                      Format.formatCurrency(_auctionData?['current_price'] ?? 0),
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700]),
                    ),
                    if (_auctionData?['remaining_time'] != null &&
                        (_auctionData?['remaining_time'] as String).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer, size: 16, color: Colors.orange),
                              SizedBox(width: 6),
                              Text(
                                _auctionData?['remaining_time'] ?? '-',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Column(
                  children: [
                    Text('ราคาเริ่มต้น',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    SizedBox(height: 4),
                    Text(
                      Format.formatCurrency(_auctionData?['star_price'] ?? 0),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700]),
                    ),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Column(
                  children: [
                    Text('ขั้นต่ำ',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    SizedBox(height: 4),
                    Text(
                      Format.formatCurrency(_auctionData?['minimum_increase'] ?? 0),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          // สถิติการประมูล
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.blue),
                        SizedBox(width: 6),
                        Text(
                          'ผู้ประมูล: ${_auctionData?['number_bidders'] ?? '0'} คน',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.gavel, size: 16, color: Colors.orange),
                        SizedBox(width: 6),
                        Text(
                          'จำนวนครั้ง: ${_auctionData?['total_bids'] ?? '0'} ครั้ง',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.green),
                        SizedBox(width: 6),
                        Text(
                          'อัปเดตล่าสุด: ${_formatTime(_auctionData?['last_updated']).length >= 19 ? _formatTime(_auctionData?['last_updated']).substring(11, 19) : _formatTime(_auctionData?['last_updated'])}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Live',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          if (_auctionData?['bid_history'] != null &&
              (_auctionData?['bid_history'] as List).isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ประวัติการประมูล',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '${(_auctionData?['bid_history'] as List).length} รายการ',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  height: 120,
                  child: ListView.builder(
                    itemCount: (_auctionData?['bid_history'] as List).length,
                    itemBuilder: (context, index) {
                      // Reverse index เพื่อให้รายการล่าสุดอยู่บนสุด
                      final reversedIndex =
                          (_auctionData?['bid_history'] as List).length -
                              1 -
                              index;
                      final bid =
                          (_auctionData?['bid_history'] as List)[reversedIndex];
                      final isLatestBid = index ==
                          0; // รายการล่าสุด (ตอนนี้ index 0 จะเป็นรายการล่าสุด)
                      
                      // Print ข้อมูล bid แต่ละรายการ
                      final bidderName = bid['bidder_name']?.toString() ?? 'ไม่ระบุ';
                      final bidAmount = bid['bid_amount']?.toString() ?? '0';
                      print('🔍 UI Render - Bid #${index + 1}: เบอร์=$bidderName, ราคา=${Format.formatCurrency(int.tryParse(bidAmount) ?? 0)}, isLatest=$isLatestBid');
                      return Container(
                        margin: EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isLatestBid
                              ? Colors.green.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isLatestBid
                              ? Border.all(color: Colors.green.withOpacity(0.3))
                              : null,
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  isLatestBid ? Colors.green : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 16,
                              color:
                                  isLatestBid ? Colors.white : Colors.grey[600],
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                Format.formatCurrency(bid['bid_amount']),
                                style: TextStyle(
                                  fontWeight: isLatestBid
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isLatestBid
                                      ? Colors.green[700]
                                      : Colors.black,
                                ),
                              ),
                              if (isLatestBid) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'ล่าสุด',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                              'โดย: ${_maskPhoneNumber(bid['bidder_name']?.toString())}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatTime(bid['bid_time']).length >= 19
                                    ? _formatTime(bid['bid_time'])
                                        .substring(11, 19)
                                    : _formatTime(
                                        bid['bid_time']), // แสดงเฉพาะเวลา
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                _formatTime(bid['bid_time']).length >= 10
                                    ? _formatTime(bid['bid_time'])
                                        .substring(0, 10)
                                    : _formatTime(
                                        bid['bid_time']), // แสดงเฉพาะวันที่
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

bool isAuctionEnded(Map<String, dynamic> auction) {
  final endTime = auction['auctionEndTime'];
  if (endTime == null || endTime.isEmpty) return false;
  try {
    final end = DateTime.parse(endTime);
    return DateTime.now().isAfter(end);
  } catch (_) {
    return false;
  }
}
