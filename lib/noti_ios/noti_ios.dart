import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/services/winner_service.dart';
import 'package:e_auction/services/user_bid_history_service.dart';
import 'dart:isolate';
import 'dart:async';

/// แจ้งเตือนการประมูลที่กำลังจะหมดเวลา (ทุก 30 นาที)
Future<void> setupIOSAuctionNotification(FlutterLocalNotificationsPlugin plugin) async {
  final iOSPlugin = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
  if (iOSPlugin != null) {
    await iOSPlugin.requestPermissions(alert: true, badge: true, sound: true);

    String auctionTitle = 'การประมูลใกล้หมดเวลา';
    String auctionBody = 'มีการประมูลที่กำลังจะหมดเวลาในอีก 30 นาที อย่าลืมตรวจสอบและประมูลต่อนะคะ';

    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, now.hour, now.minute + 30);
    if (scheduledTime.minute >= 60) {
      scheduledTime = DateTime(now.year, now.month, now.day, now.hour + 1, scheduledTime.minute - 60);
    }

    await plugin.zonedSchedule(
        1,
        auctionTitle,
        auctionBody,
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
  }
}

/// แจ้งเตือนการประมูลใหม่ (ทุกวันตอน 09:00) - ประกาศผู้ชนะด้วย
Future<void> setupIOSNewAuctionNotification(FlutterLocalNotificationsPlugin plugin) async {
  final iOSPlugin = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
  if (iOSPlugin != null) {
    await iOSPlugin.requestPermissions(alert: true, badge: true, sound: true);

    String newAuctionTitle = 'ประกาศผู้ชนะการประมูล';
    String newAuctionBody = 'ระบบกำลังประกาศผู้ชนะการประมูลที่หมดเวลาแล้ว อย่าลืมเข้าไปดูผลการประมูลกันนะคะ';

    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 15, 40); // 09:00
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }

    await plugin.zonedSchedule(
        2,
        newAuctionTitle,
        newAuctionBody,
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'announce_winners', // เพิ่ม payload เพื่อระบุว่าเป็นการประกาศผู้ชนะ
      );
      
    // ส่ง trigger ทันทีเมื่อตั้งเวลาเสร็จ (สำหรับทดสอบ)
    print('🔔 SCHEDULED: Setting up notification for ${scheduledTime.toString()}');
    print('🔔 SCHEDULED: Will automatically trigger winner announcement at scheduled time');
  }
}

/// แจ้งเตือนผลการประมูล (ทุกวันตอน 18:00)
Future<void> setupIOSAuctionResultNotification(FlutterLocalNotificationsPlugin plugin) async {
  final iOSPlugin = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
  if (iOSPlugin != null) {
    await iOSPlugin.requestPermissions(alert: true, badge: true, sound: true);

    String resultTitle = 'ผลการประมูล';
    String resultBody = 'มีการประมูลที่สิ้นสุดแล้ว อย่าลืมตรวจสอบผลการประมูลกันนะคะ';

    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 18, 0);
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }

    await plugin.zonedSchedule(
      3,
      resultTitle,
      resultBody,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

/// ส่งแจ้งเตือนแบบ immediate (สำหรับการประมูลที่กำลังจะหมดเวลา)
Future<void> sendImmediateAuctionNotification(
  FlutterLocalNotificationsPlugin plugin,
  String auctionTitle,
  String message,
  {String? payload}
) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'auction_channel',
    'Auction Notifications',
    channelDescription: 'Notifications for auction events',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'default',
    interruptionLevel: InterruptionLevel.active,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  await plugin.show(
    100, // ใช้ ID ที่ไม่ซ้ำกับ scheduled notifications
    auctionTitle,
    message,
    platformChannelSpecifics,
    payload: payload,
  );
}

/// ส่งแจ้งเตือนเมื่อชนะการประมูล
Future<void> sendWinnerNotification(
  FlutterLocalNotificationsPlugin plugin,
  String auctionTitle,
  String finalPrice,
) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'winner_channel',
    'Winner Notifications',
    channelDescription: 'Notifications for auction winners',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    color: Color(0xFF4CAF50), // สีเขียวสำหรับผู้ชนะ
  );

  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'default',
    interruptionLevel: InterruptionLevel.active,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  await plugin.show(
    101,
    '🎉 ยินดีด้วย! คุณชนะการประมูล',
    'คุณชนะการประมูล "$auctionTitle" ในราคา $finalPrice',
    platformChannelSpecifics,
    payload: 'winner_auction',
  );
}

