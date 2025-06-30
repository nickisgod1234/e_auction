import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/services/auth_service/auth_service.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/utils/regexvalidator.dart';
import 'package:flutter/services.dart';

class PaymentDialogContent extends StatefulWidget {
  final Map<String, dynamic> auction;
  
  const PaymentDialogContent({super.key, required this.auction});
  
  @override
  State<PaymentDialogContent> createState() => _PaymentDialogContentState();
}

class _PaymentDialogContentState extends State<PaymentDialogContent> {
  int timeLeft = 60;
  Timer? timer;
  bool isDialogOpen = true;
  
  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (periodicTimer) {
      if (mounted && isDialogOpen) {
        setState(() {
          if (timeLeft > 0) {
            timeLeft--;
          } else {
            periodicTimer.cancel();
            if (mounted && isDialogOpen) {
              Navigator.of(context).pop();
            }
          }
        });
      } else {
        periodicTimer.cancel();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.payment, color: Colors.white, size: 10),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ติดต่อชำระเงิน',
                    style: TextStyle(
                      fontSize: 16,
                     
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Countdown timer
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ปิดอัตโนมัติใน $timeLeft วินาที',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Success message
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ยินดีด้วย! คุณชนะการประมูล',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Auction info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  InfoRowWidget(
                    label: 'สินค้า',
                    value: widget.auction['title'],
                  ),
                  SizedBox(height: 8),
                  InfoRowWidget(
                    label: 'เลขที่ประมูล',
                    value: widget.auction['auctionId'],
                    isMonospace: true,
                  ),
                  SizedBox(height: 8),
                  InfoRowWidget(
                    label: 'ราคาที่ชนะ',
                    value: Format.formatCurrency(widget.auction['finalPrice']),
                    isHighlight: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            Text(
              'กรุณาติดต่อผู้ขายเพื่อชำระเงิน:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            
            // Contact info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ContactRowWidget(icon: Icons.phone, contact: 'โทร: 02-123-4567'),
                  SizedBox(height: 8),
                  ContactRowWidget(icon: Icons.chat, contact: 'Line: @e_auction_support'),
                  SizedBox(height: 8),
                  ContactRowWidget(icon: Icons.email, contact: 'Email: support@e-auction.com'),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'อย่าลืมแจ้งเลขที่ประมูลเมื่อติดต่อผู้ขาย',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  isDialogOpen = false;
                  timer?.cancel();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'ปิด',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';
    for (int i = 0; i < digits.length && i < 10; i++) {
      if (i == 3 || i == 6) formatted += '-';
      formatted += digits[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class FormFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool requiredField;
  final bool isEmail;
  final bool isPhone;

  const FormFieldWidget({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.requiredField = true,
    this.isEmail = false,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly, PhoneNumberFormatter()] : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (requiredField && (value == null || value.trim().isEmpty)) {
              return 'กรุณากรอก${label.replaceAll("*", "").trim()}';
            }
            if (isEmail && value != null && value.trim().isNotEmpty) {
              final emailValidator = EmailSubmitRegexValidator();
              if (!emailValidator.isValid(value.trim())) {
                return 'รูปแบบอีเมลไม่ถูกต้อง';
              }
            }
            if (isPhone && value != null && value.trim().isNotEmpty) {
              final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.length != 10) {
                return 'กรุณากรอกเบอร์โทร 10 หลัก';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}

class InfoRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final bool isMonospace;

  const InfoRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
              color: isHighlight ? Colors.green[700] : Colors.black,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

class ContactRowWidget extends StatelessWidget {
  final IconData icon;
  final String contact;

  const ContactRowWidget({
    super.key,
    required this.icon,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        SizedBox(width: 12),
        Text(
          contact,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
          child: Image.asset(
            auction['image'],
            width: small ? 44 : 60,
            height: small ? 44 : 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: small ? 44 : 60,
                height: small ? 44 : 60,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
              );
            },
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
            color: getStatusColor(auction['status']),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            getStatusText(auction['status']),
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
          child: Image.asset(
            auction['image'],
            width: small ? 44 : 60,
            height: small ? 44 : 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: small ? 44 : 60,
                height: small ? 44 : 60,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
              );
            },
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
          child: Image.asset(
            auction['image'],
            width: small ? 44 : 60,
            height: small ? 44 : 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: small ? 44 : 60,
                height: small ? 44 : 60,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
              );
            },
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

// Dialog Methods
class AuctionDialogs {
  static void showPaymentDialog(BuildContext context, Map<String, dynamic> auction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PaymentDialogContent(auction: auction);
      },
    );
  }

  static void showWinnerInfoDialog(
    BuildContext context,
    Map<String, dynamic> auction,
    Map<String, TextEditingController> controllers,
    Future<void> Function() saveWinnerInfoToServer,
    bool Function() validateForm,
    void Function(String) showValidationError,
  ) async {
    await _loadWinnerInfo(controllers);
    final formKey = GlobalKey<FormState>();
    final hasInfo = await _hasWinnerInfo(controllers);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(hasInfo ? Icons.edit : Icons.emoji_events, color: hasInfo ? Colors.blue : Colors.green, size: 24),
                  const SizedBox(width: 8),
                  Text(hasInfo ? 'แก้ไขข้อมูลผู้ชนะ' : 'ข้อมูลผู้ชนะการประมูล'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Winner notification
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasInfo ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: hasInfo ? Colors.blue.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(hasInfo ? Icons.edit : Icons.celebration, color: hasInfo ? Colors.blue : Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasInfo 
                                  ? 'แก้ไขข้อมูลสำหรับการประมูล ${auction['title']}'
                                  : 'ยินดีด้วย! คุณชนะการประมูล ${auction['title']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: hasInfo ? Colors.blue : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Auction info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InfoRowWidget(
                              label: 'เลขที่ประมูล',
                              value: auction['auctionId'],
                              isMonospace: true,
                            ),
                            InfoRowWidget(
                              label: 'ราคาที่ชนะ',
                              value: Format.formatCurrency(auction['finalPrice']),
                              isHighlight: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Form fields
                      Text(
                        hasInfo ? 'แก้ไขข้อมูลสำหรับการจัดส่ง:' : 'กรุณากรอกข้อมูลสำหรับการจัดส่ง:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      
                      FormFieldWidget(
                        controller: controllers['firstname']!,
                        label: 'ชื่อ *',
                        icon: Icons.person,
                        hint: 'กรอกชื่อ',
                        requiredField: true,
                      ),
                      const SizedBox(height: 8),
                      
                      FormFieldWidget(
                        controller: controllers['lastname']!,
                        label: 'นามสกุล *',
                        icon: Icons.person,
                        hint: 'กรอกนามสกุล',
                        requiredField: true,
                      ),
                      const SizedBox(height: 8),
                      
                      FormFieldWidget(
                        controller: controllers['phone']!,
                        label: 'เบอร์โทรศัพท์ *',
                        icon: Icons.phone,
                        hint: 'กรอกเบอร์โทรศัพท์',
                        keyboardType: TextInputType.phone,
                        requiredField: true,
                        isPhone: true,
                      ),
                      const SizedBox(height: 8),
                      
                      FormFieldWidget(
                        controller: controllers['email']!,
                        label: 'อีเมล *',
                        icon: Icons.email,
                        hint: 'กรอกอีเมล',
                        keyboardType: TextInputType.emailAddress,
                        requiredField: true,
                        isEmail: true,
                      ),
                      const SizedBox(height: 8),
                      
                      FormFieldWidget(
                        controller: controllers['address']!,
                        label: 'ที่อยู่ *',
                        icon: Icons.location_on,
                        hint: 'กรอกที่อยู่',
                        maxLines: 2,
                        requiredField: true,
                      ),
                      const SizedBox(height: 8),
                      
                      CascadeAddressDropdowns(
                        controllers: controllers,
                        authService: AuthService(baseUrl: Config.apiUrlotpsever),
                      ),
                      
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Text(
                          hasInfo 
                            ? '💡 ข้อมูลที่แก้ไขจะถูกบันทึกและใช้สำหรับการประมูลครั้งต่อไป'
                            : '💡 ข้อมูลนี้จะถูกบันทึกและใช้สำหรับการประมูลครั้งต่อไป',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      try {
                        await saveWinnerInfoToServer();
                        Navigator.of(context).pop();
                        // แสดง payment dialog หลังจากบันทึกข้อมูลสำเร็จ
                        showPaymentDialog(context, auction);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${hasInfo ? 'แก้ไข' : 'บันทึก'}ข้อมูลเรียบร้อยแล้ว (${auction['auctionId']})'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(hasInfo ? Icons.edit : Icons.save, size: 16),
                  label: Text(hasInfo ? 'แก้ไขข้อมูล' : 'บันทึกข้อมูล'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> _loadWinnerInfo(Map<String, TextEditingController> controllers) async {
    final prefs = await SharedPreferences.getInstance();
    controllers['firstname']!.text = prefs.getString('winner_firstname') ?? '';
    controllers['lastname']!.text = prefs.getString('winner_lastname') ?? '';
    controllers['phone']!.text = prefs.getString('winner_phone') ?? '';
    controllers['address']!.text = prefs.getString('winner_address') ?? '';
    controllers['taxNumber']!.text = prefs.getString('winner_tax_number') ?? '';
    controllers['email']!.text = prefs.getString('winner_email') ?? '';
    controllers['provinceId']!.text = prefs.getString('winner_province_id') ?? '';
    controllers['districtId']!.text = prefs.getString('winner_district_id') ?? '';
    controllers['subDistrictId']!.text = prefs.getString('winner_sub_district_id') ?? '';
    controllers['sub']!.text = prefs.getString('winner_sub') ?? '';
    controllers['zipCode']!.text = prefs.getString('winner_zip_code') ?? '';
  }

  static Future<bool> _hasWinnerInfo(Map<String, TextEditingController> controllers) async {
    final prefs = await SharedPreferences.getInstance();
    final firstname = prefs.getString('winner_firstname') ?? '';
    final lastname = prefs.getString('winner_lastname') ?? '';
    final phone = prefs.getString('winner_phone') ?? '';
    final address = prefs.getString('winner_address') ?? '';
    final taxNumber = prefs.getString('winner_tax_number') ?? '';
    
    return firstname.isNotEmpty && lastname.isNotEmpty && phone.isNotEmpty && 
           address.isNotEmpty && taxNumber.isNotEmpty;
  }
}

// Cascade Dropdown Widgets
class CascadeAddressDropdowns extends StatefulWidget {
  final Map<String, TextEditingController> controllers;
  final AuthService authService;

  const CascadeAddressDropdowns({
    super.key,
    required this.controllers,
    required this.authService,
  });

  @override
  State<CascadeAddressDropdowns> createState() => _CascadeAddressDropdownsState();
}

class _CascadeAddressDropdownsState extends State<CascadeAddressDropdowns> {
  List<Map<String, dynamic>> addressData = [];
  Map<String, dynamic>? selectedProvince;
  Map<String, dynamic>? selectedDistrict;
  Map<String, dynamic>? selectedSubDistrict;

  String? provinceError;
  String? districtError;
  String? subDistrictError;

  @override
  void initState() {
    super.initState();
    loadAddressData();
  }

  Future<void> loadAddressData() async {
    try {
      final data = await widget.authService.getAddressData();
      if (mounted) {
        setState(() {
          addressData = data;
          // Restore selected values from controllers
          if (widget.controllers['provinceId']!.text.isNotEmpty) {
            selectedProvince = addressData.firstWhere(
              (p) => p['id'].toString() == widget.controllers['provinceId']!.text,
              orElse: () => {},
            );
          }
          if (selectedProvince != null && widget.controllers['districtId']!.text.isNotEmpty) {
            selectedDistrict = (selectedProvince!['districts'] as List).firstWhere(
              (d) => d['id'].toString() == widget.controllers['districtId']!.text,
              orElse: () => {},
            );
          }
          if (selectedDistrict != null && widget.controllers['subDistrictId']!.text.isNotEmpty) {
            selectedSubDistrict = (selectedDistrict!['sub_districts'] as List).firstWhere(
              (s) => s['id'].toString() == widget.controllers['subDistrictId']!.text,
              orElse: () => {},
            );
          }
        });
      }
    } catch (e) {
      // fallback: do nothing
    }
  }

  bool validateDropdowns() {
    setState(() {
      provinceError = selectedProvince == null ? 'กรุณาเลือกจังหวัด' : null;
      districtError = selectedDistrict == null ? 'กรุณาเลือกอำเภอ/เขต' : null;
      subDistrictError = selectedSubDistrict == null ? 'กรุณาเลือกตำบล/แขวง' : null;
    });
    return provinceError == null && districtError == null && subDistrictError == null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // จังหวัด
        Text('จังหวัด *', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        DropdownButtonFormField<Map<String, dynamic>>(
          value: selectedProvince,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.location_city, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
            errorText: provinceError,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          hint: const Text('เลือกจังหวัด'),
          items: addressData.map((province) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: province,
              child: Text(province['name_th'] ?? ''),
            );
          }).toList(),
          onChanged: (province) {
            setState(() {
              selectedProvince = province;
              selectedDistrict = null;
              selectedSubDistrict = null;
              provinceError = null;
              districtError = null;
              subDistrictError = null;
            });
            widget.controllers['provinceId']!.text = province?['id']?.toString() ?? '';
            widget.controllers['districtId']!.text = '';
            widget.controllers['subDistrictId']!.text = '';
          },
        ),
        if (provinceError != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(provinceError!, style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 8),
        // อำเภอ
        if (selectedProvince != null) ...[
          Text('อำเภอ/เขต *', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: selectedDistrict,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.location_city, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
              errorText: districtError,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            hint: const Text('เลือกอำเภอ/เขต'),
            items: (selectedProvince!['districts'] as List).map((district) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: district,
                child: Text(district['name_th'] ?? ''),
              );
            }).toList(),
            onChanged: (district) {
              setState(() {
                selectedDistrict = district;
                selectedSubDistrict = null;
                districtError = null;
                subDistrictError = null;
              });
              widget.controllers['districtId']!.text = district?['id']?.toString() ?? '';
              widget.controllers['subDistrictId']!.text = '';
            },
          ),
          if (districtError != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 2),
              child: Text(districtError!, style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          const SizedBox(height: 8),
        ],
        // ตำบล
        if (selectedDistrict != null) ...[
          Text('ตำบล/แขวง *', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: selectedSubDistrict,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.location_on, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
              errorText: subDistrictError,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            hint: const Text('เลือกตำบล/แขวง'),
            items: (selectedDistrict!['sub_districts'] as List).map((subDistrict) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: subDistrict,
                child: Text(subDistrict['name_th'] ?? ''),
              );
            }).toList(),
            onChanged: (subDistrict) {
              setState(() {
                selectedSubDistrict = subDistrict;
                subDistrictError = null;
              });
              widget.controllers['subDistrictId']!.text = subDistrict?['id']?.toString() ?? '';
              widget.controllers['zipCode']!.text = subDistrict?['zip_code']?.toString() ?? '';
            },
          ),
          if (subDistrictError != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 2),
              child: Text(subDistrictError!, style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          const SizedBox(height: 8),
        ],
        // รหัสไปรษณีย์
        if (selectedSubDistrict != null) ...[
          Text('รหัสไปรษณีย์', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          FormFieldWidget(
            controller: widget.controllers['zipCode']!,
            label: '',
            icon: Icons.mail,
            hint: 'รหัสไปรษณีย์',
            keyboardType: TextInputType.number,
            requiredField: false,
          ),
        ],
      ],
    );
  }
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
            child: Image.asset(
              auction['image'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                );
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
                            // textStyle: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }
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
