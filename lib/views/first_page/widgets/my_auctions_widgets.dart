import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/services/auth_service/auth_service.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/utils/regexvalidator.dart';
import 'package:flutter/services.dart';
import 'package:e_auction/services/product_service.dart';
import 'package:e_auction/views/first_page/auction_page/auction_detail_view_page.dart';
import 'package:e_auction/views/first_page/widgets/my_auctions_widget.dart' as dialogs;
import 'package:e_auction/views/first_page/detail_page/detail_page.dart';
import 'package:e_auction/views/first_page/detail_page/detail_completed.dart';
import 'package:e_auction/services/winner_service.dart';

// Helper method to build auction image
Widget _buildAuctionImage(String? imagePath,
    {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (imagePath == null || imagePath.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
    );
  }

  // Check if the image path is a network URL
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return Image.network(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
        );
      },
    );
  } else {
    // Treat as local asset
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
        );
      },
    );
  }
}

// ฟังก์ชันเลือกภาพที่ถูกต้องแบบ async (ใช้ ProductService.convertToAppFormat เหมือนหน้า home)
Future<String> getAuctionImageWithFallback(Map<String, dynamic> auction) async {
  final productService = ProductService(baseUrl: Config.apiUrlAuction);

  try {
    // ดึงข้อมูลจาก getAllQuotations() เหมือนหน้า home
    final allQuotations = await productService.getAllQuotations();
    final quotationId =
        auction['quotation_more_information_id'] ?? auction['id'];

    // หา quotation ที่ตรงกับ ID
    final matchingQuotation = allQuotations?.firstWhere(
      (q) =>
          q['quotation_more_information_id']?.toString() ==
          quotationId.toString(),
      orElse: () => <String, dynamic>{},
    );

    if (matchingQuotation != null && matchingQuotation.isNotEmpty) {
      // ใช้ ProductService.convertToAppFormat เหมือนหน้า home
      final formattedAuctionData =
          productService.convertToAppFormat(matchingQuotation);
      final imageUrl =
          formattedAuctionData['image'] ?? 'assets/images/noimage.jpg';
      return imageUrl;
    } else {
      return 'assets/images/noimage.jpg';
    }
  } catch (e) {
    return 'assets/images/noimage.jpg';
  }
}