/// ส่งแจ้งเตือนเมื่อถูกแซง
Future<void> sendOutbidNotification(
  FlutterLocalNotificationsPlugin plugin,
  String auctionTitle,
  String currentBid,
) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'outbid_channel',
    'Outbid Notifications',
    channelDescription: 'Notifications when you are outbid',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    color: Color(0xFFFF9800), // สีส้มสำหรับการถูกแซง
  );

  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'default',
    interruptionLevel: InterruptionLevel.active,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  await plugin.show(
    102,
    '⚠️ คุณถูกแซงแล้ว!',
    'มีคนประมูล "$auctionTitle" ในราคา $currentBid มากกว่าคุณแล้ว',
    platformChannelSpecifics,
    payload: 'outbid_auction',
  );
}

/// ลบแจ้งเตือนทั้งหมด
Future<void> cancelAllNotifications(FlutterLocalNotificationsPlugin plugin) async {
  await plugin.cancelAll();
}

/// ลบแจ้งเตือนตาม ID
Future<void> cancelNotification(FlutterLocalNotificationsPlugin plugin, int id) async {
  await plugin.cancel(id);
}

/// ตรวจสอบสิทธิ์การแจ้งเตือน
Future<bool> checkNotificationPermission(FlutterLocalNotificationsPlugin plugin) async {
  final iOSPlugin = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
  if (iOSPlugin != null) {
    final result = await iOSPlugin.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return result == true;
  }
  return false;
}

/// ฟังก์ชันใหม่: ประกาศผู้ชนะเมื่อถึงเวลาที่กำหนด
Future<void> announceWinnersAtScheduledTime(FlutterLocalNotificationsPlugin plugin) async {
  try {
    print('🔔 SCHEDULED: Starting scheduled winner announcement...');
    
    // ส่ง API call ไปตรงๆ โดยไม่ต้องส่ง body
    final url = Uri.parse('http://192.168.1.39/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=8&action=announce_winner');
    
    print('🔔 SCHEDULED: Sending API call to: $url');
    
    final response = await http.post(url);
    
    print('🔔 SCHEDULED: API Response Status: ${response.statusCode}');
    print('🔔 SCHEDULED: API Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      print('🎉 SCHEDULED: Winner announcement API call successful!');
    } else {
      print('⚠️ SCHEDULED: Winner announcement API call failed with status: ${response.statusCode}');
    }
    
    print('🔔 SCHEDULED: Winner announcement completed');
  } catch (e) {
    print('❌ SCHEDULED: Error in scheduled winner announcement: $e');
  }
}

/// ฟังก์ชันใหม่: Background task สำหรับส่ง API call
Future<void> triggerWinnerAnnouncementInBackground() async {
  try {
    print('🔄 BACKGROUND: Starting background winner announcement...');
    
    // ส่ง API call ไปตรงๆ โดยไม่ต้องส่ง body
    final url = Uri.parse('http://192.168.1.39/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=8&action=announce_winner');
    
    print('🔄 BACKGROUND: Sending API call to: $url');
    
    final response = await http.post(url);
    
    print('🔄 BACKGROUND: API Response Status: ${response.statusCode}');
    print('🔄 BACKGROUND: API Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      print('🎉 BACKGROUND: Winner announcement API call successful!');
    } else {
      print('⚠️ BACKGROUND: Winner announcement API call failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ BACKGROUND: Error in background winner announcement: $e');
  }
}

/// ฟังก์ชันใหม่: ตั้งค่า background task สำหรับเวลา 09:00
Future<void> setupBackgroundWinnerAnnouncement() async {
  try {
    print('🔄 BACKGROUND: Setting up background winner announcement...');
    
    // คำนวณเวลาถัดไปที่จะเป็น 09:00
    final now = DateTime.now();
    var nextScheduledTime = DateTime(now.year, now.month, now.day, 15, 40); // 09:00
    
    if (now.isAfter(nextScheduledTime)) {
      nextScheduledTime = nextScheduledTime.add(Duration(days: 1));
    }
    
    final delay = nextScheduledTime.difference(now);
    
    print('🔄 BACKGROUND: Next scheduled time: ${nextScheduledTime.toString()}');
    print('🔄 BACKGROUND: Delay: ${delay.inSeconds} seconds');
    
    // ตั้ง timer สำหรับส่ง trigger
    Timer(delay, () async {
      print('🔄 BACKGROUND: Timer triggered at ${DateTime.now().toString()}');
      await triggerWinnerAnnouncementInBackground();
      
      // ตั้ง timer สำหรับวันถัดไป
      Timer(Duration(days: 1), () {
        setupBackgroundWinnerAnnouncement();
      });
    });
    
  } catch (e) {
    print('❌ BACKGROUND: Error setting up background task: $e');
  }
}





