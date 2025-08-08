import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:e_auction/services/add_auction_service/add_auction_service.dart';

class AddAuctionMethods {
  // Image Picker Methods
  static Future<File?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  static Future<File?> takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  // Load Quotation Types
  static Future<List<Map<String, dynamic>>> loadQuotationTypes() async {
    return await AddAuctionService.loadQuotationTypes();
  }

  // Date Selection
  static Future<DateTime?> selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
    return null;
  }

  // Update Min Increment
  static double updateMinIncrement({
    required bool isPercentage,
    required double percentageValue,
    required double currentPrice,
  }) {
    if (isPercentage) {
      return currentPrice * percentageValue / 100;
    }
    return 100; // Default fixed amount
  }

  // Form Validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอก$fieldName';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกอีเมล';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'กรุณากรอกอีเมลให้ถูกต้อง';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกเบอร์โทรศัพท์';
    }
    if (value.length < 10) {
      return 'เบอร์โทรศัพท์ต้องมีอย่างน้อย 10 หลัก';
    }
    return null;
  }

  static String? validateIdCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกเลขบัตรประชาชน';
    }
    if (value.length != 13) {
      return 'เลขบัตรประชาชนต้องมี 13 หลัก';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกราคา';
    }
    try {
      // Parse directly (no formatting)
      double price = double.parse(value);
      if (price < 0) {
        return 'ราคาต้องมากกว่าหรือเท่ากับ 0';
      }
    } catch (e) {
      return 'กรุณากรอกราคาให้ถูกต้อง';
    }
    return null;
  }

  static String? validateMinIncrement(String? value, double currentPrice) {
    if (value == null || value.isEmpty) {
      return null; // ไม่บังคับให้กรอกขั้นต่ำการเพิ่ม
    }
    try {
      // Parse directly (no formatting)
      double minIncrement = double.parse(value);
      if (minIncrement < 0) {
        return 'ขั้นต่ำการเพิ่มต้องมากกว่าหรือเท่ากับ 0';
      }
      if (minIncrement > currentPrice && currentPrice > 0) {
        return 'ขั้นต่ำการเพิ่มต้องไม่เกินราคาปัจจุบัน (฿${NumberFormat('#,###').format(currentPrice)})';
      }
    } catch (e) {
      return 'กรุณากรอกขั้นต่ำการเพิ่มให้ถูกต้อง';
    }
    return null;
  }

  // Show Confirmation Dialog
  static Future<bool> showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการเพิ่มประมูล'),
          content: const Text('คุณต้องการเพิ่มประมูลนี้หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Save Auction
  static Future<Map<String, dynamic>> saveAuction({
    required Map<String, dynamic> auctionData,
    File? imageFile,
  }) async {
    // Format data for API
    final formattedData = AddAuctionService.formatAuctionDataForAPI(auctionData);
    
    // Validate data
    final validation = AddAuctionService.validateAuctionData(formattedData);
    if (!validation['isValid']) {
      throw Exception('Validation failed: ${validation['errors']}');
    }
    
    return await AddAuctionService.saveAuction(
      auctionData: formattedData,
      imageFile: imageFile,
    );
  }

  // Show Success Dialog
  static void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              const Text('สำเร็จ'),
            ],
          ),
          content: const Text('เพิ่มประมูลสำเร็จแล้ว'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous page
              },
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  // Show Error Dialog
  static void showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              const Text('เกิดข้อผิดพลาด'),
            ],
          ),
          content: Text(errorMessage),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  // Format Currency
  static String formatCurrency(double amount) {
    return '฿${amount.toStringAsFixed(2)}';
  }

  // Format Date
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Format DateTime
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Validate Auction Data
  static Map<String, dynamic> validateAuctionData(Map<String, dynamic> data) {
    return AddAuctionService.validateAuctionData(data);
  }

  // Format Auction Data for API
  static Map<String, dynamic> formatAuctionDataForAPI(Map<String, dynamic> data) {
    return AddAuctionService.formatAuctionDataForAPI(data);
  }
} 