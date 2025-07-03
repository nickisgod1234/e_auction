# iOS Notification System for E-Auction App

## Overview
ระบบแจ้งเตือนสำหรับแอปประมูลออนไลน์ ที่รองรับ iOS notifications พร้อมระบบประกาศผู้ชนะอัตโนมัติ

## Features
- ✅ iOS Local Notifications
- ✅ Scheduled Notifications (09:00 daily)
- ✅ Immediate Notifications
- ✅ Winner Announcement Automation
- ✅ Background Processing (Timer-based)
- ✅ Notification Permissions
- ✅ Automatic API Trigger (No user interaction required)

## Setup

### 1. iOS Configuration

#### Info.plist Configuration
เพิ่ม keys ต่อไปนี้ใน `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>remote-notification</string>
</array>

<key>NSUserNotificationUsageDescription</key>
<string>แอปต้องการส่งแจ้งเตือนเกี่ยวกับการประมูลและผลการประมูล</string>

<key>NSCameraUsageDescription</key>
<string>แอปต้องการเข้าถึงกล้องเพื่อถ่ายรูปสินค้า</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>แอปต้องการเข้าถึงรูปภาพเพื่อเลือกรูปสินค้า</string>
```

#### AppDelegate.swift Configuration
อัปเดต `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import flutter_local_notifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize notifications
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            FlutterLocalNotificationsPlugin.register(with: registry.registrar(forPlugin: "com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin")!)
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle notification taps
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    // Handle notifications when app is in foreground
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}
```

### 2. Dependencies
เพิ่มใน `pubspec.yaml`:

```yaml
dependencies:
  flutter_local_notifications: ^16.3.2
  timezone: ^0.9.2
  shared_preferences: ^2.2.2
  http: ^1.1.0
```

### 3. Main.dart Integration
เพิ่มใน `lib/main.dart`:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:e_auction/noti_ios/noti_ios.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap
      if (response.payload == 'announce_winners') {
        // Trigger winner announcement
        announceWinnersAtScheduledTime(flutterLocalNotificationsPlugin);
      }
    },
  );
  
  // Setup scheduled notifications
  await setupIOSAuctionNotification(flutterLocalNotificationsPlugin);
  await setupIOSNewAuctionNotification(flutterLocalNotificationsPlugin);
  await setupIOSAuctionResultNotification(flutterLocalNotificationsPlugin);
  
  runApp(MyApp());
}
```

## API Integration

### Winner Service API
ระบบใช้ API endpoint: `http://192.168.1.39/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php`

#### Announce Winner API
- **Endpoint**: `POST /?id={auctionId}&action=announce_winner`
- **Request Body**: ไม่มี (server รองรับแล้ว)
- **Response**:
```json
{
  "status": "success",
  "message": "Winner announced successfully",
  "data": {
    "winner_id": "123",
    "auction_id": "8"
  }
}
```

## Usage Examples

### 1. Manual Winner Announcement
```dart
// ประกาศผู้ชนะด้วย user_id อย่างเดียว
final result = await WinnerService.triggerAnnounceWinner('8', '13');
if (result['status'] == 'success') {
  print('Winner announced successfully!');
}
```

### 2. Scheduled Winner Announcement (09:00 daily)
```dart
// ระบบจะประกาศผู้ชนะอัตโนมัติทุกวันเวลา 09:00
// โดยส่ง API call ไปตรงๆ โดยไม่ต้องส่ง body ใดๆ
await announceWinnersAtScheduledTime(flutterLocalNotificationsPlugin);
```

### 3. Auto Trigger on Page Entry
```dart
// ประกาศผู้ชนะอัตโนมัติเมื่อเข้าไปในหน้า My Auctions
// ทำงานใน initState ของ MyAuctionsPage
_autoTriggerWinnerAnnouncement();
```

### 4. Send Immediate Notifications
```dart
// แจ้งเตือนผู้ชนะ
await sendWinnerNotification(
  plugin,
  'Patek Philippe Nautilus',
  '1,500,000 บาท'
);

// แจ้งเตือนการถูกแซง
await sendOutbidNotification(
  plugin,
  'Tesla Model S',
  '3,500,000 บาท'
);
```

## Notification Types

### 1. Scheduled Notifications
- **09:00 Daily**: ประกาศผู้ชนะอัตโนมัติ (payload: 'announce_winners')
- **18:00 Daily**: ผลการประมูล
- **Every 30 minutes**: การประมูลใกล้หมดเวลา

