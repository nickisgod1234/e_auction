import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:e_auction/utils/tool_utility.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'dart:ui';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/services/auth_service/auth_service.dart';
import 'package:e_auction/views/first_page/home_screen.dart';
import 'package:e_auction/theme/app_theme.dart';

class RequestOtpLoginPage extends StatefulWidget {
  @override
  _RequestOtpLoginPageState createState() => _RequestOtpLoginPageState();
}

class _RequestOtpLoginPageState extends State<RequestOtpLoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final AuthService _authService = AuthService(baseUrl: Config.apiUrlotpsever);

  bool _isPinVisible = false; // แสดงช่อง PIN เมื่อได้รับ refno
  bool _isPhoneLoginMode = false; // ควบคุมการแสดง TextButton และปุ่มย้อนกลับ
  bool _isLoading = false; // แสดงสถานะโหลด
  bool _isRequestEnabled = true; // ควบคุมการส่ง OTP
  int _countdown = 0; // ตัวนับเวลาขอ OTP ใหม่
  String _refno = ""; // เก็บ refno
  Timer? _timer;

  // Helper function to safely get string values from userData
  String _safeGetString(Map<String, dynamic> userData, String key) {
    final value = userData[key];
    if (value == null) return '';
    return value.toString();
  }

  void _startLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิดโดยการกดที่พื้นที่ว่าง
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'กำลังโหลด',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _stopLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop(); // ปิด Dialog
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phone_number');

    if (phoneNumber != null) {
      // ถ้ามีข้อมูล phone_number ให้แสดงหน้า RequestOtpLoginPage ตามปกติ
      print('Phone number exists: $phoneNumber');
    } else {
      // ถ้าไม่มีข้อมูล ให้แสดงหน้า RequestOtpLoginPage ตามปกติ
      print("No phone number found in SharedPreferences");
    }
  }

// บันทึกข้อมูลเบอร์โทรและ Token
  Future<void> saveUserData(String phoneNumber, String token,
      String phoneUserID, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', phoneNumber); // เก็บเบอร์โทร
    await prefs.setString('email', email); // เก็บเบอร์โทร
    await prefs.setString('password', password); // เก็บเบอร์โทร
    await prefs.setInt('id', phoneUserID as int); // เก็บเบอร์โทร
    await prefs.setString('token_otp', token); // เก็บ Token
  }

// ดึงข้อมูลผู้ใช้จาก Local Storage
  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phone_number');
    final token = prefs.getString('token_otp');
    final phoneUserID = prefs.getString('id');
    final email = prefs.getString('email');
    final password = prefs.getString('password');
    print('Phone User ID: $phoneUserID');
    print('Phone Number: $phoneNumber');
    print('email: $email');
    print('passwor: $password');
    return {
      'phone_number': phoneNumber,
      'token_otp': token,
      'id': phoneUserID,
      'email': email,
      'password': password
    };
  }

