import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:e_auction/views/config/config_prod.dart';

class CustomerStatsService {
  // เปลี่ยนมาใช้ baseUrl แบบ static ตามที่ขอ
  // static String get baseUrl => '${Config.apiUrlotplocalauction}api/chat';
  static String get baseUrl => '${Config.apiUrlotpsever}api/chat';

  late http.Client _client;

  CustomerStatsService() {
    _client = _createHttpClient();
  }

  factory CustomerStatsService.defaultInstance() {
    return CustomerStatsService();
  }

  http.Client _createHttpClient() {
    if (Platform.isAndroid) {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true; // ยอมรับ certificate ทั้งหมด
      };
      return IOClient(client);
    } else {
      return http.Client();
    }
  }

  String _getBaseUrl() {
    // ใช้ static baseUrl โดยตรง
    return baseUrl;
  }

  // แก้ headers ตามที่ขอ (มี charset)
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  Future<CustomerStatsResponse> getCustomerStats() async {
    try {
      final url = '${_getBaseUrl()}/customer_stats.php';
      print('CustomerStatsService.getCustomerStats URL: $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: _headers,
      );

      print('CustomerStatsService.getCustomerStats Response: ${response.statusCode}');
      print('CustomerStatsService.getCustomerStats Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CustomerStatsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load customer stats: ${response.statusCode}');
      }
    } catch (e) {
      print('CustomerStatsService.getCustomerStats Error: $e');
      throw Exception('Error loading customer stats: $e');
    }
  }
}

class CustomerStatsResponse {
  final bool success;
  final String message;
  final CustomerStatsData? data;

  CustomerStatsResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CustomerStatsResponse.fromJson(Map<String, dynamic> json) {
    return CustomerStatsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? CustomerStatsData.fromJson(json['data']) : null,
    );
  }
}

class CustomerStatsData {
  final int total;
  final int today;
  final int thisWeek;
  final int thisMonth;
  final List<DailyStats> daily;
  final List<RecentCustomer> recent;
  final String lastUpdated;

  CustomerStatsData({
    required this.total,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.daily,
    required this.recent,
    required this.lastUpdated,
  });

  factory CustomerStatsData.fromJson(Map<String, dynamic> json) {
    return CustomerStatsData(
      total: json['total'] ?? 0,
      today: json['today'] ?? 0,
      thisWeek: json['this_week'] ?? 0,
      thisMonth: json['this_month'] ?? 0,
      daily: (json['daily'] as List?)
          ?.map((item) => DailyStats.fromJson(item))
          .toList() ?? [],
      recent: (json['recent'] as List?)
          ?.map((item) => RecentCustomer.fromJson(item))
          .toList() ?? [],
      lastUpdated: json['last_updated'] ?? '',
    );
  }
}

class DailyStats {
  final String date;
  final int count;

  DailyStats({
    required this.date,
    required this.count,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class RecentCustomer {
  final int id;
  final String? name;
  final String? email;
  final String phone;
  final String? type;
  final String createdAt;

  RecentCustomer({
    required this.id,
    this.name,
    this.email,
    required this.phone,
    this.type,
    required this.createdAt,
  });

  factory RecentCustomer.fromJson(Map<String, dynamic> json) {
    return RecentCustomer(
      id: json['id'] ?? 0,
      name: json['name'],
      email: json['email'],
      phone: json['phone'] ?? '',
      type: json['type'],
      createdAt: json['created_at'] ?? '',
    );
  }

  String get formattedPhone {
    if (phone.startsWith('0')) {
      return phone;
    }
    return '0$phone';
  }

  String get formattedDate {
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return createdAt;
    }
  }
}