### 2. Immediate Notifications
- **Winner Notifications**: เมื่อชนะการประมูล
- **Outbid Notifications**: เมื่อถูกแซง
- **Auction End Notifications**: เมื่อการประมูลใกล้หมดเวลา

## Winner Announcement Workflow

### 1. Scheduled Announcement (09:00)
1. ระบบส่งแจ้งเตือนเวลา 09:00 ทุกวัน
2. **Background task** จะส่ง API call อัตโนมัติเมื่อถึงเวลา
3. ไม่ต้อง tap notification (ทำงานใน background)
4. ส่ง API call ไปตรงๆ: `POST /?id=8&action=announce_winner`
5. ไม่ส่ง body ใดๆ (server รองรับแล้ว)
6. API ประกาศผู้ชนะและส่งผลลัพธ์กลับ

### 2. Auto Trigger on Page Entry
1. เมื่อ user เข้าไปในหน้า My Auctions
2. เรียกใช้ `_autoTriggerWinnerAnnouncement()` ใน initState
3. ดึง user_id จาก SharedPreferences
4. ส่ง trigger ไปยัง auction ID ที่กำหนด
5. รีเฟรชข้อมูลหลังจากประกาศสำเร็จ

### 3. Manual Trigger
1. เรียกใช้ `_manualTriggerWinnerAnnouncement(auctionId, userId)`
2. ส่ง trigger ไปยัง API
3. รีเฟรชข้อมูลหลังจากประกาศสำเร็จ

## Testing

### Test Scheduled Notification
```bash
# เปลี่ยนเวลาใน setupIOSNewAuctionNotification เป็นเวลาปัจจุบัน + 1 นาที
var scheduledTime = DateTime.now().add(Duration(minutes: 1));
```

### Test Manual Trigger
```dart
// ทดสอบ API call โดยตรง
final url = Uri.parse('http://192.168.1.39/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=8&action=announce_winner');
final response = await http.post(url);
print('Response: ${response.body}');
```

### Test Auto Trigger
```dart
// เข้าไปในหน้า My Auctions
// ระบบจะเรียก _autoTriggerWinnerAnnouncement() อัตโนมัติ
```

## Error Handling
- ถ้าไม่มี user_id ใน SharedPreferences จะข้ามการประกาศ
- ถ้า API call ล้มเหลว จะแสดง error ใน console
- ระบบจะรีเฟรชข้อมูลหลังจากประกาศสำเร็จ

## Configuration
- Auction ID ที่จะประกาศผู้ชนะสามารถกำหนดได้ใน `announceWinnersAtScheduledTime()`
- สามารถเพิ่ม auction ID หลายตัวได้
- เวลาส่งแจ้งเตือนสามารถปรับได้ใน `setupIOSNewAuctionNotification()`

## Security Considerations

### API Security
- ใช้ `user_id` จาก SharedPreferences เท่านั้น
- ไม่ส่งข้อมูลส่วนตัวอื่นๆ
- ตรวจสอบ authentication ก่อนเรียก API

### Data Privacy
- ไม่เก็บข้อมูลส่วนตัวใน notifications
- ใช้ payload เฉพาะสำหรับ routing
- ลบ notifications เก่าอัตโนมัติ

## Performance Optimization

### Background Processing
- ใช้ `background-processing` mode
- จำกัดการเรียก API ใน background
- ใช้ SharedPreferences สำหรับ caching

### Memory Management
- ลบ notifications เก่าอัตโนมัติ
- จำกัดจำนวน notifications พร้อมกัน
- ใช้ weak references สำหรับ callbacks

## Troubleshooting

### iOS Specific Issues
1. **Notifications not showing**: ตรวจสอบ permissions
2. **Background not working**: ตรวจสอบ UIBackgroundModes
3. **Sound not playing**: ตรวจสอบ sound settings

### API Issues
1. **Connection timeout**: ตรวจสอบ network
2. **Authentication failed**: ตรวจสอบ user_id
3. **Server error**: ตรวจสอบ API endpoint

## Future Enhancements

### Planned Features
- [ ] Push Notifications (Firebase)
- [ ] Rich Notifications (images, actions)
- [ ] Notification Groups
- [ ] Custom Sound Files
- [ ] Notification History

### API Improvements
- [ ] Batch Winner Announcements
- [ ] Real-time WebSocket Updates
- [ ] Notification Preferences API
- [ ] Analytics Integration 