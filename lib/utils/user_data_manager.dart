import 'package:shared_preferences/shared_preferences.dart';

class UserDataManager {
  static const String _phoneNumberKey = 'phone_number';
  static const String _tokenKey = 'token_otp';
  static const String _idKey = 'id';
  static const String _emailKey = 'email';
  static const String _passwordKey = 'password';
  static const String _roleKey = 'role';
  static const String _isAdminKey = 'is_admin';
  static const String _nameKey = 'name';
  static const String _profilePictureKey = 'profile_picture';
  static const String _typeKey = 'type';
  static const String _addressKey = 'address';
  static const String _statusKey = 'status';

  // Helper function เพื่อตรวจสอบ admin status จากหลายแหล่ง
  static bool _determineAdminStatus(Map<String, dynamic> userData) {
    // ตรวจสอบจาก is_admin field
    if (userData['is_admin'] != null) {
      final isAdmin = userData['is_admin'];
      if (isAdmin == true || isAdmin == 'true' || isAdmin == 1) {
        return true;
      }
      if (isAdmin == false || isAdmin == 'false' || isAdmin == 0) {
        return false;
      }
    }
    
    // ตรวจสอบจาก role field
    if (userData['role'] != null) {
      final role = userData['role'].toString().toLowerCase();
      if (role == 'admin') {
        return true;
      }
      if (role == 'customer') {
        return false;
      }
    }
    
    // ตรวจสอบจาก user_type field (database field)
    if (userData['user_type'] != null) {
      final userType = userData['user_type'].toString().toLowerCase();
      if (userType == 'admin') {
        return true;
      }
      if (userType == 'customer') {
        return false;
      }
    }
    
    // Default เป็น customer
    return false;
  }
  
  // Helper function เพื่อกำหนด role จากหลายแหล่ง
  static String _determineRole(Map<String, dynamic> userData) {
    // ตรวจสอบจาก role field
    if (userData['role'] != null && userData['role'].toString().isNotEmpty) {
      return userData['role'].toString();
    }
    
    // ตรวจสอบจาก user_type field (database field)
    if (userData['user_type'] != null && userData['user_type'].toString().isNotEmpty) {
      return userData['user_type'].toString();
    }
    
    // ตรวจสอบจาก is_admin field
    if (userData['is_admin'] != null) {
      final isAdmin = userData['is_admin'];
      if (isAdmin == true || isAdmin == 'true' || isAdmin == 1) {
        return 'admin';
      }
      if (isAdmin == false || isAdmin == 'false' || isAdmin == 0) {
        return 'customer';
      }
    }
    
    // Default เป็น customer
    return 'customer';
  }

  // บันทึกข้อมูลผู้ใช้ทั้งหมด
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    
    print('=== UserDataManager.saveUserData ===');
    print('Input Role: ${userData['role']}');
    print('Input Is Admin: ${userData['is_admin']}');
    print('Input User Type: ${userData['user_type']}');
    
    await prefs.setString(_phoneNumberKey, userData['phone_number'] ?? '');
    await prefs.setString(_tokenKey, userData['token_otp'] ?? '');
    await prefs.setString(_idKey, userData['id']?.toString() ?? '');
    await prefs.setString(_emailKey, userData['email'] ?? '');
    await prefs.setString(_passwordKey, userData['password'] ?? '');
    
    // ใช้ helper functions เพื่อกำหนด role และ is_admin
    final role = _determineRole(userData);
    final isAdmin = _determineAdminStatus(userData);
    
    print('Processed Role: $role');
    print('Processed Is Admin: $isAdmin');
    
    await prefs.setString(_roleKey, role);
    await prefs.setBool(_isAdminKey, isAdmin);
    await prefs.setString(_nameKey, userData['name'] ?? '');
    await prefs.setString(_profilePictureKey, userData['profile_picture'] ?? '');
    await prefs.setString(_typeKey, userData['type'] ?? '');
    await prefs.setString(_addressKey, userData['address'] ?? '');
    await prefs.setString(_statusKey, userData['status'] ?? '');
    
