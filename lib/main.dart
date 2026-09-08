
import 'package:flutter/material.dart';
import 'package:e_auction/views/first_page/request_otp_page/request_otp_login.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:e_auction/noti_ios/noti_ios.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:async';
import 'package:e_auction/services/product_service.dart';
import 'package:e_auction/services/product_status_notifier.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:e_auction/views/first_page/my_products_page/my_products_page.dart';

/// ใช้เปิดหน้าจากการแตะ notification ที่ไม่มี BuildContext ให้ใช้
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      } else if (response.payload?.startsWith('product_approval_') ?? false) {
        // แจ้งผลอนุมัติสินค้า พาไปดูสถานะสินค้าที่ผู้ใช้ลงไว้
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const MyProductsPage()),
        );
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

  // ตั้งค่า timer สำหรับตรวจสอบการประมูลที่ใกล้หมดเวลา (สำหรับ iOS)
  _setupNearExpiryNotificationTimer(flutterLocalNotificationsPlugin);

  // ตั้งค่า timer สำหรับตรวจสอบผลอนุมัติสินค้าที่ผู้ใช้ลงไว้
  _setupProductApprovalNotificationTimer(flutterLocalNotificationsPlugin);
}

// Timer สำหรับตรวจสอบผลอนุมัติสินค้าของผู้ใช้
Timer? _productApprovalNotificationTimer;

void _setupProductApprovalNotificationTimer(
  FlutterLocalNotificationsPlugin plugin,
) {
  _productApprovalNotificationTimer?.cancel();

  Future<void> runCheck() async {
    // ถ้ายังไม่ล็อกอินทั้งสองฟังก์ชันจะออกก่อนยิง request
    await ProductStatusNotifier.discoverPendingProducts();
    await ProductStatusNotifier.checkPendingProducts(plugin);
  }

  runCheck();

  // ทุก 2 นาที รอบที่ไม่มีสินค้ารออนุมัติจะไม่ยิง request เลย
  _productApprovalNotificationTimer = Timer.periodic(
    Duration(minutes: 2),
    (timer) async {
      print('📦 MAIN: ตรวจสอบผลอนุมัติสินค้าที่ลงไว้...');
      await runCheck();
    },
  );

  print('✅ MAIN: ตั้งค่า timer สำหรับตรวจสอบผลอนุมัติสินค้าแล้ว (ทุก 2 นาที)');
}

// Timer สำหรับตรวจสอบการประมูลที่ใกล้หมดเวลา
Timer? _nearExpiryNotificationTimer;

void _setupNearExpiryNotificationTimer(
  FlutterLocalNotificationsPlugin plugin,
) {
  // หยุด timer เก่าก่อน (ถ้ามี)
  _nearExpiryNotificationTimer?.cancel();

  // สร้าง ProductService instance
  final productService = ProductService(baseUrl: Config.apiUrlAuction);

  // เรียกใช้ทันทีครั้งแรก
  productService.checkAndNotifyNearExpiryAuctions(plugin);
  productService.cleanupExpiredNotificationFlags(plugin);

  // ตั้ง timer ให้ตรวจสอบทุก 30 วินาที (เพื่อให้ตรวจสอบบ่อยขึ้นและแจ้งเตือนได้ทันที)
  _nearExpiryNotificationTimer = Timer.periodic(
    Duration(seconds: 30),
    (timer) async {
      print('⏰ MAIN: ตรวจสอบการประมูลที่ใกล้หมดเวลา...');
      await productService.checkAndNotifyNearExpiryAuctions(plugin);
      await productService.cleanupExpiredNotificationFlags(plugin);
    },
  );

  print('✅ MAIN: ตั้งค่า timer สำหรับตรวจสอบการประมูลที่ใกล้หมดเวลาแล้ว (ทุก 30 วินาที)');
  print('✅ MAIN: ระบบจะแจ้งเตือนทันทีเมื่อเหลือ <= 5 นาที และตั้งเวลาแจ้งเตือนล่วงหน้าเพื่อให้แจ้งเตือนแม้เมื่อออกจากแอพ');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppTheme.getAppTitle(AppTheme.currentClient),
      theme: AppTheme.getThemeForClient(AppTheme.currentClient),
      home: RequestOtpLoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
