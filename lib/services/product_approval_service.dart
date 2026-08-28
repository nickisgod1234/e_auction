import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:e_auction/views/config/config_prod.dart';

class ProductApprovalService {
  static String get baseUrl => Config.erpWriteBaseUrl;
  late http.Client _client;

  ProductApprovalService() {
    _client = _createHttpClient();
  }

  // ใช้ baseUrl จาก Config
  ProductApprovalService.defaultInstance() {
    _client = _createHttpClient();
  }

  http.Client _createHttpClient() {
    if (Platform.isAndroid) {
      // สำหรับ Android ให้ bypass SSL verification
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true; // ยอมรับ certificate ทั้งหมด
      };
      return IOClient(client);
    } else {
      // สำหรับ iOS และ platform อื่นๆ ใช้ default
      return http.Client();
    }
  }

  // แปลง HTTPS เป็น HTTP สำหรับ Android
  String _getBaseUrl() {
    if (Platform.isAndroid) {
      return baseUrl.replaceFirst('https://', 'http://');
    }
    return baseUrl;
  }

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ดึงรายการสินค้าที่รออนุมัติ
  Future<ProductApprovalResponse> getPendingProducts({
    String? status,
    String? type,
    String? date,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (date != null && date.isNotEmpty) queryParams['date'] = date;

      final uri = Uri.parse(
              '${_getBaseUrl()}/modules/sales/controllers/flutter_quotation_approval_controller.php')
          .replace(queryParameters: queryParams);

      // print('ProductApprovalService.getPendingProducts URL: $uri');

      final response = await _client.get(uri, headers: _headers);

      // print(
      //     'ProductApprovalService.getPendingProducts Response: ${response.statusCode}');
      // print('ProductApprovalService.getPendingProducts Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // print('ProductApprovalService.getPendingProducts Raw Data: $data');
        return ProductApprovalResponse.fromJson(data);
      } else {
        // print(
        //     'ProductApprovalService.getPendingProducts Error Status: ${response.statusCode}');
        // print(
        //     'ProductApprovalService.getPendingProducts Error Body: ${response.body}');
        return ProductApprovalResponse(
          status: 'error',
          message: 'เกิดข้อผิดพลาดในการดึงข้อมูล',
          data: [],
        );
      }
    } catch (e) {
      return ProductApprovalResponse(
        status: 'error',
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e',
        data: [],
      );
    }
  }

  // ดึงรายละเอียดสินค้า
  Future<ProductApprovalResponse> getProductDetail(int quotationId) async {
    try {
      final uri = Uri.parse(
              '${_getBaseUrl()}/modules/sales/controllers/flutter_quotation_approval_controller.php')
          .replace(queryParameters: {'id': quotationId.toString()});

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProductApprovalResponse.fromJson(data);
      } else {
        return ProductApprovalResponse(
          status: 'error',
          message: 'เกิดข้อผิดพลาดในการดึงข้อมูล',
          data: [],
        );
      }
    } catch (e) {
      return ProductApprovalResponse(
        status: 'error',
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e',
        data: [],
      );
    }
  }

  // อนุมัติสินค้า
  Future<ProductApprovalResponse> approveProduct({
    required int quotationId,
    required String status, // 'approved' หรือ 'rejected'
    String? comment,
  }) async {
    try {
      final requestData = {
        'quotation_id': quotationId,
        'status': status,
        'comment': comment ??
            (status == 'approved' ? 'อนุมัติโดย admin' : 'ปฏิเสธโดย admin'),
      };

      final uri = Uri.parse(
          '${_getBaseUrl()}/modules/sales/controllers/flutter_quotation_approval_controller.php');

      print('ProductApprovalService.approveProduct URL: $uri');
      print(
          'ProductApprovalService.approveProduct Body: ${jsonEncode(requestData)}');

      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode(requestData),
      );

      print(
          'ProductApprovalService.approveProduct Response: ${response.statusCode}');
      print('ProductApprovalService.approveProduct Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProductApprovalResponse.fromJson(data);
      } else {
        return ProductApprovalResponse(
          status: 'error',
          message: 'เกิดข้อผิดพลาดในการอนุมัติ',
          data: [],
        );
      }
    } catch (e) {
      return ProductApprovalResponse(
        status: 'error',
        message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e',
        data: [],
      );
    }
  }

  // ส่งสินค้าเข้า ERP (รายการรออนุมัติใน ERP)
  Future<SimpleApiResponse> submitItemsToErp({
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final cleanedItems = items
          .map(_removeEmptyValues)
          .where((item) => item.isNotEmpty)
          .toList();

      if (cleanedItems.isEmpty) {
        return SimpleApiResponse(
          success: false,
          message: 'ไม่มีข้อมูลสินค้าที่ส่งเข้า ERP',
        );
      }

      final candidates = _getErpSubmitUris();
      final body = jsonEncode({'items': cleanedItems});

      String lastError = '';
      for (final uri in candidates) {
        final response = await _client.post(
          uri,
          headers: _headers,
          body: body,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final status = data['status']?.toString().toLowerCase();
          final message = data['message']?.toString() ?? '';
          final errorCount = int.tryParse(data['error_count']?.toString() ?? '0') ?? 0;
          final normalizedMessage = message.toLowerCase();
          final hasSuccessMessage = normalizedMessage.contains('completed') ||
              normalizedMessage.contains('sync completed') ||
              normalizedMessage.contains('success');
          final success = errorCount == 0 &&
              (status == 'success' || status == 'ok' || hasSuccessMessage);
          return SimpleApiResponse(
            success: success,
            message: message.isNotEmpty
                ? message
                : data['message']?.toString() ??
                (success
                    ? 'ส่งข้อมูลเข้า ERP สำเร็จ'
                    : 'ส่งข้อมูลเข้า ERP ไม่สำเร็จ (URL: $uri)'),
          );
        }

        final shortBody = response.body.length > 240
            ? '${response.body.substring(0, 240)}...'
            : response.body;
        lastError =
            'HTTP ${response.statusCode} | URL: $uri | BODY: $shortBody';
      }

      return SimpleApiResponse(
        success: false,
        message: 'ส่งข้อมูลเข้า ERP ไม่สำเร็จ: $lastError',
      );
    } catch (e) {
      return SimpleApiResponse(
        success: false,
        message: 'เกิดข้อผิดพลาดในการส่งเข้า ERP: $e',
      );
    }
  }

  Map<String, dynamic> _removeEmptyValues(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    input.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is List && value.isEmpty) return;
      result[key] = value;
    });
    return result;
  }

  List<Uri> _getErpSubmitUris() {
    final base = _getBaseUrl(); // server base

    final alternateHost =
        Config.apiUrlAuction.contains('www.')
            ? Config.apiUrlAuction.replaceFirst('www.', '')
            : Config.apiUrlAuction.replaceFirst('://', '://www.');
    final altBase = Platform.isAndroid
        ? alternateHost.replaceFirst('https://', 'http://')
        : alternateHost;

    // ลองหลาย path เพราะ server บางชุดตั้ง route ไม่เหมือนกัน
    const candidatePaths = [
      '/modules/procurements/controllers/material_master_controller.php',
      '/modules/procurement/controllers/material_master_controller.php',
      '/modules/procurements/material_master_controller.php',
      '/modules/procurement/material_master_controller.php',
    ];

    // ใช้สำหรับ dev บนเครื่อง local เท่านั้น
    // final localBase = 'http://localhost/${Config.erpCloudmate}';

    final uris = <Uri>[];
    for (final path in candidatePaths) {
      // uris.add(Uri.parse('$localBase$path'));
      uris.add(Uri.parse('$base$path'));
      uris.add(Uri.parse('$altBase/${Config.erpPrd}$path'));
    }
    return uris.toSet().toList();
  }
}

