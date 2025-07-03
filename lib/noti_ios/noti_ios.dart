import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

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

/// แจ้งเตือนการประมูลใหม่ (ทุกวันตอน 09:00)
Future<void> setupIOSNewAuctionNotification(FlutterLocalNotificationsPlugin plugin) async {
  final iOSPlugin = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
  if (iOSPlugin != null) {
    await iOSPlugin.requestPermissions(alert: true, badge: true, sound: true);

    String newAuctionTitle = 'การประมูลใหม่';
    String newAuctionBody = 'มีการประมูลใหม่เข้ามาในระบบแล้ว อย่าลืมเข้าไปดูและประมูลกันนะคะ';

    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 14, 03);
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
      );
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