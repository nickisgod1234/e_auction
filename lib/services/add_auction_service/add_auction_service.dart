import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/views/config/config_prod.dart';

class AddAuctionService {
  // Base URL for API - using config
  static String get baseUrl {
    return '${Config.erpWriteBaseUrl}/modules/sales/controllers';
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

        // Filter only auction types (starting with 'A')
        final auctionTypes = data.where((item) {
          final code = item['quotation_type_code']?.toString() ?? '';
          return code.startsWith('A');
        }).map((item) {
          final code = item['quotation_type_code']?.toString() ?? '';
          String customName = item['description']?.toString() ?? '';
          
          // Override names for specific types
          switch (code) {
            case 'AS01':
              customName = 'ประมูลแบบทั่วไป(ได้ราคาสูงสุดเป็นผู้ชนะ)';
              break;
            case 'AS02':
              customName = 'ประมูลแบบราคาลดลง(ได้ราคาต่ำสุดเป็นผู้ชนะ)';
              break;
            case 'AS03':
              customName = 'ประมูลแบบลดตามจำนวนของสินค้า';
              break;
          }
          
          return {
            'id': item['quotation_type_id']?.toString() ?? '',
            'name': customName,
            'description': customName,
            'code': code,
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
  // API Documentation: See docs/API_DOCUMENTATION.md
  // Endpoint: POST /quotation_controller.php?action=create_flutter_auction
  static Future<Map<String, dynamic>> saveAuction({
    required Map<String, dynamic> auctionData,
    List<File> imageFiles = const [],
  }) async {
    try {
      // Validate image count (max 5 images according to API)
      const maxImages = 5;
      if (imageFiles.length > maxImages) {
        throw Exception(
            'Cannot upload more than $maxImages images. You tried to upload ${imageFiles.length} images.');
      }

      final url = '$baseUrl/quotation_controller.php?action=create_flutter_auction';

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add data as JSON string (required by API)
      // API expects: request.fields['data'] = jsonEncode(auctionData)
      final dataJson = jsonEncode(auctionData);
      request.fields['data'] = dataJson;
      
      // Debug: Print the data being sent
      print('DEBUG: Sending auction data to API:');
      print('URL: $url');
      print('Data: $dataJson');
      print('Data length: ${dataJson.length}');
      print('Images count: ${imageFiles.length}');
      
      // Check if max_quantity_available is in the data
      try {
        final decodedData = jsonDecode(dataJson);
        if (decodedData is Map) {
          print('DEBUG: Checking max_quantity_available in JSON:');
          print('Has max_quantity_available: ${decodedData.containsKey('max_quantity_available')}');
          if (decodedData.containsKey('max_quantity_available')) {
            print('max_quantity_available value: ${decodedData['max_quantity_available']}');
            print('max_quantity_available type: ${decodedData['max_quantity_available'].runtimeType}');
          } else {
            print('ERROR: max_quantity_available is NOT in the JSON data!');
            print('Available keys: ${decodedData.keys.toList()}');
          }
        }
      } catch (e) {
        print('DEBUG: Error checking JSON data: $e');
      }
      
      // For AS03, also add max_quantity_available as a separate field (in case API needs it)
      // This is in addition to the JSON data
      try {
        final decodedData = jsonDecode(dataJson);
        if (decodedData is Map && decodedData.containsKey('max_quantity_available')) {
          final maxQty = decodedData['max_quantity_available'];
          if (maxQty != null) {
            final qty = maxQty is int ? maxQty : (int.tryParse(maxQty.toString()) ?? 0);
            request.fields['max_quantity_available'] = qty.toString();
            print('DEBUG: Also added max_quantity_available as separate form field: $qty');
          }
        }
      } catch (e) {
        print('DEBUG: Error adding max_quantity_available as separate field: $e');
      }

      // Add images if provided
      // API expects: images[] field name (with brackets for array)
      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        if (await imageFile.exists()) {
          final imageStream = http.ByteStream(imageFile.openRead());
          final imageLength = await imageFile.length();
          
          final multipartFile = http.MultipartFile(
            'images[]', // Use array notation - PHP will receive as $_FILES['images']
            imageStream,
            imageLength,
            filename: imageFile.path.split('/').last,
          );
          
          request.files.add(multipartFile);
        }
      }
      
      // Debug: Print number of images
      print('DEBUG: Sending ${imageFiles.length} image(s) with field name images[]');

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60), // เพิ่ม timeout สำหรับการอัปโหลดรูป
        onTimeout: () {
          throw TimeoutException('Request timeout after 60 seconds');
        },
      );

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      // API returns 201 on success, 200 is also acceptable
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final Map<String, dynamic> result = jsonDecode(response.body);
          
          // Debug: Print the response
          print('DEBUG: API Response:');
          print('Status Code: ${response.statusCode}');
          print('Response Body: ${response.body}');
          print('Parsed Result: $result');
          
          // Check if response has error status
          if (result['status'] == 'error') {
            final errorMessage = result['message'] ?? 'Unknown error';
            throw Exception('API Error: $errorMessage');
          }
          
          return result;
        } catch (e) {
          if (e is FormatException) {
            throw Exception('Invalid JSON response from server: ${response.body}');
          }
          rethrow;
        }
      } else {
        // Try to parse error response
        String errorMessage = 'Failed to save auction (${response.statusCode})';
        try {
          final errorResponse = jsonDecode(response.body);
          if (errorResponse is Map && errorResponse['message'] != null) {
            errorMessage = errorResponse['message'].toString();
          } else {
            errorMessage = response.body;
          }
        } catch (e) {
          errorMessage = response.body;
        }
        
        print('DEBUG: API Error Response:');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        
        throw Exception(errorMessage);
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
    final isAS03 = data['quotation_type_code']?.toString() == 'AS03';

    // Required fields validation
    if (data['product_name']?.toString().isEmpty ?? true) {
      errors['product_name'] = 'กรุณากรอกชื่อสินค้า';
    }

    if (data['description']?.toString().isEmpty ?? true) {
      errors['description'] = 'กรุณากรอกรายละเอียดสินค้า';
    }

    // Fix starting_price validation (for AS03, this is bulk price)
    final startingPrice = data['starting_price'];
    if (startingPrice == null) {
      errors['starting_price'] = isAS03 
          ? 'กรุณากรอกราคาเหมา' 
          : 'กรุณากรอกราคาเริ่มต้น';
    } else {
      try {
        final price = double.tryParse(startingPrice.toString());
        if (price == null || price <= 0) {
          errors['starting_price'] = isAS03 
              ? 'กรุณากรอกราคาเหมา' 
              : 'กรุณากรอกราคาเริ่มต้น';
        }
      } catch (e) {
        errors['starting_price'] = isAS03 
            ? 'กรุณากรอกราคาเหมา' 
            : 'กรุณากรอกราคาเริ่มต้น';
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

    // For AS03, validate quantity fields instead of min_increment
    if (isAS03) {
      // Validate max_quantity_available (จำนวนสินค้าทั้งหมด - ส่งไป API)
      final maxQuantityAvailable = data['max_quantity_available'];
      if (maxQuantityAvailable == null || maxQuantityAvailable.toString().isEmpty) {
        errors['max_quantity_available'] = 'กรุณากรอกจำนวนสินค้าทั้งหมด';
      } else {
        try {
          final qty = int.tryParse(maxQuantityAvailable.toString());
          if (qty == null || qty <= 0) {
            errors['max_quantity_available'] = 'กรุณากรอกจำนวนสินค้าที่ถูกต้อง';
          }
        } catch (e) {
          errors['max_quantity_available'] = 'กรุณากรอกจำนวนสินค้าที่ถูกต้อง';
        }
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }

  // Format Auction Data for new API
  static Future<Map<String, dynamic>> formatAuctionDataForAPI(
      Map<String, dynamic> data) async {
    // Check if this is AS03 (bulk sale)
    // Try to get quotation_type_code from data, or check if max_quantity_available exists (indicates AS03)
    String? quotationTypeCode = data['quotation_type_code']?.toString();
    
    // If quotation_type_code is null but max_quantity_available exists, it's likely AS03
    if (quotationTypeCode == null && data.containsKey('max_quantity_available')) {
      quotationTypeCode = 'AS03';
      print('DEBUG: formatAuctionDataForAPI - quotation_type_code was null, but max_quantity_available exists, assuming AS03');
    }
    
    final isAS03 = quotationTypeCode == 'AS03';
    
    // Debug: Check quotation type
    print('DEBUG: formatAuctionDataForAPI - quotation_type_code: $quotationTypeCode, isAS03: $isAS03');
    print('DEBUG: formatAuctionDataForAPI - data keys: ${data.keys.toList()}');
    print('DEBUG: formatAuctionDataForAPI - has max_quantity_available: ${data.containsKey('max_quantity_available')}');
    
    // Convert prices to integers (API expects int, not string)
    final startingPrice = data['starting_price'];
    final minIncrement = data['min_increment'];
    
    int startingPriceInt = 0;
    int minIncrementInt = 100;
    
    if (startingPrice != null) {
      try {
        final price = double.tryParse(startingPrice.toString());
        startingPriceInt = price?.toInt() ?? 0;
      } catch (e) {
        startingPriceInt = 0;
      }
    }
    
    // For AS03, set min_increment to 1 (API requires > 0)
    // For other types, use the provided min_increment or default to 100
    if (isAS03) {
      minIncrementInt = 1; // API requires min_increment > 0 even for bulk sales
    } else if (minIncrement != null) {
      try {
        final increment = double.tryParse(minIncrement.toString());
        if (increment != null && increment > 0) {
          minIncrementInt = increment.toInt();
        } else {
          minIncrementInt = 100; // Default if invalid
        }
      } catch (e) {
        minIncrementInt = 100;
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
      'starting_price': startingPriceInt, // Send as int (not string)
      'min_increment': minIncrementInt, // Send as int (not string)
      'start_date': data['start_date']?.toString() ?? '',
      'end_date': data['end_date']?.toString() ?? '',
      'purchase_order_type_id': data['purchase_order_type_id']?.toString() ?? '',
      // ลบ seller_name และ seller_phone ออกเพราะไม่ใช้แล้ว
      // เพิ่มข้อมูลที่จำเป็นตามตัวอย่าง API response
      'sourcing': true, // ใช้ boolean แทน string 'true'
      'created_by': 2, // ควรดึงจาก user session - ใช้ int แทน string
      'vendor_id': 8, // ควรดึงจาก user session - ใช้ int แทน string
      // เก็บ quotation_type_code ไว้เพื่อใช้ในการตรวจสอบในครั้งต่อไป
      'quotation_type_code': quotationTypeCode ?? data['quotation_type_code']?.toString(),
    };
    
    // Add quantity data for AS03 (use max_quantity_available for API)
    // IMPORTANT: Always add max_quantity_available for AS03, even if 0
    // Also check if max_quantity_available already exists in data (from previous format call)
    if (isAS03 || data.containsKey('max_quantity_available')) {
      final maxQuantityAvailable = data['max_quantity_available'];
      print('DEBUG: AS03 detected (isAS03: $isAS03) or max_quantity_available exists - value: $maxQuantityAvailable (type: ${maxQuantityAvailable.runtimeType})');
      
      // Convert to int (API expects int, not string)
      int qty = 0;
      if (maxQuantityAvailable != null) {
        if (maxQuantityAvailable is int) {
          qty = maxQuantityAvailable;
        } else if (maxQuantityAvailable is String) {
          qty = int.tryParse(maxQuantityAvailable.trim()) ?? 0;
        } else {
          qty = int.tryParse(maxQuantityAvailable.toString().trim()) ?? 0;
        }
      }
      
      // Always add max_quantity_available for AS03 (even if 0)
      formattedData['max_quantity_available'] = qty;
      print('DEBUG: Added max_quantity_available to formattedData: $qty (type: ${qty.runtimeType})');
    } else {
      print('DEBUG: Not AS03 - isAS03: $isAS03, quotation_type_code: $quotationTypeCode, has max_quantity_available: ${data.containsKey('max_quantity_available')}');
    }
    
    // Debug: Print the formatted data
    print('DEBUG: Formatted auction data for API:');
    print('Formatted Data: $formattedData');
    print('Is AS03: $isAS03');
    print('Quotation Type Code: $quotationTypeCode');
    if (isAS03) {
      print('Max Quantity Available: ${formattedData['max_quantity_available']}');
      print('Max Quantity Available Type: ${formattedData['max_quantity_available'].runtimeType}');
      if (!formattedData.containsKey('max_quantity_available')) {
        print('ERROR: max_quantity_available is missing from formattedData!');
      }
    } else {
      print('WARNING: Not AS03, max_quantity_available will not be added');
    }
    
    return formattedData;
  }

  // Get user's previous auctions (for relisting)
  static Future<List<Map<String, dynamic>>> getUserPreviousAuctions() async {
    http.Client? client;
    try {
      // Get customer_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('id') ?? '';
      
      if (userIdStr.isEmpty) {
        return [];
      }

      final customerId = int.tryParse(userIdStr) ?? 0;
      if (customerId == 0) {
        return [];
      }

      // Use ProductService to get all quotations
      // Note: We'll filter by customer_id on the client side since API might not support it
      final url = Uri.parse(
          '${Config.erpWriteBaseUrl}/modules/sales/controllers/list_quotation_type_auction_price_controller.php');
      
      client = _createHttpClient();
      
      final response = await client.get(
        url,
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
        
        // Filter auctions by customer_id and only completed/ended auctions
        final now = DateTime.now();
        final userAuctions = data.where((item) {
          final itemCustomerId = item['customer_id']?.toString() ?? '';
          final endDateStr = item['auction_end_date']?.toString() ?? '';
          
          // Check if this auction belongs to the user
          if (itemCustomerId != userIdStr) {
            return false;
          }
          
          // Only include completed auctions (ended)
          if (endDateStr.isNotEmpty) {
            try {
              final endDate = DateTime.parse(endDateStr);
              return now.isAfter(endDate);
            } catch (e) {
              return false;
            }
          }
          
          return false;
        }).map((item) {
          return {
            'id': item['quotation_more_information_id']?.toString() ?? item['quotation_id']?.toString() ?? '',
            'quotation_id': item['quotation_id']?.toString() ?? '',
            'quotation_more_information_id': item['quotation_more_information_id']?.toString() ?? '',
            'product_name': item['short_text']?.toString() ?? item['description']?.toString() ?? '',
            'description': item['description']?.toString() ?? item['quotation_description']?.toString() ?? '',
            'notes': item['item_note']?.toString() ?? '',
            'starting_price': item['star_price']?.toString() ?? '0',
            'min_increment': item['minimum_increase']?.toString() ?? '0',
            'start_date': item['auction_start_date']?.toString() ?? '',
            'end_date': item['auction_end_date']?.toString() ?? '',
            'purchase_order_type_id': item['quotation_type_id']?.toString() ?? '',
            'quotation_type_code': item['quotation_type_code']?.toString() ?? '',
            'quotation_type_name': item['quotation_type_description']?.toString() ?? '',
            'image_url': item['quotation_image']?.toString() ?? '',
            'quantity': item['quantity']?.toString() ?? '1',
          };
        }).toList();

        return userAuctions.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Failed to load previous auctions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
            'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต');
      } else if (e is TimeoutException) {
        throw Exception('การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง');
      } else {
        print('Error loading previous auctions: $e');
        return [];
      }
    } finally {
      if (client != null) {
        try {
          client.close();
        } catch (closeError) {
          // Ignore close errors
        }
      }
    }
  }
}
