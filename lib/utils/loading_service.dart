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
} 