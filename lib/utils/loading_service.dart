import 'package:flutter/material.dart';

class LoadingService {
  // Singleton pattern
  LoadingService._privateConstructor();
  static final LoadingService _instance = LoadingService._privateConstructor();
  static LoadingService get instance => _instance;

  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  void show() {
    if (!isLoading.value) {
      isLoading.value = true;
    }
  }

  void hide() {
    if (isLoading.value) {
      isLoading.value = false;
    }
  }

  /// แสดง loading dialog ขณะรอ Future ทำงานเสร็จ
  static Future<T> showLoadingWhile<T>(
      BuildContext context, Future<T> Function() futureFn) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final result = await futureFn();

      // เช็ค context ยังอยู่ใน tree หรือไม่ก่อนปิด dialog
      try {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        } else {}
      } catch (e) {}

      return result;
    } catch (e) {
      // เช็ค context ยังอยู่ใน tree หรือไม่ก่อนปิด dialog
      try {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        } else {}
      } catch (e2) {}

      rethrow;
    }
  }
}
