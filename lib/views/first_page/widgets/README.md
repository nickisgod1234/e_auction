# Auction Widgets

โฟลเดอร์นี้เก็บ reusable widgets สำหรับการแสดงผลข้อมูลการประมูล

## ไฟล์ในโฟลเดอร์

### 1. `auction_image_widget.dart`
Widget สำหรับแสดงรูปภาพการประมูล

**การใช้งาน:**
```dart
import 'package:e_auction/views/first_page/widgets/auction_image_widget.dart';

// ใช้เป็น Widget
AuctionImageWidget(
  imagePath: auction['image'],
  width: 80,
  height: 80,
  borderRadius: BorderRadius.circular(8),
)

// หรือใช้เป็น Helper function
buildAuctionImage(
  auction['image'],
  width: 80,
  height: 80,
  borderRadius: BorderRadius.circular(8),
)
```

**คุณสมบัติ:**
- รองรับทั้ง URL และ local assets
- จัดการ error อัตโนมัติ
- รองรับ borderRadius
- แสดง placeholder เมื่อไม่มีรูปภาพ

### 2. `auction_list_item_widget.dart`
Widget สำหรับแสดงรายการการประมูลในรูปแบบ list

**การใช้งาน:**
```dart
import 'package:e_auction/views/first_page/widgets/auction_list_item_widget.dart';

AuctionListItemWidget(
  auction: auctionData,
  onTap: () => Navigator.push(...),
  priceLabel: 'ราคาปัจจุบัน: ฿1,000,000',
  timeLabel: 'เหลือเวลา 2 ชั่วโมง',
  timeColor: Colors.red,
)
```

**คุณสมบัติ:**
- แสดงรูปภาพ, ชื่อสินค้า, ราคา, และเวลา
- รองรับการกำหนด label และสีเอง
- ใช้ Format utility สำหรับการแสดงราคา
- รองรับการซ่อน/แสดงส่วนต่างๆ

### 3. `auction_card_widgets.dart`
Widget สำหรับแสดงการประมูลในรูปแบบ card (มีอยู่เดิม)

### 4. `auction_dialogs.dart`
Dialog ต่างๆ สำหรับการประมูล (มีอยู่เดิม)

### 5. `my_auctions_widget.dart`
Widget สำหรับแสดงการประมูลของฉัน (มีอยู่เดิม)

### 6. `loading_overlay.dart`
Widget สำหรับแสดง loading overlay (มีอยู่เดิม)

## การใช้งานทั่วไป

### การแสดงรูปภาพ
```dart
// แสดงรูปภาพแบบพื้นฐาน
AuctionImageWidget(imagePath: auction['image'])

// แสดงรูปภาพพร้อม borderRadius
AuctionImageWidget(
  imagePath: auction['image'],
  width: 100,
  height: 100,
  borderRadius: BorderRadius.circular(12),
)
```

### การแสดงรายการ
```dart
// รายการการประมูลปัจจุบัน
AuctionListItemWidget(
  auction: currentAuction,
  onTap: () => navigateToDetail(currentAuction),
  timeColor: Colors.red, // สีแดงสำหรับเวลาที่เหลือ
)

// รายการการประมูลที่จะมาถึง
AuctionListItemWidget(
  auction: upcomingAuction,
  onTap: () => navigateToDetail(upcomingAuction),
  priceLabel: 'ราคาเริ่มต้น: ${Format.formatCurrency(auction['startingPrice'])}',
  timeLabel: 'จะเริ่มในอีก: ${auction['timeUntilStart']}',
  timeColor: Colors.blue, // สีน้ำเงินสำหรับเวลาที่จะเริ่ม
)
```

## ข้อดีของการแยก Widget

1. **ลดการซ้ำซ้อน**: ไม่ต้องเขียนโค้ดซ้ำในหลายไฟล์
2. **ง่ายต่อการบำรุงรักษา**: แก้ไขที่เดียวใช้ได้ทุกที่
3. **ความสอดคล้อง**: UI เหมือนกันทั้งแอป
4. **การทดสอบ**: ทดสอบ widget แต่ละตัวแยกกันได้
5. **การปรับปรุง**: เพิ่มฟีเจอร์ใหม่ได้ง่าย 