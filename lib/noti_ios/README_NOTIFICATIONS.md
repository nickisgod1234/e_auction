# ระบบแจ้งเตือน E-Auction

## การตั้งค่า

### 1. Info.plist
เพิ่มการตั้งค่าต่อไปนี้ใน `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>background-fetch</string>
    <string>remote-notification</string>
</array>
<key>NSUserNotificationUsageDescription</key>
<string>E-Auction needs to send you notifications about auction updates, bidding status, and important events.</string>
```

### 2. AppDelegate.swift
เพิ่มการตั้งค่าใน `ios/Runner/AppDelegate.swift`:

```swift
import UserNotifications

// ใน application didFinishLaunchingWithOptions
UNUserNotificationCenter.current().delegate = self

// เพิ่ม delegate methods
override func userNotificationCenter(
  _ center: UNUserNotificationCenter,
  willPresent notification: UNNotification,
  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
  completionHandler([.alert, .badge, .sound])
}

override func userNotificationCenter(
  _ center: UNUserNotificationCenter,
  didReceive response: UNNotificationResponse,
  withCompletionHandler completionHandler: @escaping () -> Void
) {
  completionHandler()
}
```

### 3. Dependencies
เพิ่มใน `pubspec.yaml`:

```yaml
dependencies:
  flutter_local_notifications: ^18.0.1
  timezone: ^0.9.2
```

## การใช้งาน

### แจ้งเตือนที่ตั้งเวลาไว้

1. **แจ้งเตือนการประมูลใกล้หมดเวลา** (ทุก 30 นาที)
   - ID: 1
   - เวลา: ทุก 30 นาที

2. **แจ้งเตือนการประมูลใหม่** (ทุกวัน 13:49)
   - ID: 2
   - เวลา: ทุกวัน 13:49 น.

3. **แจ้งเตือนผลการประมูล** (ทุกวัน 18:00)
   - ID: 3
   - เวลา: ทุกวัน 18:00 น.

### แจ้งเตือนแบบ Real-time

4. **แจ้งเตือนการประมูลใกล้หมดเวลาแบบ Real-time** (ทุก 30 วินาที)
   - ID: 200
   - เงื่อนไข: เมื่อเหลือเวลาน้อยกว่า 1 นาที และไม่เคยแจ้งเตือนใน 61 วินาทีที่ผ่านมา
   - ข้อมูล: ใช้ข้อมูลจาก SharedPreferences (active_auctions)
   - การป้องกันการแจ้งเตือนซ้ำ: ใช้ SharedPreferences เก็บเวลาการแจ้งเตือนล่าสุด

### แจ้งเตือนแบบ Immediate

```dart
// ส่งแจ้งเตือนทันที
await sendImmediateAuctionNotification(
  plugin,
  'ชื่อการประมูล',
  'ข้อความแจ้งเตือน',
  payload: 'custom_payload'
);

// แจ้งเตือนเมื่อชนะ
await sendWinnerNotification(
  plugin,
  'ชื่อการประมูล',
  '1,500,000 บาท'
);

// แจ้งเตือนเมื่อถูกแซง
await sendOutbidNotification(
  plugin,
  'ชื่อการประมูล',
  '1,600,000 บาท'
);

// แจ้งเตือนการประมูลใกล้หมดเวลา
await sendExpiringAuctionNotification(
  plugin,
  'ใช้ทดสอบประกาศผู้ชนะ',
  'น้ำหวานดอกมะพร้าวอินทรีย์ (Bulk) - 12 kg',
  'เหลือ 1 นาที',
  '5',
  'หมดเวลาภายใน 1 ชั่วโมง'
);
```

### การเช็คการประมูลที่ใกล้หมดเวลา

```dart
// เริ่มเช็คการประมูลที่ใกล้หมดเวลาทุก 30 วินาที
await startExpiringAuctionChecker(plugin);

// หยุดการเช็ค
stopExpiringAuctionChecker();

// เช็คครั้งเดียว
await checkExpiringAuctions(plugin);

// ล้างประวัติการแจ้งเตือนสำหรับการประมูลที่สิ้นสุดแล้ว
await clearExpiredAuctionNotifications();

// บันทึกข้อมูลการประมูลที่กำลังใช้งาน
List<Map<String, dynamic>> auctions = [
  {
    'id': '1',
    'title': 'การประมูลสินค้า A',
    'auction_end_date': '2025-07-03 14:00:00',
    'current_price': '1000',
  }
];
await saveActiveAuctions(auctions);

// ดึงข้อมูลการประมูลที่กำลังใช้งาน
List<Map<String, dynamic>> activeAuctions = await getActiveAuctions();
```

