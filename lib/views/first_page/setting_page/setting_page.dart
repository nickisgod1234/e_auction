import 'package:e_auction/views/first_page/request_otp_page/request_otp_login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/services/auth_service/auth_service.dart';
import 'package:e_auction/views/config/config_prod.dart';


class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> with WidgetsBindingObserver {
  bool _isConsentGiven = false;
  String? _memFullName = '';
  bool _isLoggedIn = false;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authService = AuthService(baseUrl: Config.apiUrlotpsever);
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
      fullName = prefs.getString('fullname');

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
    String? phoneNumber = prefs.getString('phone');

    if (!_isLoggedIn || userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ไม่พบข้อมูลการล็อกอิน กรุณาล็อกอินใหม่'),
      ));
      return;
    }

    // สำหรับ Apple test account (demo) ให้ล้างข้อมูลและเด้งไปหน้า login โดยไม่เรียก API
    if (userId == 'APPLE_TEST_ID' || phoneNumber == '0001112345') {
      await prefs.clear(); // Clear all data in SharedPreferences
      setState(() {
        _isLoggedIn = false;
        _memFullName = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ออกจากระบบเรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
      ));

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => RequestOtpLoginPage()),
          (Route<dynamic> route) => false,
        );
      }
      return;
    }

    final response = await _authService.deleteUser(customerId: userId);

    if (response != null && response['success'] == true) {
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
        content: Text(response?['message'] ?? 'ไม่สามารถลบบัญชีได้ กรุณาลองใหม่'),
        backgroundColor: Colors.red,
      ));
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
        title: Text('ตั้งค่าบัญชี', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Consent Switch
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.privacy_tip_outlined, color: Colors.black),
                title: Text('ยินยอมในการเก็บข้อมูล', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                subtitle: Text(_isConsentGiven ? 'ยินยอมให้เก็บข้อมูลแล้ว' : 'ยังไม่ได้ให้ความยินยอม', style: TextStyle(color: Colors.grey[700])),
                trailing: Switch(
                  value: _isConsentGiven,
                  onChanged: (bool newValue) {
                    if (!newValue) {
                      _showRevokeConsentDialog();
                    } else {
                      _saveConsentStatus(newValue);
                    }
                  },
                  activeColor: Colors.black,
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
              ),
            ),
            SizedBox(height: 16),
            // Delete Account
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
                title: Text('ลบบัญชี', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                subtitle: Text('ลบบัญชีและข้อมูลทั้งหมดอย่างถาวร', style: TextStyle(color: Colors.grey[700])),
                onTap: _showDeleteConfirmationDialog,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            SizedBox(height: 16),
            // Logout (optional)
            if (_isLoggedIn)
              Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.black),
                  title: Text('ออกจากระบบ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => RequestOtpLoginPage()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
