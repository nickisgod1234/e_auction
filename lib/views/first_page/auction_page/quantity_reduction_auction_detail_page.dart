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
  final GlobalKey<_QuantityReductionRealtimeWidgetState> realtimeKey =
      GlobalKey<_QuantityReductionRealtimeWidgetState>();
  Map<String, dynamic>? _latestAuctionData;
  bool _isJoining = false;
  bool _hasJoined = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkIfUserHasJoined();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadLatestData();
    });
  }

  Future<void> _loadLatestData() async {
    try {
      final client = _getHttpClient();
      final baseUrl = _getBaseUrl();
      final quotationId = widget.auctionData['quotation_more_information_id']?.toString() ?? 
                         widget.auctionData['id'].toString();
      
      final response = await client.get(
        Uri.parse('$baseUrl/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=$quotationId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['quotation_more_information_id'] != null) {
          setState(() {
            _latestAuctionData = data;
          });
          realtimeKey.currentState?.updateData(data);
        }
      }
    } catch (e) {
      print('Error loading latest data: $e');
    }
  }

  Future<void> _checkIfUserHasJoined() async {
    // TODO: ตรวจสอบว่าผู้ใช้เข้าร่วมการประมูลนี้แล้วหรือไม่
    // ใช้ API หรือ SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id') ?? '';
    final quotationId = widget.auctionData['quotation_more_information_id']?.toString() ?? 
                       widget.auctionData['id'].toString();
    
    // ตรวจสอบจาก SharedPreferences หรือ API
    final joinedAuctions = prefs.getStringList('joined_quantity_reduction_auctions') ?? [];
    
    // ดึงจำนวนสินค้าที่เหลือจาก SharedPreferences
    final remainingQuantity = prefs.getInt('quantity_${quotationId}') ?? widget.auctionData['quantity'] ?? 0;
    
    setState(() {
      _hasJoined = joinedAuctions.contains(quotationId);
      // อัปเดตจำนวนสินค้าใน _latestAuctionData ถ้ามี
      if (_latestAuctionData != null) {
        _latestAuctionData!['remaining_quantity'] = remainingQuantity;
      }
    });
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

  // แสดง Dialog ยืนยันการเข้าร่วม
  void _showJoinConfirmationDialog() {
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
              child: Icon(Icons.trending_down, color: Colors.purple, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'ยืนยันการเข้าร่วม',
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
              'คุณต้องการเข้าร่วมการประมูลแบบลดจำนวนนี้หรือไม่?',
              style: TextStyle(fontSize: 16),
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
                    '📋 กติกาการประมูล:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• เมื่อเข้าร่วมแล้ว ไม่สามารถยกเลิกได้'),
                  Text('• ราคาจะลดลงอัตโนมัติตามเวลาที่กำหนด'),
                  Text('• ผู้ที่เข้าร่วมก่อนจะได้สิทธิ์ซื้อก่อน'),
                  Text('• จำนวนสินค้าจำกัด: ${widget.auctionData['quantity'] ?? 0} รายการ'),
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
              Navigator.pop(context);
              _joinAuction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('เข้าร่วม'),
          ),
        ],
      ),
    );
  }

  // เข้าร่วมการประมูล
  Future<void> _joinAuction() async {
    if (_isJoining) return;

    setState(() {
      _isJoining = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id') ?? '';
      final userPhone = prefs.getString('phone_number') ?? '';
      final quotationId = widget.auctionData['quotation_more_information_id']?.toString() ?? 
                         widget.auctionData['id'].toString();

      // TODO: เรียก API เพื่อเข้าร่วมการประมูลและลดจำนวนสินค้า
      // final productService = ProductService(baseUrl: _getBaseUrl());
      // final result = await productService.joinQuantityReductionAuction(
      //   quotationId: quotationId,
      //   userId: userId,
      //   userPhone: userPhone,
      // );

      // จำลองการเข้าร่วมสำเร็จและลดจำนวนสินค้า
      await Future.delayed(Duration(seconds: 2));

      // ลดจำนวนสินค้าในข้อมูลปัจจุบัน
      final currentQuantity = _latestAuctionData?['remaining_quantity'] ?? widget.auctionData['quantity'] ?? 0;
      final newQuantity = currentQuantity - 1;
      
      // อัปเดตข้อมูลใน SharedPreferences
      final joinedAuctions = prefs.getStringList('joined_quantity_reduction_auctions') ?? [];
      if (!joinedAuctions.contains(quotationId)) {
        joinedAuctions.add(quotationId);
        await prefs.setStringList('joined_quantity_reduction_auctions', joinedAuctions);
      }

      // อัปเดตจำนวนสินค้าใน SharedPreferences
      await prefs.setInt('quantity_${quotationId}', newQuantity);

      setState(() {
        _hasJoined = true;
        _isJoining = false;
        // อัปเดตข้อมูลใน _latestAuctionData
        if (_latestAuctionData != null) {
          _latestAuctionData!['remaining_quantity'] = newQuantity;
        }
      });

      _showCustomToast(context, 'เข้าร่วมการประมูลสำเร็จ! จำนวนสินค้าเหลือ $newQuantity รายการ', isSuccess: true);

      // ส่งแจ้งเตือน
      _sendJoinNotification();

    } catch (e) {
      setState(() {
        _isJoining = false;
      });
      _showCustomToast(context, 'เกิดข้อผิดพลาดในการเข้าร่วม', isSuccess: false);
    }
  }

  // แสดง Dialog ยืนยันการรีเซท
  void _showResetConfirmationDialog() {
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.refresh, color: Colors.orange, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'รีเซทการเข้าร่วม',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
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
              'คุณต้องการรีเซทการเข้าร่วมการประมูลนี้หรือไม่?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ คำเตือน (สำหรับทดสอบเท่านั้น):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• จะลบสถานะการเข้าร่วมออก'),
                  Text('• จะรีเซทจำนวนสินค้ากลับเป็นค่าเริ่มต้น'),
                  Text('• สามารถเข้าร่วมใหม่ได้'),
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
              Navigator.pop(context);
              _resetJoinStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('รีเซท'),
          ),
        ],
      ),
    );
  }

  // รีเซทสถานะการเข้าร่วม
  Future<void> _resetJoinStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quotationId = widget.auctionData['quotation_more_information_id']?.toString() ?? 
                         widget.auctionData['id'].toString();
      final originalQuantity = widget.auctionData['quantity'] ?? 0;

      // ลบการเข้าร่วมออกจาก SharedPreferences
      final joinedAuctions = prefs.getStringList('joined_quantity_reduction_auctions') ?? [];
      joinedAuctions.remove(quotationId);
      await prefs.setStringList('joined_quantity_reduction_auctions', joinedAuctions);

      // รีเซทจำนวนสินค้ากลับเป็นค่าเริ่มต้น
      await prefs.remove('quantity_${quotationId}');

      setState(() {
        _hasJoined = false;
        // อัปเดตข้อมูลใน _latestAuctionData
        if (_latestAuctionData != null) {
          _latestAuctionData!['remaining_quantity'] = originalQuantity;
        }
      });

      _showCustomToast(context, 'รีเซทการเข้าร่วมสำเร็จ! จำนวนสินค้า: $originalQuantity รายการ', isSuccess: true);

    } catch (e) {
      _showCustomToast(context, 'เกิดข้อผิดพลาดในการรีเซท', isSuccess: false);
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
    final url = Config.apiUrlAuction;
    if (Platform.isAndroid) {
      return url.replaceFirst('https://', 'http://');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final currentPrice = _latestAuctionData?['current_price'] ?? widget.auctionData['currentPrice'] ?? 0;
    final startingPrice = _latestAuctionData?['star_price'] ?? widget.auctionData['startingPrice'] ?? 0;
    final quantity = widget.auctionData['quantity'] ?? 0;
    final remainingQuantity = _latestAuctionData?['remaining_quantity'] ?? quantity;

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
          // ปุ่มรีเซทสำหรับทดสอบ
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: () {
              _showResetConfirmationDialog();
            },
            tooltip: 'รีเซทการเข้าร่วม (สำหรับทดสอบ)',
          ),
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

            // Realtime Price Widget
            QuantityReductionRealtimeWidget(
              key: realtimeKey,
              quotationId: widget.auctionData['quotation_more_information_id']?.toString() ?? 
                          widget.auctionData['id'].toString(),
              baseUrl: Config.apiUrlAuction,
            ),

            // Quantity Info
            _buildQuantityInfo(remainingQuantity, quantity),

            // Product Details
            _buildProductDetails(),

            // Item Notes
            _buildItemNotes(),

            // Seller Info
            _buildSellerInfo(),

            // Bottom spacing
            SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ข้อมูลจำนวนสินค้า
            Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'จำนวนสินค้า: $remainingQuantity รายการ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // ปุ่มเข้าร่วมหลัก
            Container(
              width: 200,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _hasJoined 
                    ? [Colors.grey, Colors.grey.shade600]
                    : [Colors.purple, Colors.purple.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (_hasJoined ? Colors.grey : Colors.purple).withOpacity(0.4),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _hasJoined ? null : (_isJoining ? null : _showJoinConfirmationDialog),
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
                    if (_isJoining)
                      Container(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _hasJoined ? Icons.check_circle : Icons.trending_down,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    SizedBox(width: 8),
                    Text(
                      _hasJoined ? 'เข้าร่วมแล้ว' : (_isJoining ? 'กำลังเข้าร่วม...' : 'เข้าร่วมประมูล'),
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
      child: Stack(
        children: [
          _buildAuctionImage(widget.auctionData['image'], width: double.infinity, height: 300),
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

  Widget _buildQuantityInfo(int remainingQuantity, int totalQuantity) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
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
                  'เหลือ $remainingQuantity จาก $totalQuantity รายการ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (totalQuantity - remainingQuantity) / totalQuantity,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
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
                _buildDetailRow('แบรนด์', widget.auctionData['brand'] ?? 'ไม่ระบุ'),
                _buildDetailRow('รุ่น', widget.auctionData['model'] ?? 'ไม่ระบุ'),
                _buildDetailRow('วัสดุ', widget.auctionData['material'] ?? 'ไม่ระบุ'),
                _buildDetailRow('ขนาด', widget.auctionData['size'] ?? 'ไม่ระบุ'),
                _buildDetailRow('สี', widget.auctionData['color'] ?? 'ไม่ระบุ'),
                _buildDetailRow('สภาพ', widget.auctionData['condition'] ?? 'ไม่ระบุ'),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
}

class QuantityReductionRealtimeWidget extends StatefulWidget {
  final String quotationId;
  final String baseUrl;

  const QuantityReductionRealtimeWidget({
    Key? key,
    required this.quotationId,
    required this.baseUrl,
  }) : super(key: key);

  @override
  _QuantityReductionRealtimeWidgetState createState() => _QuantityReductionRealtimeWidgetState();
}

class _QuantityReductionRealtimeWidgetState extends State<QuantityReductionRealtimeWidget> {
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
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadAuctionData();
    });
  }

  Future<void> _loadAuctionData() async {
    try {
      final client = _getHttpClient();
      final baseUrl = _getBaseUrl();
      final response = await client.get(
        Uri.parse('$baseUrl/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=${widget.quotationId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data is Map<String, dynamic> && data['quotation_more_information_id'] != null) {
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

  void updateData(Map<String, dynamic> newData) {
    setState(() {
      _auctionData = newData;
      isLoading = false;
    });
  }

  // Helper method to get HTTP client for Android
  http.Client _getHttpClient() {
    if (Platform.isAndroid) {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true;
      };
      return IOClient(client);
    } else {
      return http.Client();
    }
  }

  // Helper method to get base URL for Android
  String _getBaseUrl() {
    if (Platform.isAndroid) {
      return widget.baseUrl.replaceFirst('https://', 'http://');
    }
    return widget.baseUrl;
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
          colors: [Colors.purple.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
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
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2, color: Colors.purple, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'จำนวนสินค้า (Real-time)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
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
                    Text('จำนวนสินค้า',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    SizedBox(height: 4),
                    Text(
                      '${_auctionData?['remaining_quantity'] ?? 0} รายการ',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700]),
                    ),
                    if (_auctionData?['remaining_time'] != null &&
                        (_auctionData?['remaining_time'] as String).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
                    Text('ผู้เข้าร่วม',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    SizedBox(height: 4),
                    Text(
                      '${_auctionData?['number_bidders'] ?? '0'} คน',
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
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.purple),
                    SizedBox(width: 6),
                    Text(
                      'ผู้เข้าร่วม: ${_auctionData?['number_bidders'] ?? '0'} คน',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Live',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.purple[700],
                        fontWeight: FontWeight.bold),
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