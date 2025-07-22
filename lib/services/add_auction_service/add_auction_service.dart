import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:e_auction/views/config/config_prod.dart';

class AddAuctionService {
  // Base URL for API - using config
  static String get baseUrl {
    final url = '${Config.apiUrllocal}/ERP-Cloudmate/modules/sales/controllers';

    return url;
  }

  // Load Quotation Types
  static Future<List<Map<String, dynamic>>> loadQuotationTypes() async {
    try {
      final url = '$baseUrl/quotation_type_controller.php';

      final response = await http.get(
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

        // Filter only auction types (starting with 'A')
        final auctionTypes = data.where((item) {
          final code = item['quotation_type_code']?.toString() ?? '';
          return code.startsWith('A');
        }).map((item) {
          return {
            'id': item['quotation_type_id']?.toString() ?? '',
            'name': item['description']?.toString() ??
                '', // ใช้ description เป็นชื่อ
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
    }
  }

  // Save Auction
  static Future<Map<String, dynamic>> saveAuction({
    required Map<String, dynamic> auctionData,
  }) async {
    try {
      final url = '$baseUrl/add_auction_controller.php';

      final response = await http
          .post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(auctionData),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout after 30 seconds');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);

        return result;
      } else {
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

  // Upload Image (if needed)
  static Future<String?> uploadImage(String imagePath) async {
    try {
      // TODO: Implement image upload if needed
      // This would typically involve multipart/form-data
      return imagePath;
    } catch (e) {
      throw Exception('Error uploading image: $e');
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

    if (data['starting_price'] == null ||
        (data['starting_price'] as num) <= 0) {
      errors['starting_price'] = 'กรุณากรอกราคาเริ่มต้น';
    }

    if (data['start_date']?.toString().isEmpty ?? true) {
      errors['start_date'] = 'กรุณาเลือกวันที่เริ่มต้น';
    }

    if (data['end_date']?.toString().isEmpty ?? true) {
      errors['end_date'] = 'กรุณาเลือกวันที่สิ้นสุด';
    }

    if (data['seller_name']?.toString().isEmpty ?? true) {
      errors['seller_name'] = 'กรุณากรอกชื่อผู้ขาย';
    }

    if (data['seller_phone']?.toString().isEmpty ?? true) {
      errors['seller_phone'] = 'กรุณากรอกเบอร์โทรศัพท์';
    }

    if (data['seller_address']?.toString().isEmpty ?? true) {
      errors['seller_address'] = 'กรุณากรอกที่อยู่';
    }

    if (data['seller_id_card']?.toString().isEmpty ?? true) {
      errors['seller_id_card'] = 'กรุณากรอกเลขบัตรประชาชน';
    }

    if (data['quotation_type_id']?.toString().isEmpty ?? true) {
      errors['quotation_type_id'] = 'กรุณาเลือกประเภทสินค้า';
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }

  // Format Auction Data for API
  static Map<String, dynamic> formatAuctionDataForAPI(
      Map<String, dynamic> data) {
    return {
      'product_name': data['product_name']?.toString() ?? '',
      'description': data['description']?.toString() ?? '',
      'notes': data['notes']?.toString() ?? '',
      'starting_price': data['starting_price']?.toString() ?? '0',
      'min_increment': data['min_increment']?.toString() ?? '100',
      'is_percentage': data['is_percentage'] ?? false,
      'percentage_value': data['percentage_value']?.toString() ?? '3.0',
      'bidder_count': data['bidder_count']?.toString() ?? '0',
      'start_date': data['start_date']?.toString() ?? '',
      'end_date': data['end_date']?.toString() ?? '',
      'quotation_type_id': data['quotation_type_id']?.toString() ?? '',
      'quotation_type_name': data['quotation_type_name']?.toString() ?? '',
      'seller_name': data['seller_name']?.toString() ?? '',
      'seller_phone': data['seller_phone']?.toString() ?? '',
      'seller_email': data['seller_email']?.toString() ?? '',
      'seller_address': data['seller_address']?.toString() ?? '',
      'seller_id_card': data['seller_id_card']?.toString() ?? '',
      'seller_company': data['seller_company']?.toString() ?? '',
      'image_path': data['image_path']?.toString() ?? '',
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}
