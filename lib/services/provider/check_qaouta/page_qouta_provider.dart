// import 'dart:convert';
// import 'package:cm_raot/models/qouta_model.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../../config/config.dart';

// class PageQoutaProvider extends ChangeNotifier {
//   final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
//   bool _isLoading = false;
//   QuotaModel? _quotaData;

//   bool get isLoading => _isLoading;
//   QuotaModel? get quotaData => _quotaData;

//   PageQoutaProvider._internal();
//   static final PageQoutaProvider _instance = PageQoutaProvider._internal();
//   factory PageQoutaProvider() => _instance;

//   static final _dio = Dio();

//   Future<void> fetchQuotaData() async {
//     final SharedPreferences prefs = await _prefs;
//     _isLoading = true;
//     notifyListeners();

//     final String? token = prefs.getString('token_sp');
//     if (token == null || token.isEmpty) {
//       print('No token found');
//       _isLoading = false;
//       _quotaData = null;
//       notifyListeners();
//       return;
//     }

//     final headers = {
//       'x-access-token': token,
//       'Content-Type': 'application/json',
//     };

//     try {
//       final response = await _dio.get(
//         '${Config.baseUrlkn}/sp/api/quota',
//         options: Options(headers: headers),
//       );

//       print('API Response: ${response.data}');

//       if (response.statusCode == 200) {
//         var jsonResponse = response.data;

//         // ตรวจสอบว่า jsonResponse ไม่เป็น null
//         if (jsonResponse != null) {
//           // Parse response into QuotaModel
//           _quotaData = QuotaModel.fromJson(jsonResponse);

//           // Sort data_res if needed
//           _quotaData!.dataRes.sort((a, b) {
//             return b.dateStart.compareTo(
//                 a.dateStart); // Sort by dateStart in descending order
//           });

//           print('Sorted data: ${_quotaData!.dataRes}');
//         } else {
//           print('Response is empty');
//           _quotaData = null;
//         }
//       } else if (response.statusCode == 401) {
//         print('Unauthorized request. Token may be expired.');
//         _quotaData = null;
//         // Handle navigation to login page or show a dialog
//         // เช่นแสดง AlertDialog เพื่อแจ้งเตือนผู้ใช้
//       } else {
//         throw Exception(
//             'Failed to load quota data. Status code: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching quota data: $e');
//       _quotaData = null;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }
