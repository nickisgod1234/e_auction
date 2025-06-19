// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../config/config_prod.dart';
// import 'package:flutter/material.dart';

// class ProfilePictureService {
//   static String? _userProfilePicture;

//   static String? get userProfilePicture => _userProfilePicture;

//   static Future<void> loadProfilePicture() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final storedPhoneNumber = prefs.getString('phone_number');
    
//     if (storedPhoneNumber == null || storedPhoneNumber.isEmpty) {
//       print('No phone number found in SharedPreferences');
//       return;
//     }

//     final url = Uri.parse('${Config.apiUrl}/login_phone_local/check_phone.php');
//     try {
//       print('Making API call to: $url');
//       final response = await http.post(
//         url,
//         body: jsonEncode({'phone_number': storedPhoneNumber}),
//         headers: {'Content-Type': 'application/json'},
//       );

//       print('Response status: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['success'] && data['data']['status'] == "exists") {
//           print('User data exists. Profile Picture: ${data['data']['profile_picture']}');
//           _userProfilePicture = data['data']['profile_picture'];
//         }
//       }
//     } catch (e) {
//       print('Error while loading user profile picture: $e');
//     }
//   }

//   static ImageProvider getProfilePicture() {
//     if (_userProfilePicture != null) {
//       return NetworkImage(Uri.parse('${Config.apiUrl}/HR-API/img/images/${_userProfilePicture!}').toString());
//     }
//     return AssetImage('assets/images/profile.png');
//   }
// } 