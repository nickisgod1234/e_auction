import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/views/first_page/widgets/auction_dialogs.dart';
import 'dart:async';

// Helper function to build auction image widget
Widget _buildAuctionImage(String imagePath, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
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

// Auction Card Widgets
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
    return Card(
      margin: EdgeInsets.symmetric(horizontal: small ? 4 : 16, vertical: small ? 6 : 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildAuctionImage(
            auction['image'],
            width: small ? 44 : 60,
            height: small ? 44 : 60,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: small ? 8 : 16, vertical: small ? 6 : 8),
        title: Text(
          auction['title'],
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: small ? 14 : 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('การประมูลของฉัน: ${Format.formatCurrency(auction['myBid'])}', style: TextStyle(fontSize: small ? 12 : 14)),
            Text('ราคาปัจจุบัน: ${Format.formatCurrency(auction['currentPrice'])}', style: TextStyle(fontSize: small ? 12 : 14)),
            Text('${auction['timeRemaining']} • อันดับที่ ${auction['myBidRank']}', style: TextStyle(fontSize: small ? 12 : 14)),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: getStatusColor(auction['status'] ?? 'unknown'),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            getStatusText(auction['status'] ?? 'unknown'),
            style: TextStyle(color: Colors.white, fontSize: small ? 10 : 12, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class WonAuctionCard extends StatelessWidget {
  final Map<String, dynamic> auction;
  final VoidCallback onPaymentTap;
  final bool small;

  const WonAuctionCard({
    super.key,
    required this.auction,
    required this.onPaymentTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: small ? 4 : 16, vertical: small ? 6 : 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildAuctionImage(
            auction['image'],
            width: small ? 44 : 60,
            height: small ? 44 : 60,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: small ? 8 : 16, vertical: small ? 6 : 8),
        title: Text(
          auction['title'],
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: small ? 14 : 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ราคาสุดท้าย: ${Format.formatCurrency(auction['finalPrice'])}', style: TextStyle(fontSize: small ? 12 : 14)),
            Text('${auction['completedDate']} • ${auction['sellerName']}', style: TextStyle(fontSize: small ? 12 : 14)),
            Text(
              'เลขที่ประมูล: ${auction['auctionId']}',
              style: TextStyle(
                fontSize: small ? 10 : 12,
                color: Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              auction['paymentStatus'] == 'paid' ? 'ชำระเงินแล้ว' : 'รอชำระเงิน',
              style: TextStyle(
                color: auction['paymentStatus'] == 'paid' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: small ? 12 : 14,
              ),
            ),
            if (auction['paymentStatus'] == 'pending')
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  onPressed: onPaymentTap,
                  icon: Icon(Icons.edit, size: small ? 14 : 16),
                  label: Text('กรอกข้อมูลผู้ชนะ', style: TextStyle(fontSize: small ? 12 : 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size(0, small ? 28 : 32),
                  ),
                ),
              ),
            if (auction['paymentStatus'] == 'paid')
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.check_circle, size: small ? 14 : 16),
                  label: Text('ชำระเงินแล้ว', style: TextStyle(fontSize: small ? 12 : 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.grey[600],
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size(0, small ? 28 : 32),
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                  ),
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'ชนะ',
            style: TextStyle(color: Colors.white, fontSize: small ? 10 : 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class LostAuctionCard extends StatelessWidget {
  final Map<String, dynamic> auction;
  final bool small;

  const LostAuctionCard({
    super.key,
    required this.auction,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: small ? 4 : 16, vertical: small ? 6 : 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildAuctionImage(
            auction['image'],
            width: small ? 44 : 60,
            height: small ? 44 : 60,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: small ? 8 : 16, vertical: small ? 6 : 8),
        title: Text(
          auction['title'],
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: small ? 14 : 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sentiment_dissatisfied, size: small ? 12 : 14, color: Colors.red[600]),
                SizedBox(width: 4),
                Text(
                  'ไม่ชนะการประมูล',
                  style: TextStyle(
                    fontSize: small ? 12 : 14,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text('การประมูลของฉัน: ${Format.formatCurrency(auction['myBid'])}', style: TextStyle(fontSize: small ? 12 : 14)),
            Text('ราคาที่ชนะ: ${Format.formatCurrency(auction['winnerBid'])}', style: TextStyle(fontSize: small ? 12 : 14, fontWeight: FontWeight.w600, color: Colors.red[600])),
            Text('${auction['completedDate']} • ${auction['sellerName']}', style: TextStyle(fontSize: small ? 12 : 14, color: Colors.grey[600])),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'ไม่ชนะ',
            style: TextStyle(color: Colors.white, fontSize: small ? 10 : 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// CountdownTimerWidget: แสดงเวลานับถอยหลังแบบ real-time
class CountdownTimerWidget extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? style;
  const CountdownTimerWidget({Key? key, required this.endTime, this.style}) : super(key: key);

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    setState(() {
      _remaining = widget.endTime.difference(now);
      if (_remaining.isNegative) _remaining = Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;
    return Text(
      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: widget.style ?? TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
    );
  }
}

// Enhanced Won Auction Card with Apple Test Account Support
Widget buildWonAuctionCard(
  BuildContext context,
  Map<String, dynamic> auction,
  Future<bool> Function() hasWinnerInfo,
  Future<void> Function(Map<String, dynamic>) loadProfileAndShowDialog,
) {
  return Container(
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
            child: _buildAuctionImage(
              auction['image'],
              width: 60,
              height: 60,
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
                    Icon(Icons.emoji_events, size: 14, color: Colors.green[600]),
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          height: 32,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                              ),
                            ),
                          ),
                        );
                      }
                      final isAppleTest = snapshot.data ?? false;
                      
                      // ไม่แสดงปุ่มกรอกข้อมูลสำหรับ Apple test account
                      if (isAppleTest) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info, size: 16, color: Colors.grey[600]),
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
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              height: 32,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
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
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () async {
                                          if (await validateWinnerInfo(context)) {
                                            AuctionDialogs.showPaymentDialog(context, auction);
                                          }
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.credit_card, color: Colors.black, size: 16),
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
                                  icon: Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                                  label: Text('แก้ไขข้อมูลผู้ชนะ', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey[600],
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return ElevatedButton.icon(
                              onPressed: () async {
                                await loadProfileAndShowDialog(auction);
                              },
                              icon: Icon(Icons.edit, size: 16, color: Colors.black),
                              label: Text('กรอกข้อมูลผู้ชนะ', style: TextStyle(color: Colors.black)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
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
  );
}

// Utility Functions
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

  if (firstname.isEmpty || lastname.isEmpty || phone.isEmpty || address.isEmpty || provinceId.isEmpty || districtId.isEmpty || subDistrictId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('กรุณากรอกข้อมูลผู้ชนะให้ครบถ้วน'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }
  return true;
}

Widget buildEmptyState({required IconData icon, required String title, required String subtitle}) {
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