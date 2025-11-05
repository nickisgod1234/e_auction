import 'package:flutter/material.dart';
import 'package:e_auction/services/auth_service/auth_service.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:e_auction/views/first_page/home_screen.dart';

class EmailLoginMethods {
  // Validate Email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกอีเมล';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'กรุณากรอกอีเมลที่ถูกต้อง';
    }
    return null;
  }

  // Validate Password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }
    if (value.length < 6) {
      return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
    }
    return null;
  }

  // Show Error Dialog
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('เกิดข้อผิดพลาด'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  // Show Success Dialog
  static void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('เข้าสู่ระบบสำเร็จ'),
          content: Text('ยินดีต้อนรับกลับมา'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  // Login with Email
  static Future<Map<String, dynamic>> loginWithEmail(
    AuthService authService,
    String email,
    String password,
  ) async {
    try {
      final userData = await authService.loginWithEmail(email, password);

      if (userData == null) {
        return {
          'success': false,
          'message': 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้',
        };
      }

      final status = userData['status'];
      if (status == 'error' || status == 'not_found') {
        return {
          'success': false,
          'message': userData['message'] ?? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
        };
      }

      if (status == 'deleted') {
        return {
          'success': false,
          'message': 'บัญชีนี้ถูกลบไปแล้ว กรุณาติดต่อผู้ดูแลระบบ',
        };
      }

      if (status == 'exists') {
        // บันทึกข้อมูลผู้ใช้
        await UserDataManager.saveUserData(userData);

        // ตรวจสอบข้อมูลที่บันทึกจริงจาก SharedPreferences
        final savedData = await UserDataManager.getUserData();

        print('=== Email Login Data ===');
        print('User ID: ${userData['id']}');
        print('Email: ${userData['email']}');
        print('User Name: ${userData['name']}');
        print('Role: ${savedData['role']}');
        print('Is Admin: ${savedData['is_admin']}');

        return {
          'success': true,
          'userData': userData,
        };
      }

      return {
        'success': false,
        'message': 'ไม่สามารถเข้าสู่ระบบได้',
      };
    } catch (e) {
      print('Error in loginWithEmail: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาด: ${e.toString()}',
      };
    }
  }

  // Navigate to Home Screen
  static void navigateToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(),
      ),
    );
  }
}
