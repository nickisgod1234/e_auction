import 'package:flutter/material.dart';
import 'package:e_auction/views/first_page/request_otp_page/request_otp_login.dart';
import 'package:e_auction/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppTheme.getAppTitle(AppTheme.currentClient),
      theme: AppTheme.getThemeForClient(AppTheme.currentClient),
      home: RequestOtpLoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