// ลบข้อมูลผู้ใช้ (สำหรับกรณี Log Out)
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('phone_number');
  }

  void _submitPhoneNumber() async {
    final phoneNumber = _phoneController.text;

    // Demo Mode for Apple Review
    if (phoneNumber == '0001112345') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('id', 'APPLE_TEST_ID');
      await prefs.setString('phone', '0001112345');

      setState(() {
        _refno = 'DEMO';
        _isPinVisible = true;
      });
      _showOtpDialogWithResend();
      return;
    }

    if (phoneNumber.isEmpty || !RegExp(r'^[0-9]{10}$').hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกเบอร์โทรศัพท์ที่ถูกต้อง')),
      );
      return;
    }
    _startLoadingDialog(context); // แสดงสถานะโหลด
    try {
      final userData = await _authService.checkPhoneNumber(phoneNumber);

      if (userData == null) {
        _stopLoadingDialog(context);
        _showRegistrationDialog(phoneNumber);
        return;
      }

      final status = userData['status'];
      if (status == 'deleted') {
        _stopLoadingDialog(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เบอร์นี้ถูกลบไปแล้ว กรุณาติดต่อผู้ดูแลระบบ'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (status == 'not_found') {
        _stopLoadingDialog(context);
        _showRegistrationDialog(phoneNumber);
        return;
      }

      // ถ้า isdelete == 'f' หรือค่าว่าง/null ให้เข้าใช้งานได้ตามปกติ
      final phone_number = _safeGetString(userData, 'phone_number');
      final phone_id = _safeGetString(userData, 'id');
      final userName = _safeGetString(userData, 'name');
      final Emai = _safeGetString(userData, 'email');
      final password = _safeGetString(userData, 'password');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone_number', phone_number);
      await prefs.setString('id', phone_id);
      await prefs.setString('email', Emai);
      await prefs.setString('password', password);
      // ... (บันทึก fields อื่นๆ เหมือนเดิม)
      await prefs.setString(
          'created_at', _safeGetString(userData, 'created_at'));
      await prefs.setString(
          'updated_at', _safeGetString(userData, 'updated_at'));
      await prefs.setString(
          'company_id', _safeGetString(userData, 'company_id'));
      await prefs.setString('type', _safeGetString(userData, 'type'));
      await prefs.setString('logo', _safeGetString(userData, 'logo'));
      await prefs.setString('phone', _safeGetString(userData, 'phone'));
      await prefs.setString('code', _safeGetString(userData, 'code'));
      await prefs.setString('name', _safeGetString(userData, 'name'));
      await prefs.setString(
          'tax_number', _safeGetString(userData, 'tax_number'));
      await prefs.setString('fullname', _safeGetString(userData, 'fullname'));
      await prefs.setString('addr', _safeGetString(userData, 'addr'));
      await prefs.setString(
          'province_id', _safeGetString(userData, 'province_id'));
      await prefs.setString(
          'district_id', _safeGetString(userData, 'district_id'));
      await prefs.setString(
          'sub_district_id', _safeGetString(userData, 'sub_district_id'));
      await prefs.setString('sub', _safeGetString(userData, 'sub'));
      await prefs.setString('pass', _safeGetString(userData, 'pass'));
      await prefs.setString('reset_key', _safeGetString(userData, 'reset_key'));
      await prefs.setString(
          'reset_key_exp', _safeGetString(userData, 'reset_key_exp'));
      await prefs.setString('isdelete', userData['isdelete'] ?? '');

      print('User ID: $phone_number');
      print('User Name: $userName');
      print('Status: $status');
      // ส่ง OTP ทันทีเพื่อเข้าสู่ระบบ
      final otpResponse = await _authService.sendOtp(phoneNumber);
      _stopLoadingDialog(context); // ปิดสถานะโหลด
      if (otpResponse != null) {
        setState(() {
          _refno = otpResponse['refno'];
          _isPinVisible = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP ถูกส่งไปยังเบอร์โทรของคุณแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
        _startCountdown();
        // แสดง OTP Dialog อัตโนมัติ (แบบใหม่)
        _showOtpDialogWithResend();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถส่ง OTP ได้ กรุณาลองอีกครั้ง'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _stopLoadingDialog(context); // ปิดสถานะโหลด
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // เพิ่มเมธอดใหม่สำหรับแสดง popup ลงทะเบียน
  void _showRegistrationDialog(String phoneNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.person_add, color: Colors.blue, size: 48),
            SizedBox(height: 12),
            Text(
              'ไม่พบเบอร์โทรในระบบ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        content: Text(
          'เบอร์โทรนี้ยังไม่ได้ลงทะเบียนในระบบ\nต้องการลงทะเบียนใหม่หรือไม่?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: Icon(Icons.close, color: Colors.white),
            label: Text('ยกเลิก', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: Icon(Icons.check, color: Colors.white),
            label: Text('ตกลง', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(context);
              _startRegistrationProcess(phoneNumber);
            },
          ),
        ],
      ),
    );
  }

  // เพิ่มเมธอดใหม่สำหรับเริ่มกระบวนการลงทะเบียน
  void _startRegistrationProcess(String phoneNumber) async {
    _startLoadingDialog(context);

    try {
      // ส่ง OTP สำหรับลงทะเบียน
      final otpResponse = await _authService.sendOtp(phoneNumber);
      _stopLoadingDialog(context);

      if (otpResponse != null) {
        setState(() {
          _refno = otpResponse['refno'];
          _isPinVisible = true;
        });

        // เริ่ม countdown timer
        _startCountdown();

        // แสดง dialog สำหรับกรอก OTP
        _showRegistrationOtpDialog(phoneNumber);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถส่ง OTP ได้ กรุณาลองอีกครั้ง')),
        );
      }
    } catch (e) {
      _stopLoadingDialog(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // เพิ่มเมธอดใหม่สำหรับแสดง dialog กรอก OTP ลงทะเบียน
  void _showRegistrationOtpDialog(String phoneNumber) {
    final TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Icon(Icons.verified_user, color: Colors.blue, size: 48),
              SizedBox(height: 12),
              Text(
                'ยืนยันการลงทะเบียน',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'เราได้ส่ง OTP ไปยังหมายเลขโทรศัพท์ของคุณ\nกรุณายืนยันรหัส OTP เพื่อลงทะเบียน',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'REFNO: $_refno',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: otpController,
                decoration: InputDecoration(
                  labelText: 'กรอกรหัส OTP',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final pin = otpController.text;

                if (pin.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('กรุณากรอกรหัส OTP')),
                  );
                  return;
                }

                _startLoadingDialog(context);
                final response = await _authService.verifyOtp(phoneNumber, pin);
                _stopLoadingDialog(context);

                if (response['success']) {
                  Navigator.pop(context); // ปิด OTP dialog

                  // บันทึกข้อมูลการลงทะเบียน
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('phone_number', phoneNumber);
                  await prefs.setString('token_otp', response['token'] ?? '');
                  await prefs.setString('id', response['id']?.toString() ?? '');

                  // บันทึกข้อมูลอื่นๆ ที่ได้จาก response
                  if (response['email'] != null)
                    await prefs.setString('email', response['email']);
                  if (response['password'] != null)
                    await prefs.setString('password', response['password']);
                  if (response['name'] != null)
                    await prefs.setString('name', response['name']);

                  // แสดงข้อความสำเร็จ
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ลงทะเบียนสำเร็จ! ยินดีต้อนรับสู่ระบบ'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // ไปยังหน้า HomeScreen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ยืนยัน OTP ไม่สำเร็จ กรุณาลองอีกครั้ง'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('ยืนยัน', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _startCountdown() {
    setState(() {
      _isRequestEnabled = false;
      _countdown = 60;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isRequestEnabled = true;
        });
      }
    });
  }

  void _verifyOTP() async {
    final pin = _pinController.text;
    final phoneNumber = _phoneController.text;

    // Demo Mode
    if (phoneNumber == '0001112345' && pin == '12345') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone_number', '0001112345');
      await prefs.setString('token_otp', 'demo_token');
      await prefs.setString('id', '999');
      await prefs.setString('email', 'nick888@hmail.com');
      await prefs.setString('password', '12345');
      // เพิ่มข้อมูลจำลองอื่น ๆ ตามต้องการ

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เข้าสู่ Demo Mode')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
      return;
    }

    if (pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกรหัส PIN')),
      );
      return;
    }

    _startLoadingDialog(context); // เริ่มแสดงสถานะโหลด
    final response = await _authService.verifyOtp(phoneNumber, pin);
    _stopLoadingDialog(context); // หยุดแสดงสถานะโหลด

    if (response['success']) {
      final id = int.tryParse(response['id'].toString()) ?? 0;

      if (id > 0) {
        final prefs = await SharedPreferences.getInstance();
        // บันทึกข้อมูลการล็อกอิน
        await prefs.setString('phone_number', phoneNumber);
        await prefs.setString('token_otp', response['token'] ?? '');
        await prefs.setString('id', id.toString());

        // บันทึกข้อมูลอื่นๆ ที่ได้จาก response
        if (response['email'] != null)
          await prefs.setString('email', response['email']);
        if (response['password'] != null)
          await prefs.setString('password', response['password']);
        if (response['name'] != null)
          await prefs.setString('name', response['name']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ยืนยันสำเร็จ!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ยืนยันไม่สำเร็จ กรุณาลองอีกครั้ง')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ยืนยันไม่สำเร็จ กรุณาลองอีกครั้ง')),
      );
    }
  }

  Future<void> _requestNewOTP() async {
    if (!_isRequestEnabled) return;

    final phoneNumber = _phoneController.text;

    if (phoneNumber.isEmpty || !RegExp(r'^[0-9]{10}$').hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกเบอร์โทรศัพท์ให้ถูกต้อง')),
      );
      return;
    }

    _startLoadingDialog(context); // เริ่มแสดงสถานะโหลด
    final newRefno = await _authService.sendOtp(phoneNumber);
    _stopLoadingDialog(context); // หยุดแสดงสถานะโหลด

    if (newRefno != null) {
      setState(() {
        _refno = newRefno['refno']; // อัปเดต refno ใหม่จาก API
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP ถูกส่งอีกครั้ง: Refno: $_refno')),
      );
      _startCountdown();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ขอรหัสใหม่ไม่สำเร็จ กรุณาลองอีกครั้ง')),
      );
    }
  }

  void _resetToDefault() {
    setState(() {
      _isPhoneLoginMode = false;
      _isPinVisible = false;
      _refno = "";
      _phoneController.clear();
      _pinController.clear();
    });
  }

  // ===== เพิ่มฟังก์ชัน OTP Popup 5 หลัก =====
  // ปรับฟังก์ชัน showOtpDialog5Digits ให้รับ callback ขอ OTP ใหม่ และ state สำหรับ countdown
  Future<void> showOtpDialog5Digits(BuildContext context, void Function(String) onVerify, {
    required VoidCallback onRequestNewOtp,
    required bool isRequestEnabled,
    required int countdown,
  }) async {
    final List<TextEditingController> controllers =
        List.generate(5, (_) => TextEditingController());
    final focusNodes = List.generate(5, (_) => FocusNode());

    void _onChanged(int idx, String value) {
      if (value.length == 1 && idx < 4) {
        focusNodes[idx + 1].requestFocus();
      }
      if (value.isEmpty && idx > 0) {
        focusNodes[idx - 1].requestFocus();
      }
    }

    int localCountdown = 60;
    bool localRequestEnabled = false;
    Timer? timer;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // เริ่ม timer เฉพาะรอบแรก
            if (timer == null) {
              timer = Timer.periodic(Duration(seconds: 1), (t) {
                if (localCountdown > 0) {
                  setState(() => localCountdown--);
                } else {
                  setState(() => localRequestEnabled = true);
                  t.cancel();
                }
              });
            }
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 40, color: Colors.grey[700]),
                  SizedBox(height: 16),
                  Text('Enter your OTP code\nto sign in.', textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  // ใน showOtpDialog5Digits ให้เปลี่ยน Container ของแต่ละ TextField เป็นแบบมีเงา ไม่มีขอบ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (idx) {
                      return Container(
                        width: 36,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: controllers[idx],
                          focusNode: focusNodes[idx],
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) => _onChanged(idx, val),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final otp = controllers.map((c) => c.text).join();
                      onVerify(otp);
                      timer?.cancel();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 44),
                    ),
                    child: Text('Verify'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: localRequestEnabled
                        ? () {
                            setState(() {
                              localCountdown = 60;
                              localRequestEnabled = false;
                            });
                            onRequestNewOtp();
                            // รีเซ็ต timer
                            timer?.cancel();
                            timer = Timer.periodic(Duration(seconds: 1), (t) {
                              if (localCountdown > 0) {
                                setState(() => localCountdown--);
                              } else {
                                setState(() => localRequestEnabled = true);
                                t.cancel();
                              }
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: localRequestEnabled ? Colors.blue : Colors.grey,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 44),
                    ),
                    child: Text(
                      localRequestEnabled
                          ? 'ขอรหัสใหม่'
                          : 'รอ $localCountdown s เพื่อขอใหม่ได้',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    timer?.cancel();
  }
  // ===== END เพิ่มฟังก์ชัน OTP Popup 5 หลัก =====

  // เพิ่ม callback สำหรับขอ OTP ใหม่และเปิด dialog ใหม่
  void _showOtpDialogWithResend() {
    showOtpDialog5Digits(
      context,
      (otp) {
        _pinController.text = otp;
        _verifyOTP();
      },
      onRequestNewOtp: () async {
        Navigator.of(context).pop(); // ปิด dialog เดิม
        await _requestNewOTP(); // ส่ง OTP ใหม่
        // รอ OTP ส่งเสร็จแล้วเปิด dialog ใหม่ (delay เล็กน้อยเพื่อให้ state หลักอัปเดต)
        Future.delayed(Duration(milliseconds: 300), () {
          _showOtpDialogWithResend();
        });
      },
      isRequestEnabled: _isRequestEnabled,
      countdown: _countdown,
    );
  }

  @override
  void initState() {
    super.initState();
    _checkSavedLogin(); // เพิ่มการตรวจสอบข้อมูลการล็อกอินที่บันทึกไว้
  }

  // เพิ่มเมธอดใหม่สำหรับตรวจสอบข้อมูลการล็อกอินที่บันทึกไว้
  Future<void> _checkSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phone_number');
    final token = prefs.getString('token_otp');
    final id = prefs.getString('id');
    final isdelete = prefs.getString('isdelete');

    // เช็คสถานะ isdelete ก่อน
    if (isdelete == 'true') {
      // ถ้าบัญชีถูกลบแล้ว ให้ล้างข้อมูลและไม่ให้เข้าสู่ระบบ
      await prefs.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บัญชีนี้ถูกลบแล้ว กรุณาติดต่อผู้ดูแลระบบ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (phoneNumber != null && token != null && id != null) {
      // ถ้ามีข้อมูลการล็อกอินที่บันทึกไว้ และบัญชีไม่ถูกลบ ให้ไปที่หน้า HomeScreenCM โดยตรง
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Ensures content resizes with the keyboard
      body: GestureDetector(
        onTap: () {
          // Hide the keyboard when tapping outside of a TextField
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // เอฟเฟกต์เบลอ
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.white,
                    ),
                  ),

                  // ปุ่มย้อนกลับที่มุมขวาบน
                  if (_isPhoneLoginMode)
                    Positioned(
                      top: 40,
                      right: 20,
                      child: GestureDetector(
                        onTap: _resetToDefault,
                        child: Icon(
                          Icons.close,
                          color: context.customTheme.primaryColor,
                          size: 28,
                        ),
                      ),
                    ),

                  // เนื้อหาในหน้า
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // โลโก้และข้อความด้านบน
                        Column(
                          children: [
                            SizedBox(height: 60), // ระยะห่างด้านบน
                            Text(
                              AppTheme.getAppTitle(AppTheme.currentClient),
                              style: TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: context.customTheme.primaryColor,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "เข้าสู่ระบบ",
                              style: TextStyle(
                                fontSize: 18,
                                color: context.customTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),

                        // ปุ่มและฟิลด์กรอกข้อมูล
                        Column(
                          children: [
                            if (!_isPhoneLoginMode) ...[
                              // ปุ่มล็อกอินด้วยเบอร์โทร
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isPhoneLoginMode = true;
                                  });
                                },
                                icon: Icon(Icons.phone, color: Colors.white),
                                label: Text("ล็อกอินด้วยเบอร์โทร"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      context.customTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(double.infinity, 50),
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                            if (_isPhoneLoginMode) ...[
                              TextField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'กรอกเบอร์โทรศัพท์',
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.5),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto,
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            context.customTheme.primaryColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: context.customTheme.primaryColor
                                            .withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  labelStyle: TextStyle(
                                      color: context.customTheme.primaryColor),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _submitPhoneNumber,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      context.customTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text("ตกลง"),
                              ),
                              if (_refno.isNotEmpty) ...[
                                SizedBox(height: 20),
                                Text(
                                  'REFNO: $_refno',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: context.customTheme.primaryColor,
                                  ),
                                ),
                                SizedBox(height: 10),
                                // ลบปุ่มกรอก OTP ออก (ไม่ต้องให้ผู้ใช้กดเอง)
                              ],
                            ],
                          ],
                        ),

                        // ข้อความเงื่อนไขการใช้งาน
                        Column(
                          children: [
                            Text(
                              "เมื่อดำเนินการต่อ แสดงว่าคุณยอมรับเงื่อนไขการใช้งาน\n"
                              "และนโยบายความเป็นส่วนตัวของเรา",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.customTheme.primaryColor,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 40),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
