// import 'dart:convert';

// import 'package:cm_raot/interceptors/v1_network_interceptor.dart';
// import 'package:cm_raot/models/profile_model.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class PageInformationProvider extends ChangeNotifier {
//   final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
//   bool _isLoading = false;
//   ProfileModel? _profile;

//   bool get isLoading => _isLoading;
//   ProfileModel? get user => _profile;

//   PageInformationProvider._internal();
//   static final PageInformationProvider _instance =
//       PageInformationProvider._internal();
//   factory PageInformationProvider() => _instance;

//   static final _dio = Dio()..interceptors.add(V1NetworkInterceptor());

//   Future<void> fetchProductData(BuildContext context) async {
//     final SharedPreferences prefs = await _prefs;
//     _isLoading = true;

//     final url = 'mobile/product/all';

//     try {
//       final Response response = await _dio.get(url);
//       if (response.statusCode == 200) {
//         _profile = profileModelFromJson(jsonEncode(response.data));
//       } else {
//         throw Exception('Failed to load profile data');
//       }
//     } catch (e) {
//       print('Error fetching profile data: $e');

//       // Mock data in case of an error
//       const mockData = {
//         "status": "success",
//         "data_res": {
//           "id": 2,
//           "company_name": "SPE02",
//           "fname": "SPE02",
//           "lname": "SPE02",
//           "email": "SPE02@SPE02.com",
//           "pdpa": false,
//           "suspended": false,
//           "createdAt": "2024-08-30T04:03:46.937Z",
//           "updatedAt": "2024-08-30T04:03:46.937Z"
//         }
//       };

//       // Assign the mock data to _profile
//       _profile = profileModelFromJson(jsonEncode(mockData));
//     } finally {
//       // ตรวจสอบว่า widget ยัง mounted อยู่ก่อนที่จะ notifyListeners
//       if (context.mounted) {
//         _isLoading = false;
//         notifyListeners();
//       }
//     }
//   }
// }