    // ตรวจสอบข้อมูลที่บันทึกจริง
    final savedRole = prefs.getString(_roleKey);
    final savedIsAdmin = prefs.getBool(_isAdminKey);
    
    print('=== UserDataManager Verification ===');
    print('Saved Role: $savedRole');
    print('Saved Is Admin: $savedIsAdmin');
  }

  // ดึงข้อมูลผู้ใช้ทั้งหมด
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'phone_number': prefs.getString(_phoneNumberKey),
      'token_otp': prefs.getString(_tokenKey),
      'id': prefs.getString(_idKey),
      'email': prefs.getString(_emailKey),
      'password': prefs.getString(_passwordKey),
      'role': prefs.getString(_roleKey),
      'is_admin': prefs.getBool(_isAdminKey) ?? false,
      'name': prefs.getString(_nameKey),
      'profile_picture': prefs.getString(_profilePictureKey),
      'type': prefs.getString(_typeKey),
      'address': prefs.getString(_addressKey),
      'status': prefs.getString(_statusKey),
    };
  }

  // ตรวจสอบว่าเป็น admin หรือไม่
  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAdminKey) ?? false;
  }

  // ดึง role ของผู้ใช้
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  // ดึงชื่อผู้ใช้
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  // ดึง email ผู้ใช้
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // ดึงเบอร์โทรผู้ใช้
  static Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneNumberKey);
  }

  // ดึง ID ผู้ใช้
  static Future<String?> getID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idKey);
  }

  // ดึง customer_id สำหรับ chat system
  static Future<int?> getCustomerID() async {
    final prefs = await SharedPreferences.getInstance();
    final idString = prefs.getString(_idKey);
    print('UserDataManager: Raw ID string: $idString');
    
    if (idString != null && idString.isNotEmpty) {
      final customerId = int.tryParse(idString);
      print('UserDataManager: Parsed customer ID: $customerId');
      return customerId;
    }
    
    print('UserDataManager: No valid ID found');
    return null;
  }

  // ลบข้อมูลผู้ใช้ทั้งหมด (สำหรับ logout)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_idKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_isAdminKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_profilePictureKey);
    await prefs.remove(_typeKey);
    await prefs.remove(_addressKey);
    await prefs.remove(_statusKey);
    
    // session แชทผูกกับ customer id เดิม ต้องลบไม่ให้ผู้ใช้คนถัดไปใช้ต่อ
    await prefs.remove('chat_session_id');
    
    // สถานะสินค้าที่เฝ้าดูไว้เป็นของผู้ใช้คนเดิม ต้องลบทั้งหมด
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith('product_status_')) {
        await prefs.remove(key);
      }
    }
    
    // ลบข้อมูลเก่าที่อาจเหลืออยู่
    await prefs.remove('created_at');
    await prefs.remove('updated_at');
    await prefs.remove('company_id');
    await prefs.remove('logo');
    await prefs.remove('phone');
    await prefs.remove('code');
    await prefs.remove('tax_number');
    await prefs.remove('fullname');
    await prefs.remove('addr');
    await prefs.remove('province_id');
    await prefs.remove('district_id');
    await prefs.remove('sub_district_id');
    await prefs.remove('sub');
    await prefs.remove('pass');
    await prefs.remove('reset_key');
    await prefs.remove('reset_key_exp');
    await prefs.remove('isdelete');
  }

  // ตรวจสอบว่าผู้ใช้ล็อกอินแล้วหรือไม่
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString(_phoneNumberKey);
    final token = prefs.getString(_tokenKey);
    final id = prefs.getString(_idKey);
    
    print('UserDataManager: Login check - Phone: $phoneNumber, Token: ${token != null ? "exists" : "null"}, ID: $id');
    
    final isLoggedIn = phoneNumber != null && token != null && id != null;
    print('UserDataManager: Is logged in: $isLoggedIn');
    
    return isLoggedIn;
  }

  // ตรวจสอบว่าบัญชีถูกลบหรือไม่
  static Future<bool> isAccountDeleted() async {
    final prefs = await SharedPreferences.getInstance();
    final isdelete = prefs.getString('isdelete');
    return isdelete == 'true';
  }
}
