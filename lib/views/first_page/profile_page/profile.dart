import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/views/first_page/request_otp_page/request_otp_login.dart';
import 'package:e_auction/views/first_page/profile_page/widget_profile/widget_profile.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, String> userData = {};
  bool isLoading = true;
  String? userProfilePicture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserProfilePicture();
  }
 Future<void> _loadUserProfilePicture() async {
    print('Debug - _loadUserProfilePicture started');
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      print('Debug - Got SharedPreferences');

      final storedPhoneNumber = prefs.getString('phone_number');
      print('Debug - Phone Number: $storedPhoneNumber');

      if (storedPhoneNumber == null || storedPhoneNumber.isEmpty) {
        print('Debug - No phone number found, using default image');
        setState(() {
          userProfilePicture = null;
        });
        return;
      }

      final url = Uri.parse(
          '${Config.apiUrlotpsever}login_phone_local/check_phone.php');
      print('Debug - API URL: $url');

      final response = await http.post(
        url,
        body: jsonEncode({'phone_number': storedPhoneNumber}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      print('Debug - API Response Status: ${response.statusCode}');
      print('Debug - API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Debug - Decoded API Response: $data');

        if (data['success'] == true && data['data'] != null) {
          final userData = data['data'];
          String? profilePicPath = userData['profile_picture'];
          
          print('Debug - Raw profile_picture from API: $profilePicPath');
          
          if (profilePicPath != null && profilePicPath.isNotEmpty) {
            // Construct full URL from relative path
            String fullUrl;
            if (profilePicPath.startsWith('http')) {
              fullUrl = profilePicPath;
            } else {
              // Remove leading slash if present and construct full URL
              if (profilePicPath.startsWith('/')) {
                profilePicPath = profilePicPath.substring(1);
              }
              fullUrl = '${Config.apiUrlotpsever}$profilePicPath';
            }
            
            print('Debug - Constructed full URL: $fullUrl');
            setState(() {
              userProfilePicture = fullUrl;
            });
          } else {
            print('Debug - No profile picture path found in API response');
            setState(() {
              userProfilePicture = null;
            });
          }
        } else {
          print('Debug - API response indicates failure or no data');
          setState(() {
            userProfilePicture = null;
          });
        }
      } else {
        print('Debug - API call failed with status: ${response.statusCode}');
        setState(() {
          userProfilePicture = null;
        });
      }
    } catch (e) {
      print('Debug - Error in _loadUserProfilePicture: $e');
      setState(() {
        userProfilePicture = null;
      });
    }
    print('Debug - _loadUserProfilePicture completed');
  }
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userData = {
        'phone_number': prefs.getString('phone_number') ?? '',
        'id': prefs.getString('id') ?? '',
        'email': prefs.getString('email') ?? '',
        'password': prefs.getString('password') ?? '',
        'name': prefs.getString('name') ?? '',
        'firstname': prefs.getString('firstname') ?? '',
        'lastname': prefs.getString('lastname') ?? '',
        'current_address': prefs.getString('current_address') ?? '',
        'profile_picture': prefs.getString('profile_picture') ?? '',
        'role_name_th': prefs.getString('role_name_th') ?? '',
        'position_id': prefs.getString('position_id') ?? '',
        'department_id': prefs.getString('department_id') ?? '',
        'branch_id': prefs.getString('branch_id') ?? '',
        'mem_fullname': prefs.getString('mem_fullname') ?? '',
        'mem_idcard': prefs.getString('mem_idcard') ?? '',
        'mem_tel': prefs.getString('mem_tel') ?? '',
        'mem_currentaddress': prefs.getString('mem_currentaddress') ?? '',            
        'mem_bloodgroup': prefs.getString('mem_bloodgroup') ?? '',
        'mem_religion': prefs.getString('mem_religion') ?? '',
        'marital_status': prefs.getString('marital_status') ?? '',
        'nationality_name': prefs.getString('nationality_name') ?? '',
        'start_work': prefs.getString('start_work') ?? '',
        'birthdate': prefs.getString('birthdate') ?? '',
        'gender': prefs.getString('gender') ?? '',
        'mem_position': prefs.getString('mem_position') ?? '',
        'mem_birthdate': prefs.getString('mem_birthdate') ?? '',
        'mem_sex': prefs.getString('mem_sex') ?? '',
      };
      isLoading = false;
    });
    
    // Print all loaded data
    print('=== LOADED USER DATA ===');
    userData.forEach((key, value) {
      print('$key: $value');
    });
    print('========================');
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการออกจากระบบ'),
          content: Text('คุณต้องการออกจากระบบหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // ลบข้อมูลทั้งหมด
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RequestOtpLoginPage(),
                  ),
                );
              },
              child: Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('โปรไฟล์'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('โปรไฟล์'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            ProfileHeader(userData: userData, profilePicture: userProfilePicture),

            // Personal Information
            PersonalInfoSection(userData: userData),

            // Work Information
            WorkInfoSection(userData: userData),

            // Address Information
            AddressInfoSection(userData: userData),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
