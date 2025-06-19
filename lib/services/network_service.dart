// import 'dart:convert';
// import 'dart:developer';

// import 'package:dio/dio.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../models/member_model.dart';

// class NetworkService {
//   // config
//   NetworkService._internal();
//   static final NetworkService _instance = NetworkService._internal();
//   factory NetworkService() => _instance;
//   static final _dio = Dio();

//   //get data
//   Future<List<Member>> fetchMembers(int startIndex, {int limit = 10}) async {
//     final prefs = await SharedPreferences.getInstance();
//     final String? token = prefs.getString('hrcloudToken'); //'token': '$token'
//     _dio.options.headers["token"] = '$token';

//     final url = 'XXX';

//     try {
//       final Response response = await _dio.get(url);
//       if (response.statusCode == 200) {
//         return memberFromJson(jsonEncode(response.data));
//       } else {
//         return memberFromJson(response.toString());
//       }
//     } catch (e) {
//       if (e is DioError) {
//         if (e.response?.data == null) {
//           log('data is null');
//         }
//         return memberFromJson([].toString());
//       } else {
//         return memberFromJson(e.toString());
//       }
//     }
//   }

//   //get data
//   Future<List<Member>> fetchPending(int startIndex, {int limit = 10}) async {
//     final prefs = await SharedPreferences.getInstance();
//     final String? token = prefs.getString('hrcloudToken'); //'token': '$token'
//     _dio.options.headers["token"] = '$token';

//     final url = 'XXX';

//     try {
//       final Response response = await _dio.get(url);
//       if (response.statusCode == 200) {
//         return memberFromJson(jsonEncode(response.data));
//       } else {
//         return memberFromJson(response.toString());
//       }
//     } catch (e) {
//       if (e is DioError) {
//         if (e.response?.data == null) {
//           log('data is null');
//         }
//         return memberFromJson([].toString());
//       } else {
//         return memberFromJson(e.toString());
//       }
//     }
//   }

//   //get data not use
//   Future<List<Member>> fetchComplete(int startIndex, {int limit = 10}) async {
//     final prefs = await SharedPreferences.getInstance();
//     final String? token = prefs.getString('hrcloudToken');
//     _dio.options.headers["token"] = '$token';

//     final url = 'XXX';

//     try {
//       final Response response = await _dio.get(url);
//       if (response.statusCode == 200) {
//         return memberFromJson(jsonEncode(response.data));
//       } else {
//         return memberFromJson(response.toString());
//       }
//     } catch (e) {
//       if (e is DioError) {
//         if (e.response?.data == null) {
//           log('data is null');
//         }
//         return memberFromJson([].toString());
//       } else {
//         return memberFromJson(e.toString());
//       }
//     }
//   }

//   //get data not use
//   Future<List<Member>> fetchSearch(String? projectname) async {
//     final prefs = await SharedPreferences.getInstance();
//     final String? token = prefs.getString('hrcloudToken'); //'token': '$token'
//     _dio.options.headers["token"] = '$token';

//     final url = 'XXX';

//     try {
//       final Response response = await _dio.get(url);
//       log(jsonEncode(response.data));
//       if (response.statusCode == 200) {
//         return memberFromJson(jsonEncode(response.data));
//       } else {
//         return memberFromJson(response.toString());
//       }
//     } catch (e) {
//       if (e is DioError) {
//         if (e.response?.data == null) {
//           log('data is null');
//         }
//         return memberFromJson([].toString());
//       } else {
//         return memberFromJson(e.toString());
//       }
//     }
//   }
// }