class ProductApprovalResponse {
  final String status;
  final String message;
  final List<ProductQuotation> data;

  ProductApprovalResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ProductApprovalResponse.fromJson(Map<String, dynamic> json) {
    print('ProductApprovalResponse.fromJson Input: $json');

    List<ProductQuotation> quotations = [];

    if (json['data'] != null) {
      print(
          'ProductApprovalResponse.fromJson Data type: ${json['data'].runtimeType}');
      print('ProductApprovalResponse.fromJson Data content: ${json['data']}');

      if (json['data'] is List) {
        quotations = (json['data'] as List).map((item) {
          print('ProductApprovalResponse.fromJson Processing item: $item');
          return ProductQuotation.fromJson(item);
        }).toList();
      } else if (json['data'] is Map) {
        quotations = [ProductQuotation.fromJson(json['data'])];
      }
    }

    print(
        'ProductApprovalResponse.fromJson Final quotations count: ${quotations.length}');

    return ProductApprovalResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? 'ไม่ระบุข้อความ',
      data: quotations,
    );
  }
}

class ProductQuotation {
  final int quotationId;
  final String? sequence;
  final String? description;
  final String? additionalNotes;
  final String? itemNote; // Add itemNote field
  final String? typeDescription;
  final String? phone;
  final double? starPrice;
  final double? minimumIncrease;
  final String? auctionStartDate;
  final String? auctionEndDate;
  final int? status;
  final String? createdAt;
  final String? quotationImage;
  final List<QuotationMessage>? messages;

  ProductQuotation({
    required this.quotationId,
    this.sequence,
    this.description,
    this.additionalNotes,
    this.itemNote,
    this.typeDescription,
    this.phone,
    this.starPrice,
    this.minimumIncrease,
    this.auctionStartDate,
    this.auctionEndDate,
    this.status,
    this.createdAt,
    this.quotationImage,
    this.messages,
  });

