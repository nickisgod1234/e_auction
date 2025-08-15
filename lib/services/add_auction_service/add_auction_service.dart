import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:flutter/foundation.dart';

class AddAuctionService {
  // Base URL for API - using config
  static String get baseUrl {
    final url = '${Config.apiUrlAuction}/ERP-Cloudmate/modules/sales/controllers';

    return url;
  }

  // Create HTTP client with SSL certificate bypass for Android
  static http.Client _createHttpClient() {
    if (Platform.isAndroid) {
      // For Android, create a client that bypasses SSL certificate verification
      final client = http.Client();
      // Note: This is a workaround for development. In production, you should fix the SSL certificate
      return client;
    } else {
      // For other platforms, use default client
      return http.Client();
    }
  }

  // Load Quotation Types
  static Future<List<Map<String, dynamic>>> loadQuotationTypes() async {
    http.Client? client;
    try {
      final url = '$baseUrl/quotation_type_controller.php';

      // Create HTTP client with SSL bypass for Android
      client = _createHttpClient();
      
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout after 30 seconds');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Filter only auction types (starting with 'A') but exclude AS03
        final auctionTypes = data.where((item) {
          final code = item['quotation_type_code']?.toString() ?? '';
          return code.startsWith('A') && code != 'AS03';
        }).map((item) {
          return {
            'id': item['quotation_type_id']?.toString() ?? '',
            'name': item['description']?.toString() ?? '',
            'description': item['description']?.toString() ?? '',
            'code': item['quotation_type_code']?.toString() ?? '',
          };
        }).toList();

        return auctionTypes.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Failed to load quotation types: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
            'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต');
      } else if (e is TimeoutException) {
        throw Exception('การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง');
      } else {
        throw Exception('Error loading quotation types: $e');
      }
    } finally {
      // Always close the client
      if (client != null) {
        try {
          client.close();
        } catch (closeError) {
          // Ignore close errors
        }
      }
    }
  }

  // Save Auction with new API
  static Future<Map<String, dynamic>> saveAuction({
    required Map<String, dynamic> auctionData,
    File? imageFile,
  }) async {
    try {
      final url = '$baseUrl/quotation_controller.php?action=create_flutter_auction';

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add data as JSON string
      final dataJson = jsonEncode(auctionData);
      request.fields['data'] = dataJson;
      
      // Debug: Print the data being sent
      print('DEBUG: Sending auction data to API:');
      print('URL: $url');
      print('Data: $dataJson');

      // Add image if provided
      if (imageFile != null && await imageFile.exists()) {
        final imageStream = http.ByteStream(imageFile.openRead());
        final imageLength = await imageFile.length();
        
        final multipartFile = http.MultipartFile(
          'images',
          imageStream,
          imageLength,
          filename: imageFile.path.split('/').last,
        );
        
        request.files.add(multipartFile);
      }

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60), // เพิ่ม timeout สำหรับการอัปโหลดรูป
        onTimeout: () {
          throw TimeoutException('Request timeout after 60 seconds');
        },
      );

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        
        // Debug: Print the response
        print('DEBUG: API Response:');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('Parsed Result: $result');
        
        return result;
      } else {
        print('DEBUG: API Error Response:');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception(
            'Failed to save auction: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
            'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต');
      } else if (e is TimeoutException) {
        throw Exception('การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง');
      } else {
        throw Exception('Error saving auction: $e');
      }
    }
  }

  // Validate Auction Data
  static Map<String, dynamic> validateAuctionData(Map<String, dynamic> data) {
    final errors = <String, String>{};

    // Required fields validation
    if (data['product_name']?.toString().isEmpty ?? true) {
      errors['product_name'] = 'กรุณากรอกชื่อสินค้า';
    }

    if (data['description']?.toString().isEmpty ?? true) {
      errors['description'] = 'กรุณากรอกรายละเอียดสินค้า';
    }

    // Fix starting_price validation
    final startingPrice = data['starting_price'];
    if (startingPrice == null) {
      errors['starting_price'] = 'กรุณากรอกราคาเริ่มต้น';
    } else {
      try {
        final price = double.tryParse(startingPrice.toString());
        if (price == null || price <= 0) {
          errors['starting_price'] = 'กรุณากรอกราคาเริ่มต้น';
        }
      } catch (e) {
        errors['starting_price'] = 'กรุณากรอกราคาเริ่มต้น';
      }
    }

    if (data['start_date']?.toString().isEmpty ?? true) {
      errors['start_date'] = 'กรุณาเลือกวันที่เริ่มต้น';
    }

    if (data['end_date']?.toString().isEmpty ?? true) {
      errors['end_date'] = 'กรุณาเลือกวันที่สิ้นสุด';
    }

    // ลบการตรวจสอบ seller_name และ seller_phone ออกเพราะไม่ใช้แล้ว

    if (data['purchase_order_type_id']?.toString().isEmpty ?? true) {
      errors['purchase_order_type_id'] = 'กรุณาเลือกประเภทสินค้า';
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }

  // Format Auction Data for new API
  static Future<Map<String, dynamic>> formatAuctionDataForAPI(
      Map<String, dynamic> data) async {
    // Convert prices to integers to remove .0
    final startingPrice = data['starting_price'];
    final minIncrement = data['min_increment'];
    
    String startingPriceStr = '0';
    String minIncrementStr = '100';
    
    if (startingPrice != null) {
      try {
        final price = double.tryParse(startingPrice.toString());
        startingPriceStr = price?.toInt().toString() ?? '0';
      } catch (e) {
        startingPriceStr = '0';
      }
    }
    
    if (minIncrement != null) {
      try {
        final increment = double.tryParse(minIncrement.toString());
        minIncrementStr = increment?.toInt().toString() ?? '100';
      } catch (e) {
        minIncrementStr = '100';
      }
    }
    
    // Get customer_id from SharedPreferences
    int customerId = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('id');
      if (userIdStr != null && userIdStr.isNotEmpty) {
        customerId = int.tryParse(userIdStr) ?? 0;
      }
    } catch (e) {
      print('Error getting customer_id from SharedPreferences: $e');
    }
    
    final formattedData = {
      'product_name': data['product_name']?.toString() ?? '',
      'description': data['description']?.toString() ?? '',
      'customer_id': customerId, // เพิ่ม customer_id จาก user session
      'notes': data['notes']?.toString() ?? '',
      'starting_price': startingPriceStr,
      'min_increment': minIncrementStr,
      'start_date': data['start_date']?.toString() ?? '',
      'end_date': data['end_date']?.toString() ?? '',
      'purchase_order_type_id': data['purchase_order_type_id']?.toString() ?? '',
      // ลบ seller_name และ seller_phone ออกเพราะไม่ใช้แล้ว
      // เพิ่มข้อมูลที่จำเป็นตามตัวอย่าง API response
      'sourcing': 'true',
      'created_by': 2, // ควรดึงจาก user session - ใช้ int แทน string
      'vendor_id': 8, // ควรดึงจาก user session - ใช้ int แทน string
    };
    
    // Debug: Print the formatted data
    print('DEBUG: Formatted auction data for API:');
    print('Formatted Data: $formattedData');
    
    return formattedData;
  }
}
