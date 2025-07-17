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
import 'package:e_auction/views/first_page/widgets/auction_bid_dialog.dart';
import 'package:e_auction/views/first_page/widgets/auction_pending_bid_dialog.dart';
import 'package:e_auction/utils/loading_service.dart';

class AuctionDetailViewPage extends StatefulWidget {
  final Map<String, dynamic> auctionData;

  AuctionDetailViewPage({super.key, required this.auctionData});

  @override
  _AuctionDetailViewPageState createState() => _AuctionDetailViewPageState();
}

class _AuctionDetailViewPageState extends State<AuctionDetailViewPage> {
  final GlobalKey<_RealtimeAuctionPriceWidgetState> realtimePriceKey =
      GlobalKey<_RealtimeAuctionPriceWidgetState>();
  Map<String, dynamic>? _latestAuctionData;

  // Add a static variable to track the disclaimer popup state
  static bool _hideDisclaimer = false;
  
  // Timer สำหรับอัปเดตเวลาที่เหลือในการยกเลิก
  Timer? _cancelTimer;
  
  // เพิ่มตัวแปรสำหรับระบบ hold bid
  Map<String, dynamic>? _pendingBid;
  Timer? _pendingBidTimer;
  bool _isPendingBidConfirmed = false;

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
    showDialog(
      context: context,
      barrierDismissible: false,
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
  }

  // เพิ่มเมธอดสำหรับแสดง dialog ลงประมูล
  void _showBidDialog(BuildContext context) async {
    final productService = ProductService(baseUrl: _getBaseUrl());
    final quotationId =
        widget.auctionData['quotation_more_information_id']?.toString() ??
            widget.auctionData['id'].toString();

    try {
      final url =
          '${_getBaseUrl()}/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=$quotationId';

      final response = await LoadingService.showLoadingWhile(context, () async {
        final client = _getHttpClient();
        return await client.get(Uri.parse(url));
      });

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
      
      final result = await LoadingService.showLoadingWhile(context, () async {
        return await productService.placeBid(
          quotationId: _pendingBid!['quotationId'],
          minimumIncrease: _pendingBid!['minimumIncrease'],
          bidAmount: _pendingBid!['bidAmount'],
          bidderId: _pendingBid!['bidderId'],
          bidderName: _pendingBid!['bidderName'],
        );
      });

              if (result != null && result['status'] == 'success') {
          // รอให้แน่ใจว่า loading dialog ปิดสนิทแล้ว
          await Future.delayed(Duration(milliseconds: 100));
          if (mounted) {
            _showSuccessDialog(context, 'ลงประมูลสำเร็จ! ${result['data']['calculation'] ?? ''}');
          }

          // ดึงข้อมูลล่าสุดและอัปเดต real-time
          try {
            final latestUrl =
                '${_getBaseUrl()}/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=${_pendingBid!['quotationId']}';
            final latestResponse = await LoadingService.showLoadingWhile(context, () async {
              final client = _getHttpClient();
              return await client.get(Uri.parse(latestUrl));
            });

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
            ),

            // Product Details
            _buildProductDetails(context),

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
            // ข้อมูลราคาขั้นต่ำ
            Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'ขั้นต่ำ: ${Format.formatCurrency(_latestAuctionData?['minimum_increase'] ?? widget.auctionData['minimum_increase'] ?? 0)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // ปุ่มลงประมูลหลัก
            Container(
              width: 200,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
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
                        Icons.gavel,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ลงประมูล',
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
    return Container(
      width: double.infinity,
      height: 300,
      child: _buildAuctionImage(widget.auctionData['image'],
          width: double.infinity, height: 300),
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

  const RealtimeAuctionPriceWidget({
    Key? key,
    required this.quotationId,
    required this.baseUrl,
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

  @override
  void initState() {
    super.initState();
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

    // ถ้าเป็นเบอร์โทรศัพท์ (มีตัวเลข 10 หลัก)
    if (phoneNumber.length >= 10 && RegExp(r'^\d+$').hasMatch(phoneNumber)) {
      if (phoneNumber.length >= 4) {
        return '${phoneNumber.substring(0, phoneNumber.length - 4)}****';
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
                              'โดย: ${_maskPhoneNumber(bid['bidder_name'])}'),
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