  factory ProductQuotation.fromJson(Map<String, dynamic> json) {

    List<QuotationMessage>? messages;
    if (json['messages'] != null) {
      messages = (json['messages'] as List)
          .map((msg) => QuotationMessage.fromJson(msg))
          .toList();
    }

    // Safe type conversion
    int quotationId = 0;
    if (json['quotation_id'] != null) {
      if (json['quotation_id'] is int) {
        quotationId = json['quotation_id'];
      } else if (json['quotation_id'] is String) {
        quotationId = int.tryParse(json['quotation_id']) ?? 0;
      }
    }

    double? starPrice;
    if (json['star_price'] != null) {
      if (json['star_price'] is double) {
        starPrice = json['star_price'];
      } else if (json['star_price'] is int) {
        starPrice = json['star_price'].toDouble();
      } else if (json['star_price'] is String) {
        starPrice = double.tryParse(json['star_price']);
      }
    }

    double? minimumIncrease;
    if (json['minimum_increase'] != null) {
      if (json['minimum_increase'] is double) {
        minimumIncrease = json['minimum_increase'];
      } else if (json['minimum_increase'] is int) {
        minimumIncrease = json['minimum_increase'].toDouble();
      } else if (json['minimum_increase'] is String) {
        minimumIncrease = double.tryParse(json['minimum_increase']);
      }
    }

    int? status;
    if (json['status'] != null) {
      if (json['status'] is int) {
        status = json['status'];
      } else if (json['status'] is String) {
        status = int.tryParse(json['status']);
      }
    }

    return ProductQuotation(
      quotationId: quotationId,
      sequence: json['sequence']?.toString(),
      description: json['description']?.toString(),
      additionalNotes: json['additional_notes']?.toString(),
      itemNote: json['item_note']?.toString(),
      typeDescription: json['type_description']?.toString(),
      phone: json['phone']?.toString(),
      starPrice: starPrice,
      minimumIncrease: minimumIncrease,
      auctionStartDate: json['auction_start_date']?.toString(),
      auctionEndDate: json['auction_end_date']?.toString(),
      status: status,
      createdAt: json['created_at']?.toString(),
      quotationImage: json['quotation_image']?.toString(),
      messages: messages,
    );
  }

  // Helper methods
  String get statusText {
    switch (status) {
      case 0:
      case null:
        return 'รออนุมัติ';
      case 1:
        return 'อนุมัติแล้ว';
      case 2:
        return 'ปฏิเสธ';
      default:
        return 'รออนุมัติ';
    }
  }

  String get statusColor {
    switch (status) {
      case 0:
      case null:
        return 'orange';
      case 1:
        return 'green';
      case 2:
        return 'red';
      default:
        return 'orange';
    }
  }

  bool get canApprove => status == 0 || status == null;

  String get formattedPhone {
    if (phone == null || phone!.trim().isEmpty) return '-';

    String phoneNumber = phone!.trim();
    if (phoneNumber.length == 9 && !phoneNumber.startsWith('0')) {
      phoneNumber = '0$phoneNumber';
    }
    return phoneNumber;
  }

  String get formattedPrice {
    if (starPrice == null) return '-';
    return '฿${starPrice!.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  String get formattedMinIncrement {
    if (minimumIncrease == null) return '-';
    return '฿${minimumIncrease!.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  List<String> get imageUrls {
    if (quotationImage == null || quotationImage!.isEmpty) {
      return [];
    }

    try {
      String imageData = quotationImage!;

      // ลบ quotes และ escape characters ที่ไม่จำเป็น
      imageData = imageData.trim();

      // ลอง parse JSON เพื่อจัดการกับ double encoding
      try {
        imageData = jsonDecode(imageData);
      } catch (e) {
        // ถ้า parse ไม่ได้ก็ใช้ค่าเดิม
      }

      // ตรวจสอบว่า imageData เป็น List หรือไม่
      if (imageData is List) {
        final urls = (imageData as List).map((img) {
          // ใช้ baseUrl จาก Config
          String baseUrl =
              '${Config.apiUrlAuction}/${Config.erpPrd}/modules/sales/uploads/quotation/$img';
          return baseUrl;
        }).toList();

        return urls;
      } else {
        // ถ้าไม่ใช่ List ให้ลอง parse อีกครั้ง
        try {
          final parsed = jsonDecode(imageData);
          if (parsed is List) {
            final urls = parsed.map((img) {
              String baseUrl =
                  '${Config.apiUrlAuction}/${Config.erpPrd}/modules/sales/uploads/quotation/$img';
              return baseUrl;
            }).toList();

            return urls;
          }
        } catch (e) {
          // Ignore parse errors
        }
      }
    } catch (e) {
      print('Error parsing image data: $e');
    }

    print('ProductQuotation.imageUrls - Returning empty list');
    return [];
  }
}

class QuotationMessage {
  final String? quotationMessage;

  QuotationMessage({this.quotationMessage});

  factory QuotationMessage.fromJson(Map<String, dynamic> json) {
    return QuotationMessage(
      quotationMessage: json['quotation_message'],
    );
  }
}

class SimpleApiResponse {
  final bool success;
  final String message;

  SimpleApiResponse({
    required this.success,
    required this.message,
  });
}
