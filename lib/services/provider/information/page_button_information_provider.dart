// import 'package:cm_supplier/interceptors/network_interceptor.dart';
// import 'package:cm_supplier/interceptors/page_average_interceptor.dart';
// import 'package:cm_supplier/models/page_average.model.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';

// class PageButtonInformationProvider with ChangeNotifier {
//   List<Product> _products = [];
//   bool _isLoading = true;

//   List<Product> get products => _products;
//   bool get isLoading => _isLoading;

//   late Dio _dio;

//   PageButtonInformationProvider() {
//     _dio = Dio()
//       ..interceptors
//           .add(NetworkInterceptor()); // เพิ่ม PageAverageInterceptor ที่นี่
//   }

//   Future<void> fetchProducts() async {
//     try {
//       final response = await _dio.get(
//           '/HR-API/sp_mobile/price_average_new.php'); // ใช้ path ที่ไม่รวม baseUrl
//       if (response.statusCode == 200) {
//         final data = response.data['data'] as List;
//         _products = data.map((item) => Product.fromJson(item)).toList();
//       }
//     } catch (e) {
//       print('Error fetching products: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }
