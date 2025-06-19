// import 'dart:convert';
// import 'package:cm_raot/interceptors/network_interceptor.dart';
// import 'package:cm_raot/models/qouta_update_model.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../../config/config.dart';

// class UpdateQoutaProvider extends ChangeNotifier {
//   final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
//   bool _isLoading = false;
//   UpdateQouta? _updateqouta;

//   bool get isLoading => _isLoading;
//   UpdateQouta? get quotaData => _updateqouta;

//   UpdateQoutaProvider._internal();
//   static final UpdateQoutaProvider _instance = UpdateQoutaProvider._internal();
//   factory UpdateQoutaProvider() => _instance;

//   static final _dio = Dio();

//   Future<void> updateQouta({
//     DateTime? dateSupplierSent, // ทำให้ไม่จำเป็นต้องส่งค่า
//     required int qtySent,
//     required String qtyStatus,
//     int? weekNumber,
//     required int idCard,
//     required BuildContext context,
//   }) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     final String? token = prefs.getString('token_sp');

//     if (token == null || token.isEmpty) {
//       throw Exception('No token found');
//     }

//     final headers = {
//       'x-access-token': token,
//       'Content-Type': 'application/json',
//     };

//     // Create the UpdateQouta model (ตรวจสอบว่า dateSupplierSent มีค่าไหมก่อนใส่ในโมเดล)
//     final updateQouta = UpdateQouta(
//       qtySent: qtySent,
//       status: qtyStatus,
//       dateSupplierSent: dateSupplierSent, // สามารถส่งเป็น null ได้
//     );

//     // Convert the model to JSON
//     final body = updateQouta.toJson();
//     body['week_number'] = weekNumber ?? 0;
//     body['id'] = idCard;

//     try {
//       final response = await _dio.put(
//         '${Config.baseUrlkn}/sp/api/quota/$idCard',
//         data: json.encode(body),
//         options: Options(headers: headers),
//       );

//       if (response.statusCode == 200) {
//         print('Quota updated successfully');
//         notifyListeners(); // Notify listeners if needed
//       } else if (response.statusCode == 401) {
//         Navigator.of(context).pushReplacementNamed('/LoginSpPage');
//       } else {
//         throw Exception('Failed to update quota: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error updating quota: $e');
//       // Handle the exception if needed
//     }
//   }
// }