// Empty State Widget
Widget buildEmptyState(
    {required IconData icon, required String title, required String subtitle}) {
  return Center(
    child: Container(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 48, color: Colors.grey[400]),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// Active Bid Card Widget
class ActiveBidCard extends StatelessWidget {
  final Map<String, dynamic> auction;
  final VoidCallback onTap;
  final Color Function(String) getStatusColor;
  final String Function(String) getStatusText;
  final bool small;

  const ActiveBidCard({
    super.key,
    required this.auction,
    required this.onTap,
    required this.getStatusColor,
    required this.getStatusText,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    // ตรวจสอบ type ของ auction
    final typeCode = auction['quotation_type_code'] ?? auction['type_code'];
    final isAS03 = typeCode == 'AS03';
    
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: small ? 8 : 16, vertical: small ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(small ? 12 : 16),
          child: Row(
            children: [
              // รูปภาพ
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder<String>(
                  future: getAuctionImageWithFallback(auction),
                  builder: (context, snapshot) {
                    final imageUrl = snapshot.data ?? 'assets/images/noimage.jpg';
                    return _buildAuctionImage(imageUrl,
                        width: small ? 60 : 80, height: small ? 60 : 80);
                  },
                ),
              ),
              SizedBox(width: 16),
              // ข้อมูล
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // หัวข้อและป้าย
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            auction['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: small ? 14 : 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        if (isAS03)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.trending_down, color: Colors.purple, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'ลดจำนวน',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // ข้อมูลรายละเอียด
                    if (isAS03) ...[
                      // สำหรับ AS03 แสดงข้อมูลการจอง
                      Text(
                        'จำนวนที่จอง: ${auction['quantity_requested'] ?? auction['myBid'] ?? 0} รายการ',
                        style: TextStyle(fontSize: small ? 12 : 14, color: Colors.purple[700], fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ราคาต่อชิ้น: ${Format.formatCurrency(auction['currentPrice'])}',
                        style: TextStyle(fontSize: small ? 12 : 14, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ยอดรวม: ${Format.formatCurrency((auction['quantity_requested'] ?? 0) * (auction['currentPrice'] ?? 0))}',
                        style: TextStyle(fontSize: small ? 12 : 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                      ),
                    ] else ...[
                      // สำหรับ auction ปกติ
                      Text(
                        'การประมูลของฉัน: ${Format.formatCurrency(auction['myBid'])}',
                        style: TextStyle(fontSize: small ? 12 : 14, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ราคาปัจจุบัน: ${Format.formatCurrency(auction['currentPrice'])}',
                        style: TextStyle(fontSize: small ? 12 : 14, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${auction['timeRemaining']} • อันดับที่ ${auction['myBidRank']}',
                        style: TextStyle(fontSize: small ? 12 : 14, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12),
              // สถานะ
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isAS03 ? Colors.purple : getStatusColor(auction['status'] ?? 'unknown'),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isAS03 ? 'จองแล้ว' : getStatusText(auction['status'] ?? 'unknown'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: small ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Won Auction Card Widget
Widget buildWonAuctionCard(
  BuildContext context,
  Map<String, dynamic> auction,
  Future<bool> Function() hasWinnerInfo,
  Future<void> Function(Map<String, dynamic>) loadProfileAndShowDialog,
) {
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () async {
      final productService = ProductService(baseUrl: Config.apiUrlAuction);
      final quotationId =
          auction['quotation_more_information_id'] ?? auction['id'];

      // ดึงข้อมูลจาก getAllQuotations() เหมือนหน้า home
      final allQuotations = await productService.getAllQuotations();

      // หา quotation ที่ตรงกับ ID
      final matchingQuotation = allQuotations?.firstWhere(
        (q) =>
            q['quotation_more_information_id']?.toString() ==
            quotationId.toString(),
        orElse: () => <String, dynamic>{},
      );

      Map<String, dynamic> formattedAuctionData;
      if (matchingQuotation != null && matchingQuotation.isNotEmpty) {
        formattedAuctionData = productService.convertToAppFormat(matchingQuotation);
      } else {
        formattedAuctionData = Map<String, dynamic>.from(auction);
      }

      // ดึงข้อมูลผู้ชนะจาก SharedPreferences (ข้อมูลที่ผู้ใช้กรอกในฟอร์ม)
      try {
        final prefs = await SharedPreferences.getInstance();
        final firstname = prefs.getString('winner_firstname') ?? '';
        final lastname = prefs.getString('winner_lastname') ?? '';
        final phone = prefs.getString('winner_phone') ?? '';
        
        if (firstname.isNotEmpty || lastname.isNotEmpty) {
          final fullName = '${firstname} ${lastname}'.trim();
          // Map winner data to the keys that detail_completed.dart expects
          formattedAuctionData['winner_firstname'] = firstname;
          formattedAuctionData['winner_lastname'] = lastname;
          formattedAuctionData['winner'] = fullName;
          formattedAuctionData['winnerName'] = fullName;
          formattedAuctionData['winner_name'] = fullName;
          formattedAuctionData['winner_phone'] = phone;
          formattedAuctionData['winnerPhone'] = phone;
        } else {
          // Fallback: ดึงข้อมูลผู้ชนะจาก WinnerService ถ้าไม่มีข้อมูลใน SharedPreferences
          final winnerData = await WinnerService.getWinnerByAuctionId(quotationId.toString());
          if (winnerData != null && winnerData['data'] != null) {
            final winner = winnerData['data'];
            formattedAuctionData['winner_firstname'] = winner['winner_firstname'];
            formattedAuctionData['winner_lastname'] = winner['winner_lastname'];
            formattedAuctionData['winner'] = '${winner['winner_firstname'] ?? ''} ${winner['winner_lastname'] ?? ''}'.trim();
            formattedAuctionData['winnerName'] = '${winner['winner_firstname'] ?? ''} ${winner['winner_lastname'] ?? ''}'.trim();
            formattedAuctionData['winner_name'] = '${winner['winner_firstname'] ?? ''} ${winner['winner_lastname'] ?? ''}'.trim();
            formattedAuctionData['winner_phone'] = winner['winner_phone'];
            formattedAuctionData['winnerPhone'] = winner['winner_phone'];
          }
        }
      } catch (e) {
        // ไม่ต้อง throw error ให้ user เห็น
        print('Error fetching winner data: $e');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailCompleted(auctionData: formattedAuctionData),
        ),
      );
    },
    child: Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<String>(
                future: getAuctionImageWithFallback(auction),
                builder: (context, snapshot) {
                  final imageUrl = snapshot.data ?? 'assets/images/noimage.jpg';
                  return _buildAuctionImage(imageUrl, width: 60, height: 60);
                },
              ),
            ),
            SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.emoji_events,
                          size: 14, color: Colors.green[600]),
                      SizedBox(width: 4),
                      Text(
                        'ชนะการประมูล',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'ราคาสุดท้าย: ${Format.formatCurrency(auction['finalPrice'])}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${auction['completedDate']} • ${auction['sellerName']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  if (auction['paymentStatus'] == 'pending')
                    FutureBuilder<bool>(
                      future: _isAppleTestAccount(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            height: 32,
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey[400]!),
                                ),
                              ),
                            ),
                          );
                        }
                        final isAppleTest = snapshot.data ?? false;

                        // ไม่แสดงปุ่มกรอกข้อมูลสำหรับ Apple test account
                        if (isAppleTest) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info,
                                    size: 16, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  'บัญชีทดสอบ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return FutureBuilder<bool>(
                          future: hasWinnerInfo(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                height: 32,
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.grey[400]!),
                                    ),
                                  ),
                                ),
                              );
                            }
                            final hasCompleteInfo = snapshot.data ?? false;
                            if (hasCompleteInfo) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.08),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          onTap: () async {
                                            if (await validateWinnerInfo(
                                                context)) {
                                              dialogs.AuctionDialogs.showPaymentDialog(
                                                  context, auction);
                                            }
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 4, horizontal: 0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.credit_card,
                                                    color: Colors.black,
                                                    size: 16),
                                                SizedBox(width: 2),
                                                Text(
                                                  'ติดต่อชำระเงิน',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () async {
                                      await loadProfileAndShowDialog(auction);
                                    },
                                    icon: Icon(Icons.edit,
                                        size: 16, color: Colors.grey[600]),
                                    label: Text('แก้ไขข้อมูลผู้ชนะ',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w600)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey[600],
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return ElevatedButton.icon(
                                onPressed: () async {
                                  await loadProfileAndShowDialog(auction);
                                },
                                icon: Icon(Icons.edit,
                                    size: 16, color: Colors.black),
                                label: Text('กรอกข้อมูลผู้ชนะ',
                                    style: TextStyle(color: Colors.black)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.black.withOpacity(0.3),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  if (auction['paymentStatus'] == 'paid')
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: Colors.green[600]),
                          SizedBox(width: 4),
                          Text(
                            'ชำระเงินแล้ว',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Status
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ชนะ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> _isAppleTestAccount() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('id') ?? '';
  final phoneNumber = prefs.getString('phone') ?? '';

  return userId == 'APPLE_TEST_ID' || phoneNumber == '0001112345';
}

Future<bool> validateWinnerInfo(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final firstname = prefs.getString('winner_firstname') ?? '';
  final lastname = prefs.getString('winner_lastname') ?? '';
  final phone = prefs.getString('winner_phone') ?? '';
  final address = prefs.getString('winner_address') ?? '';
  final provinceId = prefs.getString('winner_province_id') ?? '';
  final districtId = prefs.getString('winner_district_id') ?? '';
  final subDistrictId = prefs.getString('winner_sub_district_id') ?? '';

  if (firstname.isEmpty ||
      lastname.isEmpty ||
      phone.isEmpty ||
      address.isEmpty ||
      provinceId.isEmpty ||
      districtId.isEmpty ||
      subDistrictId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('กรุณากรอกข้อมูลผู้ชนะให้ครบถ้วน'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }
  
  // ตรวจสอบข้อมูลที่อยู่ใหม่ (ไม่บังคับ แต่แนะนำ)
  final village = prefs.getString('winner_village') ?? '';
  final road = prefs.getString('winner_road') ?? '';
  final postalCode = prefs.getString('winner_postal_code') ?? '';
  final country = prefs.getString('winner_country') ?? '';
  
  // แสดงคำแนะนำถ้าข้อมูลที่อยู่ใหม่ไม่ครบ
  if (village.isEmpty || road.isEmpty || postalCode.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('แนะนำให้กรอกข้อมูลที่อยู่เพิ่มเติมเพื่อความสมบูรณ์'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  return true;
} 