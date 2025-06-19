import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:e_auction/services/api_provider.dart';
import 'package:e_auction/views/first_page/request_otp_page/request_otp_login.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _isConsentGiven = false;
  String? _memFullName = '';
  String? _memEmail = '';
  bool _isLoggedIn = false;
  String? apiKey; // เพิ่มตัวแปรสำหรับเก็บ API Key

  @override
  void initState() {
    super.initState();
    _loadConsentStatus();
    _getProfile();
    _loadApiKey(); // เพิ่มการโหลด API Key
  }

  // เพิ่มเมธอดสำหรับโหลด API Key
  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiKey = prefs.getString('system_api_key');
    });
  }

  void _loadConsentStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('id');
    String? phoneNumber = prefs.getString('phone_number');

    // แสดงค่าของ token และ id ในคอนโซล
    print('Token: $token');
    print('UserID: $userId');
    print('Phone Number: $phoneNumber');

    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      // เมื่อเข้ามาที่ setting ให้ยินยอมให้เก็บข้อมูลเลย
      _isConsentGiven = true;
    });
  }

  void _deleteAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('id');

    if (token == null || token.isEmpty) {
      // ถ้าไม่มี token
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ไม่พบข้อมูลการล็อกอิน กรุณาล็อกอินใหม่'),
      ));
      return;
    }

    if (userId == null || userId.isEmpty) {
      // ถ้าไม่มี userId
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ไม่พบ ID ของผู้ใช้'),
      ));
      return;
    }

    // ส่งคำขอไปยัง API เพื่อลบบัญชี
    final response = await _callDeleteApi(userId);

    if (response['status'] == 'success') {
      await prefs.clear(); // ลบข้อมูลทั้งหมดใน SharedPreferences
      setState(() {
        _isLoggedIn = false;
        _memFullName = '';
        _memEmail = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('บัญชีถูกลบเรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ไม่สามารถลบบัญชีได้ กรุณาลองใหม่'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _saveConsentStatus(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // ถ้าผู้ใช้ปิดการยินยอม
    if (!value) {
      // ล้างข้อมูลทั้งหมด
      await prefs.clear();
      
      // ล้าง API Key ด้วย
      final apiProvider = ApiProvider();
      await apiProvider.clearApiKey();
      
      setState(() {
        _isConsentGiven = false;
        _isLoggedIn = false;
        _memFullName = '';
        _memEmail = '';
      });

      // นำทางไปหน้า Login ทันที
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => RequestOtpLoginPage(),
        ),
        (Route<dynamic> route) => false,
      );
      
      return;
    }

    // บันทึกสถานะการยินยอม
    await prefs.setBool('userConsent', value);

    setState(() {
      _isConsentGiven = value;
    });
  }

  Future<void> _getProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _memFullName = prefs.getString('mem_fullname') ?? 'ไม่มี';
      _memEmail = prefs.getString('mem_email') ?? 'ไม่มี';
    });
  }

  void _clearProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('mem_fullname');
    await prefs.remove('mem_email');
    await prefs.remove('mem_status');
    await prefs.remove('mem_tel');
    await prefs.remove('token');
  }

  // ฟังก์ชันลบบัญชี

  // ฟังก์ชันส่งคำขอ DELETE ไปยัง API
  Future<Map<String, dynamic>> _callDeleteApi(String userId) async {
    final String url =
        'https://www.cm-mejobs.com/HR-API/personal/is_delete_user.php?id=$userId'; // ส่ง userId เป็น parameter ใน URL

    try {
      final response =
          await http.get(Uri.parse(url)); // ใช้ GET request แทน POST

      if (response.statusCode == 200) {
        // แปลงผลลัพธ์เป็น JSON
        final data = json.decode(response.body);
        return data;
      } else {
        // ถ้า statusCode ไม่ใช่ 200 ให้แสดงข้อความผิดพลาด
        return {'status': 'error', 'message': 'เกิดข้อผิดพลาดในการติดต่อ API'};
      }
    } catch (e) {
      // กรณีที่เกิดข้อผิดพลาดจากการเชื่อมต่อ API
      return {'status': 'error', 'message': 'ไม่สามารถเชื่อมต่อกับ API'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('การตั้งค่า'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // แสดง API Key
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Row(
                  //       children: [
                  //         Icon(Icons.api, color: Colors.green),
                  //         SizedBox(width: 8),
                  //         Text(
                  //           'API Key: ${apiKey ?? "ไม่พบข้อมูล"}',
                  //           style: TextStyle(fontSize: 16),
                  //         ),
                  //       ],
                  //     ),
                  //     TextButton(
                  //       onPressed: () => _showChangeApiKeyDialog(),
                  //       child: Text('เปลี่ยน'),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // แสดงข้อมูลผู้ใช้เมื่อยินยอมให้เก็บข้อมูล
            if (_isConsentGiven) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'ข้อมูลผู้ใช้',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.person_outline, color: Colors.grey),
                      title: Text('ชื่อผู้ใช้'),
                      subtitle: Text(
                        _memFullName ?? 'ไม่ระบุชื่อ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    ListTile(
                      leading: Icon(Icons.email_outlined, color: Colors.grey),
                      title: Text('อีเมล'),
                      subtitle: Text(
                        _memEmail ?? 'ไม่ระบุอีเมล',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
            
            SwitchListTile(
              title: Text('ยินยอมในการเก็บข้อมูล'),
              subtitle: Text(
                _isConsentGiven 
                  ? 'ยินยอมให้เก็บข้อมูลแล้ว'
                  : 'เปิดเพื่อยินยอมให้เก็บข้อมูลส่วนตัว',
                style: TextStyle(
                  color: _isConsentGiven ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: _isConsentGiven,
              onChanged: (bool newValue) {
                if (!newValue) {
                  // ถ้าปิดการยินยอม ให้แสดง dialog ยืนยัน
                  _showRevokeConsentDialog();
                } else {
                  // ถ้าเปิดการยินยอม
                  _saveConsentStatus(newValue);
                }
              },
            ),
            Divider(),
            
            if (_isLoggedIn && _isConsentGiven) ...[
              ListTile(
                title: ElevatedButton(
                  onPressed: () {
                    // แสดง dialog เพื่อยืนยันการลบบัญชี
                    _showDeleteConfirmationDialog(context);
                  },
                  child: Text('ลบบัญชี'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              Divider(),
            ],
          ],
        ),
      ),
    );
  }

// ฟังก์ชันแสดงการยืนยันลบบัญชี
  void _showDeleteConfirmationDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการลบบัญชี'),
          content: Text('คุณต้องการลบบัญชีนี้จริงหรือไม่?'),
          actions: <Widget>[
            TextButton(
              child: Text('ยกเลิก'),
              onPressed: () {
                // ปิด dialog เมื่อเลือกยกเลิก
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('ยืนยัน'),
              onPressed: () {
                // ปิด dialog และเรียกฟังก์ชันลบบัญชี
                Navigator.of(context).pop();
                _deleteAccount(); // เรียกฟังก์ชันลบบัญชี
              },
            ),
          ],
        );
      },
    );
  }

  void _showChangeApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('เปลี่ยน API Key'),
        content: Text('การเปลี่ยน API Key จะทำให้คุณออกจากระบบ\nต้องการดำเนินการต่อหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              // ล้างข้อมูล API Key และข้อมูลอื่นๆ
              final apiProvider = ApiProvider();
              await apiProvider.clearApiKey();
              
              // กลับไปหน้า App Code
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/app_code',
                (Route<dynamic> route) => false,
              );
            },
            child: Text('ยืนยัน'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showRevokeConsentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการยกเลิกการยินยอม'),
          content: Text('การยกเลิกการยินยอมจะทำให้คุณออกจากระบบและล้างข้อมูลทั้งหมด\nต้องการดำเนินการต่อหรือไม่?'),
          actions: <Widget>[
            TextButton(
              child: Text('ยกเลิก'),
              onPressed: () {
                // ปิด dialog เมื่อเลือกยกเลิก
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('ยืนยัน', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // ปิด dialog และเรียกฟังก์ชันยกเลิกการยินยอม
                Navigator.of(context).pop();
                _saveConsentStatus(false);
              },
            ),
          ],
        );
      },
    );
  }
}
