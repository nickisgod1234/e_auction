import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl;

  AuthService({required this.baseUrl});

  // ตรวจสอบเบอร์โทร
  Future<Map<String, dynamic>?> checkPhoneNumber(String phoneNumber) async {
    final url = Uri.parse('$baseUrl/login_phone_local/check_phone.php');
    try {
      final response = await http.post(
        url,
        body: jsonEncode({'phone_number': phoneNumber}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Response Body: ${response.body}');

        if (data['success'] && data['data']['status'] == "exists") {
          return data['data']; // ส่งคืนข้อมูลทั้งหมด
        }
      } else {
        throw Exception('Failed to check phone number');
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }

  // ส่ง OTP
  Future<String?> sendOtp(String phoneNumber) async {
    final url = Uri.parse('$baseUrl/login_phone_local/request_otp.php');
    try {
      final response = await http.post(
        url,
        body: jsonEncode({'phone_number': phoneNumber}),
        headers: {'Content-Type': 'application/json'},
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['refno']; // ดึง refno จาก API
        } else {
          throw Exception(data['message'] ?? 'Failed to send OTP');
        }
      } else {
        throw Exception('Failed to send OTP');
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

// Save User
  Future<Map<String, dynamic>?> saveUser({
    required String phoneUserId,
    String? name,
    String? birthYear,
    String? gender,
    List<String>? preferences, // เปลี่ยนจาก Map เป็น List
    String? profilePicturePath,
  }) async {
    final url = Uri.parse('$baseUrl/login_phone_local/save_user.php');

    try {
      final request = http.MultipartRequest('POST', url);

      // เพิ่มฟิลด์
      request.fields['phone_user_id'] = phoneUserId;
      if (name != null) request.fields['name'] = name;
      if (birthYear != null) request.fields['birth_year'] = birthYear;
      if (gender != null) request.fields['gender'] = gender;

      // แปลง List<String> เป็น JSON String ก่อนส่ง
      if (preferences != null) {
        request.fields['preferences'] = jsonEncode(preferences);
      }

      // เพิ่มไฟล์รูปภาพถ้ามี
      if (profilePicturePath != null && profilePicturePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            profilePicturePath,
          ),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        throw Exception('Failed to save user data');
      }
    } catch (e) {
      print('Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ยืนยัน OTP
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String pin) async {
    final url = Uri.parse('$baseUrl/login_phone_local/verify_otp.php');
    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'phone_number': phoneNumber,
          'pin': pin,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final responseBody = jsonDecode(response.body);
      print('Response Body: $responseBody');

      return responseBody;
    } catch (e) {
      print('Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
