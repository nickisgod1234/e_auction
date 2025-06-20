import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:e_auction/utils/tool_utility.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'dart:ui';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/views/first_page/request_otp_page/auth_service/auth_service.dart';
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
      await prefs.setString('mem_fullname', 'Apple Review Tester');

      setState(() {
        _refno = 'DEMO';
        _isPinVisible = true;
      });
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
      // ดึงข้อมูลจาก checkPhoneNumber
      final userData = await _authService.checkPhoneNumber(phoneNumber);

      if (userData != null) {

        final phone_number = userData['phone_number'];
        final phone_id = userData['id'];
        final userName = userData['name'];
        final Emai = userData['email'];
        final password = userData['password'];
        final profilePicture = userData['profile_picture'];
        final current_address = userData['current_address'];

        // เก็บ id ใน SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('phone_number', phone_number);
        await prefs.setString('id', phone_id);
        await prefs.setString('email', Emai);
        await prefs.setString('password', password);
        await prefs.setString('current_address', current_address);
        // เพิ่มการเก็บ user_id, username, user_password
        if (userData['user_id'] != null) {
          await prefs.setString('user_id', userData['user_id']);
        }
        if (userData['username'] != null) {
          await prefs.setString('username', userData['username']);
        }
        if (userData['user_password'] != null) {
          await prefs.setString('user_password', userData['user_password']);
        }
        // เพิ่มการเก็บ field อื่นๆ ตามตัวอย่าง login_screen_page.dart
        await prefs.setString('firstname', userData['firstname'] ?? '');
        await prefs.setString('lastname', userData['lastname'] ?? '');
        await prefs.setString('role_id', userData['role_id'] ?? '');
        await prefs.setString('role_name_th', userData['role_name_th'] ?? '');
        await prefs.setString('statusflag', userData['statusflag'] ?? '');
        await prefs.setString('role_type', userData['role_type'] ?? '');
        await prefs.setString('branch_id', userData['branch_id'] ?? '');
        await prefs.setString('department_id', userData['department_id'] ?? '');
        await prefs.setString('position_id', userData['position_id'] ?? '');
        await prefs.setString('level_id', userData['level_id'] ?? '');
        await prefs.setString('leave_manage', userData['leave_manage'] ?? '0');
        await prefs.setString('insurance_manage', userData['insurance_manage'] ?? '0');
        await prefs.setString('person_id', userData['person_id'] ?? '');
        await prefs.setString('mem_status', userData['mem_status'] ?? '');
        await prefs.setString('mem_idcard', userData['mem_idcard'] ?? '');
        await prefs.setString('mem_email', userData['mem_email'] ?? '');
        await prefs.setString('mem_fullname', userData['mem_fullname'] ?? '');
        await prefs.setString('mem_password', userData['mem_password'] ?? '');
        await prefs.setString('mem_birthdate', userData['mem_birthdate'] ?? '');
        await prefs.setString('mem_sex', userData['mem_sex'] ?? '');
        await prefs.setString('mem_bloodgroup', userData['mem_bloodgroup'] ?? '');
        await prefs.setString('mem_contactinformation', userData['mem_contactinformation'] ?? '');
        await prefs.setString('mem_religion', userData['mem_religion'] ?? '');
        await prefs.setString('mem_emergency_contact', userData['mem_emergency_contact'] ?? '');
        await prefs.setString('mem_tel', userData['mem_tel'] ?? '');
        await prefs.setString('mem_currentaddress', userData['mem_currentaddress'] ?? '');
        await prefs.setString('mem_passport', userData['mem_passport'] ?? '');
        await prefs.setString('mem_position', userData['mem_position'] ?? '');
        await prefs.setString('line_user_id', userData['line_user_id'] ?? '');
        await prefs.setString('mem_image', userData['mem_image'] ?? '');
        await prefs.setString('mem_children', userData['children_count'] ?? '');
        await prefs.setString('marital_status', userData['marital_status'] ?? '');
        await prefs.setString('country_name', userData['country_name'] ?? '');
        await prefs.setString('nationality_name', userData['nationality_name'] ?? '');
        await prefs.setString('group_name', userData['group_name'] ?? '');
        await prefs.setString('start_work', userData['start_work'] ?? '');
        await prefs.setString('birthdate', userData['birthdate'] ?? '');
        await prefs.setString('gender', userData['gender'] ?? '');

        print('User ID: $phone_number');
        print('User Name: $userName');
        print('Profile Picture: $profilePicture');
        print('Profile current_address: $current_address');
        _stopLoadingDialog(context); // ปิดสถานะโหลด
        _showLoginSuccessDialog(phone_number);
      } else {
        _stopLoadingDialog(context); // ปิดสถานะโหลด
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.green, size: 48),
                SizedBox(height: 12),
                Text(
                  'ไม่พบเบอร์โทรในระบบ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            content: Text(
              'ไม่มีเบอร์โทรนี้ในระบบ\nกรุณาติดต่อ Admin',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ToolUtility.colorCompany,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(Icons.close, color: Colors.white),
                label: Text('ปิด', style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
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
    if (phoneNumber == '0001112345' && pin == '123456') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone_number', '0001112345');
      await prefs.setString('token_otp', 'demo_token');
      await prefs.setString('id', '999');
      await prefs.setString('mem_fullname', 'Apple Review Tester');
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
        if (response['email'] != null) await prefs.setString('email', response['email']);
        if (response['password'] != null) await prefs.setString('password', response['password']);
        if (response['name'] != null) await prefs.setString('name', response['name']);
        if (response['profile_picture'] != null) await prefs.setString('profile_picture', response['profile_picture']);
        if (response['current_address'] != null) await prefs.setString('current_address', response['current_address']);

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

  void _requestNewOTP() async {
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
        _refno = newRefno; // อัปเดต refno ใหม่จาก API
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

  void _showLoginSuccessDialog(String phoneNumber) async {
    final refno = await _authService.sendOtp(phoneNumber);
    if (refno == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาติดต่อผู้ดูแลระบบ')),
      );
      return;
    }

    setState(() {
      _refno = refno;
      _isPinVisible = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('เข้าสู่ระบบสำเร็จ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('เบอร์โทรนี้ลงทะเบียนการใช้งานแล้ว'),
              SizedBox(height: 10),
              Text(
                'เราได้ส่ง OTP ไปยังหมายเลขโทรศัพท์ของคุณ\nกรุณายืนยันรหัส OTP เพื่อเข้าสู่ระบบ',
                textAlign: TextAlign.center,
              ),
              TextField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'กรอกรหัส OTP',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final pin = _pinController.text;

                if (pin.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('กรุณากรอกรหัส PIN')),
                  );
                  return;
                }

                _startLoadingDialog(context);
                final response = await _authService.verifyOtp(phoneNumber, pin);
                _stopLoadingDialog(context);

                if (response['success']) {
                  Navigator.pop(context); // ปิด Popup

                  // บันทึกข้อมูลการล็อกอิน
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('phone_number', phoneNumber);
                  await prefs.setString('token_otp', response['token'] ?? '');
                  await prefs.setString('id', response['id']?.toString() ?? '');
                  
                  // บันทึกข้อมูลอื่นๆ ที่ได้จาก response
                  if (response['email'] != null) await prefs.setString('email', response['email']);
                  if (response['password'] != null) await prefs.setString('password', response['password']);
                  if (response['name'] != null) await prefs.setString('name', response['name']);
                  if (response['profile_picture'] != null) await prefs.setString('profile_picture', response['profile_picture']);
                  if (response['current_address'] != null) await prefs.setString('current_address', response['current_address']);

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ยืนยัน OTP ไม่สำเร็จ')),
                  );
                }
              },
              child: Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
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

    if (phoneNumber != null && token != null && id != null) {
      // ถ้ามีข้อมูลการล็อกอินที่บันทึกไว้ ให้ไปที่หน้า HomeScreenCM โดยตรง
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
                                  backgroundColor: context.customTheme.primaryColor,
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
                                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: context.customTheme.primaryColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: context.customTheme.primaryColor.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  labelStyle: TextStyle(color: context.customTheme.primaryColor),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _submitPhoneNumber,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.customTheme.primaryColor,
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
                                TextField(
                                  controller: _pinController,
                                  decoration: InputDecoration(
                                    labelText: 'กรอกรหัส PIN',
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.5),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: context.customTheme.primaryColor),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: context.customTheme.primaryColor.withOpacity(0.5)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    labelStyle: TextStyle(color: context.customTheme.primaryColor),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: _verifyOTP,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.customTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text("ยืนยัน"),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: _isRequestEnabled ? _requestNewOTP : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isRequestEnabled 
                                        ? context.customTheme.primaryColor 
                                        : context.customTheme.secondaryColor,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    _isRequestEnabled
                                        ? 'ขอรหัสใหม่'
                                        : 'รอ ${_countdown}s เพื่อขอใหม่ได้',
                                  ),
                                ),
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
