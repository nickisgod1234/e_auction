import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl;

  AuthService({required this.baseUrl});

  // Helper function to safely convert any value to string
  String _safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  // ตรวจสอบเบอร์โทร
  Future<Map<String, dynamic>?> checkPhoneNumber(String phoneNumber) async {
    final url = Uri.parse('$baseUrl/login_phone_auction/check_phone.php');
    try {
      final response = await http.post(
        url,
        body: jsonEncode({'phone_number': phoneNumber}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Response Body: ${response.body}');

        if (data['success'] && data['data'] != null) {
          final status = data['data']['status'];
          if (status == "exists") {
            final userData = data['data'];
            final result = <String, String>{};
            result['id'] = _safeToString(userData['id']);
            result['phone_number'] = _safeToString(userData['phone_number']);
            result['name'] = _safeToString(userData['name']);
            result['profile_picture'] = _safeToString(userData['profile_picture']);
            result['type'] = _safeToString(userData['type']);
            result['email'] = _safeToString(userData['email']);
            result['password'] = _safeToString(userData['password']);
            result['address'] = _safeToString(userData['address']);
            result['status'] = status;
            result['isdelete'] = _safeToString(userData['isdelete']);
            result['created_at'] = _safeToString(userData['created_at']);
            result['updated_at'] = _safeToString(userData['updated_at']);
            result['company_id'] = _safeToString(userData['company_id']);
            result['logo'] = _safeToString(userData['logo']) != '' ? _safeToString(userData['logo']) : _safeToString(userData['profile_picture']);
            result['phone'] = _safeToString(userData['phone']) != '' ? _safeToString(userData['phone']) : _safeToString(userData['phone_number']);
            result['code'] = _safeToString(userData['code']);
            result['tax_number'] = _safeToString(userData['tax_number']);
            result['fullname'] = _safeToString(userData['fullname']) != '' ? _safeToString(userData['fullname']) : _safeToString(userData['name']);
            result['addr'] = _safeToString(userData['addr']) != '' ? _safeToString(userData['addr']) : _safeToString(userData['address']);
            result['province_id'] = _safeToString(userData['province_id']);
            result['district_id'] = _safeToString(userData['district_id']);
            result['sub_district_id'] = _safeToString(userData['sub_district_id']);
            result['sub'] = _safeToString(userData['sub']);
            result['pass'] = _safeToString(userData['pass']) != '' ? _safeToString(userData['pass']) : _safeToString(userData['password']);
            result['reset_key'] = _safeToString(userData['reset_key']);
            result['reset_key_exp'] = _safeToString(userData['reset_key_exp']);
            print('Result created successfully');
            return result;
          } else {
            // return เฉพาะ status ให้ UI handle
            return {'status': status};
          }
        }
      } else {
        throw Exception('Failed to check phone number');
      }
    } catch (e) {
      print('Error in checkPhoneNumber: $e');
      print('Error stack trace: ${StackTrace.current}');
    }
    return null;
  }

  // ส่ง OTP
  Future<Map<String, dynamic>?> sendOtp(String phoneNumber) async {
    final url = Uri.parse('$baseUrl/login_phone_auction/request_otp.php');
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
          return {
            'refno': data['refno'],
            'token': data['token'],
          };
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
    String? firstname,
    String? lastname,
    String? email,
    String? phone,
    String? address,
    String? provinceId,
    String? districtId,
    String? subDistrictId,
    String? sub,
    String? type,
    String? companyId,
    String? taxNumber,
    String? code,
    String? logoPath,
    String? action,
  }) async {
    final url = Uri.parse('$baseUrl/login_phone_auction/save_user.php');

    try {
      final request = http.MultipartRequest('POST', url);

      // เพิ่มฟิลด์ตาม API specification
      request.fields['customer_id'] = phoneUserId;
      request.fields['fullname'] = '${firstname ?? ''} ${lastname ?? ''}'.trim();
      if (firstname != null) request.fields['name'] = firstname;
      if (email != null) request.fields['email'] = email;
      if (phone != null) request.fields['phone'] = phone;
      if (address != null) request.fields['addr'] = address;
      if (provinceId != null) request.fields['province_id'] = provinceId;
      if (districtId != null) request.fields['district_id'] = districtId;
      if (subDistrictId != null) request.fields['sub_district_id'] = subDistrictId;
      if (sub != null) request.fields['sub'] = sub;
      if (type != null) request.fields['type'] = type;
      if (companyId != null) request.fields['company_id'] = companyId;
      if (taxNumber != null) {
        request.fields['tax_number'] = taxNumber;
      } else {
        request.fields['tax_number'] = '';
      }
      if (code != null) request.fields['code'] = code;
      if (action != null) request.fields['action'] = action;

      // เพิ่มไฟล์รูปภาพถ้ามี (logo field)
      if (logoPath != null && logoPath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'logo',
            logoPath,
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

  // Delete User Account
  Future<Map<String, dynamic>?> deleteUser({
    required String customerId,
    String? fullname,
    String? email,
    String? phone,
    String? address,
    String? provinceId,
    String? districtId,
    String? subDistrictId,
    String? sub,
    String? type,
    String? companyId,
    String? taxNumber,
    String? name,
    String? code,
  }) async {
    final url = Uri.parse('$baseUrl/login_phone_auction/save_user.php');

    try {
      final request = http.MultipartRequest('POST', url);

      // เพิ่มฟิลด์สำหรับ delete action
      request.fields['action'] = 'delete';
      request.fields['customer_id'] = customerId;
      if (fullname != null) request.fields['fullname'] = fullname;
      if (name != null) request.fields['name'] = name;
      if (email != null) request.fields['email'] = email;
      if (phone != null) request.fields['phone'] = phone;
      if (address != null) request.fields['addr'] = address;
      if (provinceId != null) request.fields['province_id'] = provinceId;
      if (districtId != null) request.fields['district_id'] = districtId;
      if (subDistrictId != null) request.fields['sub_district_id'] = subDistrictId;
      if (sub != null) request.fields['sub'] = sub;
      if (type != null) request.fields['type'] = type;
      if (companyId != null) request.fields['company_id'] = companyId;
      if (taxNumber != null) {
        request.fields['tax_number'] = taxNumber;
      } else {
        request.fields['tax_number'] = '';
      }
      if (code != null) request.fields['code'] = code;

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        throw Exception('Failed to delete user data');
      }
    } catch (e) {
      print('Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ยืนยัน OTP
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String pin) async {
    final url = Uri.parse('$baseUrl/login_phone_auction/verify_otp.php');
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

  // ดึงข้อมูลที่อยู่ทั้งหมด (จังหวัด อำเภอ ตำบล)
  Future<List<Map<String, dynamic>>> getAddressData() async {
    final url = Uri.parse('$baseUrl/login_phone_auction/get_address_data.php');
    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้');
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(data['message'] ?? 'ไม่สามารถโหลดข้อมูลที่อยู่ได้');
        }
      } else {
        throw Exception('HTTP ${response.statusCode} - ไม่สามารถโหลดข้อมูลที่อยู่ได้');
      }
    } catch (e) {
      print('Error fetching address data: $e');
      throw Exception('ไม่สามารถโหลดข้อมูลที่อยู่ได้: ${e.toString()}');
    }
  }

  // ดึงข้อมูลโปรไฟล์ลูกค้า
  Future<Map<String, dynamic>?> getProfile(String customerId) async {
    final url = Uri.parse('$baseUrl/login_phone_auction/get_customer_data.php?customer_id=$customerId');
    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้');
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Profile Response: ${response.body}');
        
        if (data['success']) {
          final customerData = data['data'];
          
          // สร้าง Map ใหม่ด้วยการ handle null values อย่างปลอดภัย
          final result = <String, String>{};
          
          // ใช้ field names ตามที่ API ส่งกลับมา
          result['id'] = _safeToString(customerData['id']);
          result['phone'] = _safeToString(customerData['phone']);
          result['fullname'] = _safeToString(customerData['fullname']);
          result['email'] = _safeToString(customerData['email']);
          result['profile_picture'] = _safeToString(customerData['profile_picture']);
          result['type'] = _safeToString(customerData['type']);
          result['company_id'] = _safeToString(customerData['company_id']);
          result['tax_number'] = _safeToString(customerData['tax_number']);
          result['name'] = _safeToString(customerData['name']);
          result['code'] = _safeToString(customerData['code']);
          result['address'] = _safeToString(customerData['address']);
          result['province_id'] = _safeToString(customerData['province_id']);
          result['province_name'] = _safeToString(customerData['province_name']);
          result['district_id'] = _safeToString(customerData['district_id']);
          result['district_name'] = _safeToString(customerData['district_name']);
          result['sub_district_id'] = _safeToString(customerData['sub_district_id']);
          result['sub_district_name'] = _safeToString(customerData['sub_district_name']);
          result['sub'] = _safeToString(customerData['sub']);
          result['created_at'] = _safeToString(customerData['created_at']);
          result['updated_at'] = _safeToString(customerData['updated_at']);
          
          return result;
        } else {
          throw Exception(data['message'] ?? 'ไม่สามารถดึงข้อมูลโปรไฟล์ได้');
        }
      } else {
        throw Exception('HTTP ${response.statusCode} - ไม่สามารถดึงข้อมูลโปรไฟล์ได้');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      throw Exception('ไม่สามารถดึงข้อมูลโปรไฟล์ได้: ${e.toString()}');
    }
  }
}
