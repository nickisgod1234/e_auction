// import 'dart:convert';
// import 'package:cm_raot/models/qouta_detail_model.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../../config/config.dart';

// class PageQuotaDetailProvider extends ChangeNotifier {
//   final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
//   bool _isLoading = false;
//   QoutaDetailPageModeal? _quotaDetail;

//   bool get isLoading => _isLoading;
//   QoutaDetailPageModeal? get quotaDetail => _quotaDetail;

//   static final _dio = Dio();

//   Future<void> fetchQuotaDetailData(String orderNum) async {
//     final SharedPreferences prefs = await _prefs;
//     _isLoading = true;
//     notifyListeners();

//     final String? token = prefs.getString('token_sp');
//     if (token == null || token.isEmpty) {
//       print('No token found');
//       _isLoading = false;
//       _quotaDetail = null;
//       notifyListeners();
//       return;
//     }

//     final headers = {
//       'x-access-token': token,
//       'Content-Type': 'application/json',
//     };

//     try {
//       final response = await _dio.get(
//         '${Config.baseUrlkn}/sp/api/quota/$orderNum', // use the active base URL from Config
//         options: Options(headers: headers),
//       );

//       print('Response status code: ${response.statusCode}');
//       print('Response data: ${response.data}');

//       if (response.statusCode == 200) {
//         final jsonResponse = response.data;
//         _quotaDetail = QoutaDetailPageModeal.fromJson(jsonResponse);
//       } else if (response.statusCode == 401) {
//         _quotaDetail = null;
//       } else {
//         throw Exception('Failed to load quota detail data');
//       }
//     } catch (e) {
//       print('Error fetching quota detail data: $e');
//       _quotaDetail = null;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }
