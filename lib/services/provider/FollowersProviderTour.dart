// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:cm_raot/models/getall_follower.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class FollowersProviderTour with ChangeNotifier {
//   int tiktokFollowers = 0;
//   int facebookFollowers = 0;
//   int lineFollowers = 0;
//   int youtubeFollowers = 0;

//   String latestUpdateDateTikTok =
//       DateFormat('dd/MM/yyyy').format(DateTime.now());
//   String latestUpdateDateFacebook =
//       DateFormat('dd/MM/yyyy').format(DateTime.now());
//   String latestUpdateDateLine = DateFormat('dd/MM/yyyy').format(DateTime.now());
//   String latestUpdateDateYouTube =
//       DateFormat('dd/MM/yyyy').format(DateTime.now());

//   // List to hold followers history
//   List<FollowersHistory> _followersHistory = [];
//   TotalFollowers _totalFollowers = TotalFollowers(
//     totalTikTok: 0,
//     totalFacebook: 0,
//     totalLine: 0,
//     totalYouTube: 0,
//   );

//   // Getter to expose followers history
//   List<FollowersHistory> get followersHistory => _followersHistory;
//   TotalFollowers get totalFollowers => _totalFollowers;

//   Future<void> fetchFollowers() async {
//     try {
//       final response = await http.get(
//         //test
//         // Uri.parse(
//         //     'http://192.168.1.72/HR-API/social_check_tour/getall_followers.php')
//         Uri.parse(
//             'https://www.cm-mejobs.com/HR-API/social_check_tour/getall_followers.php'),
//       );

//       if (response.statusCode == 200) {
//         final result = GetallFollowers.fromJson(jsonDecode(response.body));
//         if (result.success) {
//           // Update current totals
//           final latest = result.data.isNotEmpty ? result.data.first : null;
//           if (latest != null) {
//             tiktokFollowers = latest.totalTikTok;
//             facebookFollowers = latest.totalFacebook;
//             lineFollowers = latest.totalLine;
//             youtubeFollowers = latest.totalYouTube;

//             latestUpdateDateTikTok =
//                 DateFormat('dd/MM/yyyy').format(DateTime.parse(latest.date));
//             latestUpdateDateFacebook =
//                 DateFormat('dd/MM/yyyy').format(DateTime.parse(latest.date));
//             latestUpdateDateLine =
//                 DateFormat('dd/MM/yyyy').format(DateTime.parse(latest.date));
//             latestUpdateDateYouTube =
//                 DateFormat('dd/MM/yyyy').format(DateTime.parse(latest.date));
//           }

//           // Update followers history and total
//           _followersHistory = result.data;
//           _totalFollowers = result.total;

//           notifyListeners();
//         } else {
//           throw Exception('Failed to fetch data');
//         }
//       } else {
//         throw Exception('Server error: ${response.statusCode}');
//       }
//     } catch (error) {
//       throw Exception('Error: $error');
//     }
//   }

//   Future<void> addFollowers(Map<String, dynamic> data) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       var memfullname = prefs.getString('mem_fullname').toString();
//       data['mem_fullname'] = memfullname;
//       final response = await http.post(
//         // Uri.parse(
//         //     'http://192.168.1.72/HR-API/social_check_tour/add_followers.php'),
//         Uri.parse(
//             'https://www.cm-mejobs.com/HR-API/social_check_tour/add_followers.php'),
//         headers: {
//           'Content-Type': 'application/x-www-form-urlencoded',
//         },
//         body: data,
//       );

//       if (response.statusCode == 200) {
//         final result = jsonDecode(response.body);
//         if (result['success']) {
//           await fetchFollowers();
//         } else {
//           throw Exception('Failed to insert data');
//         }
//       } else {
//         throw Exception('Server error: ${response.statusCode}');
//       }
//     } catch (error) {
//       throw Exception('Error: $error');
//     }
//   }
// }
