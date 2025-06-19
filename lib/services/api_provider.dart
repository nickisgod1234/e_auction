import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiProvider {
  // static const String baseApiUrl = 'http://localhost/ERP-Cloudmate/modules/tools/api/controllers/';
  static const String baseApiUrl = 'https://cm-mecustomers.com/morket/modules/tools/api/controllers/';
  static const String defaultSystemType = 'raot_app';

  // เพิ่มรหัสสำหรับเทส
  static const List<String> testCodes = ['TEST01', 'DEV123', 'RA0004'];

  Future<String> getApiUrl() async {
    try {
      final response = await http.get(
        Uri.parse('${baseApiUrl}system_apis_controller.php?system_type=supplier_app&system_api_key=SP0004'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['system_api_url'];
      } else {
        throw Exception('Failed to get API URL');
      }
    } catch (e) {
      print('Error getting API URL: $e');
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<bool> verifyAppCode(String appCode) async {
    try {
      // เช็คก่อนว่าเป็นรหัสเทสหรือไม่
      if (testCodes.contains(appCode)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('system_api_key', appCode);
        await prefs.setString('system_api_url', 'https://cm-mecustomers.com/');
        
        print('\nTest code accepted:');
        print('Saved API Key: $appCode');
        print('Saved API URL: https://cm-mecustomers.com/');
        return true;
      }

      // สำหรับ raot_app ไม่ต้องเช็ค API key ให้ผ่านเลย
      if (defaultSystemType == 'raot_app') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('system_api_key', appCode);
        await prefs.setString('system_api_url', 'https://cm-mecustomers.com/');
        
        print('\nRaot app - no API key verification required:');
        print('Saved API Key: $appCode');
        print('Saved API URL: https://cm-mecustomers.com/');
        return true;
      }

      // ถ้าไม่ใช่รหัสเทสและไม่ใช่ raot_app ให้เรียก API ตามปกติ
      final response = await http.get(
        Uri.parse('${baseApiUrl}system_apis_controller.php?system_type=$defaultSystemType&system_api_key=$appCode'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response Data:');
        print('system_api_key: ${data['system_api_key']}');
        print('system_api_url: ${data['system_api_url']}');
        print('system_type: ${data['system_type']}');
        
        if (data['system_api_key'] == appCode) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('system_api_key', appCode);
          await prefs.setString('system_api_url', data['system_api_url']);
          
          print('\nSaved to SharedPreferences:');
          print('Saved API Key: $appCode');
          print('Saved API URL: ${data['system_api_url']}');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error verifying app code: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String otp) async {
    try {
      final apiUrl = await getApiUrl();
      final response = await http.post(
        Uri.parse('${apiUrl}api/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to verify OTP');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // เพิ่มเมธอดสำหรับเปลี่ยน API Key
  Future<bool> changeApiKey(String newApiKey) async {
    try {
      final response = await http.get(
        Uri.parse('${baseApiUrl}system_apis_controller.php?system_type=$defaultSystemType&system_api_key=$newApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['system_api_key'] == newApiKey) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('system_api_key', newApiKey);
          await prefs.setString('system_api_url', data['system_api_url']);
          
          print('Changed API Key to: $newApiKey');
          print('Changed API URL to: ${data['system_api_url']}');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error changing API key: $e');
      return false;
    }
  }

  // เพิ่มเมธอดสำหรับล้างข้อมูล API Key
  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('system_api_key');
    await prefs.remove('system_api_url');
    print('Cleared API Key and URL from SharedPreferences');
  }
} 