import 'package:e_auction/views/first_page/request_otp_page/request_otp_login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:e_auction/services/api_provider.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> with WidgetsBindingObserver {
  bool _isConsentGiven = false;
  String? _memFullName = '';
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginAndLoadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app is resumed, check login status again to ensure UI is up to date
      _checkLoginAndLoadData();
    }
  }

  Future<void> _checkLoginAndLoadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('id');

    print('--- [Settings Page] Checking Data ---');
    print('Token from prefs: $token');
    print('UserID from prefs: $userId');

    final bool loggedIn = userId != null && userId.isNotEmpty;

    String? fullName;

    if (loggedIn) {
      // If logged in, get user data from SharedPreferences
      fullName = prefs.getString('mem_fullname');

      print('FullName from prefs: $fullName');
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _isConsentGiven = prefs.getBool('userConsent') ?? loggedIn;
        // Update name
        _memFullName = fullName;
      });
    }
  }

  void _saveConsentStatus(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('userConsent', value);
    setState(() {
      _isConsentGiven = value;
    });

    if (!value) {
      // If user revokes consent, log them out and clear data.
      await prefs.clear();
      await prefs.setBool('userConsent', false); // Keep consent status

      setState(() {
        _isLoggedIn = false;
        _memFullName = '';
      });

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => RequestOtpLoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  void _deleteAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('id');

    if (!_isLoggedIn || userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ไม่พบข้อมูลการล็อกอิน กรุณาล็อกอินใหม่'),
      ));
      return;
    }

    final response = await _callDeleteApi(userId);

    if (response['status'] == 'success') {
      await prefs.clear(); // Clear all data in SharedPreferences
      setState(() {
        _isLoggedIn = false;
        _memFullName = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('บัญชีถูกลบเรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
      ));

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => RequestOtpLoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message'] ?? 'ไม่สามารถลบบัญชีได้ กรุณาลองใหม่'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<Map<String, dynamic>> _callDeleteApi(String userId) async {
    final String url =
        'https://www.cm-mejobs.com/HR-API/personal/is_delete_user.php?id=$userId';
      

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 'error', 'message': 'เกิดข้อผิดพลาดในการติดต่อเซิร์ฟเวอร์'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้'};
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการลบบัญชี'),
          content: Text(
              'คุณแน่ใจหรือไม่ว่าต้องการลบบัญชีของคุณ? การกระทำนี้จะลบข้อมูลทั้งหมดของคุณอย่างถาวรและไม่สามารถกู้คืนได้'),
          actions: <Widget>[
            TextButton(
              child: Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('ลบบัญชี'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  void _showRevokeConsentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการยกเลิกการยินยอม'),
          content: Text(
              'การยกเลิกการยินยอมจะทำให้คุณออกจากระบบและล้างข้อมูลทั้งหมดที่จัดเก็บไว้ คุณต้องการดำเนินการต่อหรือไม่?'),
          actions: <Widget>[
            TextButton(
              child: Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('ยืนยัน', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _saveConsentStatus(false);
              },
            ),
          ],
        );
      },
    );
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
            if (_isLoggedIn)
              // Logged In View
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
                    const Row(
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
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.person_outline,
                          color: Colors.grey.shade600),
                      title: Text('ชื่อผู้ใช้'),
                      subtitle: Text(_memFullName ?? 'ไม่พบข้อมูล'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.delete_forever, color: Colors.red),
                      title: Text('ลบบัญชี',
                          style: TextStyle(color: Colors.red)),
                      onTap: _showDeleteConfirmationDialog,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              )
            else
              // Logged Out View
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'คุณยังไม่ได้เข้าสู่ระบบ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'กรุณาเข้าสู่ระบบเพื่อจัดการข้อมูลบัญชีของคุณ',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => RequestOtpLoginPage()),
                            (Route<dynamic> route) => false);
                      },
                      child: Text('ไปที่หน้าเข้าสู่ระบบ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Consent Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ยินยอมในการเก็บข้อมูล',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _isConsentGiven
                              ? 'ยินยอมให้เก็บข้อมูลแล้ว'
                              : 'ยังไม่ได้ให้ความยินยอม',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isConsentGiven,
                    onChanged: (bool newValue) {
                      if (!newValue) {
                        _showRevokeConsentDialog();
                      } else {
                        _saveConsentStatus(newValue);
                      }
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
