
import 'package:flutter/material.dart';
import 'package:e_auction/views/first_page/request_otp_page/request_otp_login.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:e_auction/noti_ios/noti_ios.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ตั้งค่าแจ้งเตือน
  await _setupNotifications();

  runApp(const MyApp());
}

Future<void> _setupNotifications() async {
  // ตั้งค่า timezone
  tz.initializeTimeZones();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ตั้งค่า Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // ตั้งค่า iOS
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // จัดการเมื่อผู้ใช้แตะที่แจ้งเตือน
      print('🔔 MAIN: Notification tapped!');
      print('🔔 MAIN: Payload: ${response.payload}');
      print('🔔 MAIN: ID: ${response.id}');
      print('🔔 MAIN: Action ID: ${response.actionId}');

      // เช็คว่าเป็น scheduled notification สำหรับประกาศผู้ชนะหรือไม่
      if (response.payload == 'announce_winners') {
        print('🔔 MAIN: Received scheduled winner announcement notification');
        print('🔔 MAIN: Calling announceWinnersAtScheduledTime...');
        // เรียกใช้ฟังก์ชันประกาศผู้ชนะ
        announceWinnersAtScheduledTime(flutterLocalNotificationsPlugin);
      } else {
        print(
            '🔔 MAIN: Not a winner announcement notification, payload: ${response.payload}');
      }
    },
  );

  // ตั้งค่าแจ้งเตือนสำหรับ iOS

  await setupIOSNewAuctionNotification(flutterLocalNotificationsPlugin);

  // ตั้งค่า background task สำหรับประกาศผู้ชนะ
  await setupBackgroundWinnerAnnouncement();
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