### การทำงานของระบบป้องกันการแจ้งเตือนซ้ำ

1. **การตรวจสอบเวลา**: ระบบจะตรวจสอบว่าเหลือเวลาน้อยกว่า 1 นาทีหรือไม่
2. **การป้องกันซ้ำ**: ถ้าเคยแจ้งเตือนใน 61 วินาทีที่ผ่านมา จะไม่แจ้งเตือนอีก
3. **การเก็บประวัติ**: ใช้ SharedPreferences เก็บเวลาการแจ้งเตือนล่าสุดสำหรับแต่ละการประมูล
4. **การล้างประวัติ**: ล้างประวัติการแจ้งเตือนทุก 5 นาทีสำหรับการประมูลที่สิ้นสุดแล้ว

### การจัดการแจ้งเตือน

```dart
// ลบแจ้งเตือนทั้งหมด
await cancelAllNotifications(plugin);

// ลบแจ้งเตือนตาม ID
await cancelNotification(plugin, 1);

// ตรวจสอบสิทธิ์
bool hasPermission = await checkNotificationPermission(plugin);
```

## การตั้งค่าใน main.dart

```dart
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

  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // จัดการเมื่อผู้ใช้แตะที่แจ้งเตือน
      print('Notification tapped: ${response.payload}');
    },
  );

  // ตั้งค่าแจ้งเตือนสำหรับ iOS
  await setupIOSAuctionNotification(flutterLocalNotificationsPlugin);
  await setupIOSNewAuctionNotification(flutterLocalNotificationsPlugin);
  await setupIOSAuctionResultNotification(flutterLocalNotificationsPlugin);
}
```

## การทดสอบ

1. รันแอปบน iOS Simulator หรือ Device
2. อนุญาตการแจ้งเตือนเมื่อแอปถาม
3. ตรวจสอบว่าแจ้งเตือนทำงานตามเวลาที่ตั้งไว้
4. ทดสอบการส่งแจ้งเตือนแบบ immediate
5. ทดสอบการเช็คการประมูลที่ใกล้หมดเวลา:
   - สร้างการประมูลที่เหลือเวลาน้อยกว่า 1 นาที
   - ตรวจสอบว่าได้รับแจ้งเตือน
   - แตะที่แจ้งเตือนเพื่อไปยังหน้า My Auctions

## การจัดการแจ้งเตือน

### เมื่อผู้ใช้แตะที่แจ้งเตือน:
- `expiring_auction`: นำไปยังหน้า My Auctions
- `winner_auction`: นำไปยังหน้า My Auctions - Won tab
- `outbid_auction`: นำไปยังหน้า My Auctions - Active tab

### การจัดการ App Lifecycle:
- `AppLifecycleState.paused`: แอปเข้าพื้นหลัง - เช็คต่อเนื่อง
- `AppLifecycleState.resumed`: แอปกลับมาใช้งาน
- `AppLifecycleState.detached`: แอปปิด - หยุดการเช็ค

## หมายเหตุ

- แจ้งเตือนจะทำงานเฉพาะเมื่อแอปอยู่ในพื้นหลังหรือปิดอยู่
- ต้องมีสิทธิ์การแจ้งเตือนจากผู้ใช้
- การตั้งเวลาใช้ timezone ของเครื่อง
- แจ้งเตือนแบบ immediate จะแสดงทันทีแม้แอปจะเปิดอยู่
- ระบบป้องกันการแจ้งเตือนซ้ำทำงานโดยเก็บประวัติใน SharedPreferences
- การประมูลที่เหลือเวลาน้อยกว่า 1 นาทีจะถูกแจ้งเตือนทุก 61 วินาที
- ประวัติการแจ้งเตือนจะถูกล้างอัตโนมัติเมื่อเก่ากว่า 24 ชั่วโมง
- ข้อมูลการประมูลเก็บใน SharedPreferences แทนการเรียก API
- ต้องบันทึกข้อมูลการประมูลที่กำลังใช้งานด้วย `saveActiveAuctions()` 