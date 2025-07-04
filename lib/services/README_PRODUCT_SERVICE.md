# ProductService - บริการจัดการข้อมูลสินค้าประมูล

## ภาพรวม
`ProductService` เป็น service class สำหรับเรียก API และจัดการข้อมูลสินค้าประมูลจาก ERP Cloudmate โดยใช้ขั้นตอนการทำงานแบบ 2 ขั้นตอน

## การติดตั้ง
1. ไฟล์หลัก: `lib/services/product_service.dart`
2. ตัวอย่างการใช้งาน: `lib/services/product_service_example.dart`

## ขั้นตอนการทำงาน

### ขั้นตอนที่ 1: เรียกรายการ quotation ทั้งหมด
เรียก API เพื่อดึงรายการ quotation ทั้งหมดจากระบบ

### ขั้นตอนที่ 2: กรองเฉพาะ auction quotations
กรองเฉพาะ quotation ที่มี `quotation_type_code` ขึ้นต้นด้วย "AS" (Auction)

### ขั้นตอนที่ 3: เรียกข้อมูลรายละเอียด
เรียกข้อมูลรายละเอียดของแต่ละ auction quotation ที่ผ่านการกรอง

## การใช้งานพื้นฐาน

### 1. สร้าง ProductService Instance
```dart
import 'package:e_auction/services/product_service.dart';
import 'package:e_auction/views/config/config_prod.dart';

final ProductService productService = ProductService(
  baseUrl: Config.apiUrllocal, // หรือ Config.apiUrl สำหรับ production
);
```

### 2. เรียกรายการ quotation ทั้งหมด
```dart
final quotations = await productService.getAllQuotations();
if (quotations != null) {
  for (var quotation in quotations) {
    print('ID: ${quotation['quotation_id']}');
    print('Type Code: ${quotation['quotation_type_code']}');
    print('Description: ${quotation['description']}');
  }
}
```

### 3. เรียกข้อมูลสินค้าประมูลทั้งหมด (ขั้นตอนใหม่)
```dart
final products = await productService.getAllAuctionProducts();
if (products != null) {
  for (var product in products) {
    final appFormat = productService.convertToAppFormat(product);
    print('สินค้า: ${appFormat['title']}');
    print('ราคา: ${appFormat['currentPrice']} ${appFormat['currency']}');
  }
}
```

### 4. เรียกข้อมูลสินค้าประมูลตามประเภท

#### การประมูลที่กำลังดำเนินการ
```dart
final currentAuctions = await productService.getCurrentAuctions();
```

#### การประมูลที่กำลังจะมาถึง
```dart
final upcomingAuctions = await productService.getUpcomingAuctions();
```

#### การประมูลที่จบแล้ว
```dart
final completedAuctions = await productService.getCompletedAuctions();
```

### 5. เรียกข้อมูลสินค้าประมูลตาม ID
```dart
final product = await productService.getAuctionProductById('46');
if (product != null) {
  final appFormat = productService.convertToAppFormat(product);
  print('ชื่อสินค้า: ${appFormat['title']}');
}
```

## ข้อมูลที่ได้จาก API

### ขั้นตอนที่ 1: รายการ quotation ทั้งหมด
```json
[
    {
        "quotation_id": "36",
        "sequence": "1000058",
        "quotation_type_code": "QT01",
        "description": "ใบเสนอราคา",
        "created_at": null
    },
    {
        "quotation_id": "46",
        "sequence": "1000063",
        "quotation_type_code": "AS01",
        "description": "ใบประมูลราคา",
        "created_at": null
    }
]
```

### ขั้นตอนที่ 2: ข้อมูลรายละเอียด auction
```json
{
    "quotation_id": "46",
    "quotation_type_id": "3",
    "quotation_type_code": "AS01",
    "quotation_type_description": "ใบประมูลราคา",
    "auction_start_date": "2025-06-24 00:00:00",
    "auction_end_date": "2025-07-24 00:00:00",
    "items": [...]
}
```

### โครงสร้างข้อมูลรายการสินค้า
```json
{
    "purchase_order_main_id": "18",
    "short_text": "ปลากระพงทอดน้ำปลา",
    "quantity": "1",
    "tabs": {
        "material_data": {...},
        "quantity_date": {...},
        "valuation": {...},
        "message": {...}
    }
}
```

## การแปลงข้อมูลเป็นรูปแบบแอพ

### ข้อมูลที่ได้จาก convertToAppFormat()
```dart
{
  'id': '46',
  'title': 'ปลากระพงทอดน้ำปลา',
  'currentPrice': 10000.0,
  'startingPrice': 10000.0,
  'timeRemaining': 'เหลือ 30 วัน 5 ชั่วโมง',
  'image': 'assets/images/noimage.jpg',
  'description': 'รายละเอียดสินค้า...',
  'auction_start_date': '2025-06-24 00:00:00',
  'auction_end_date': '2025-07-24 00:00:00',
  'status': 'current', // 'current', 'upcoming', 'completed', 'unknown'
  'currency': 'THB',
  'quantity': 1,
  'manufacturer': 'ผู้ผลิตคลาวเมต',
  'category': 'ใบประมูลราคา'
}
```

## การใช้งานใน Widget

### ตัวอย่างการใช้งานใน StatefulWidget
```dart
class AuctionPage extends StatefulWidget {
  @override
  _AuctionPageState createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  List<Map<String, dynamic>> currentAuctions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuctions();
  }

  Future<void> _loadAuctions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final productService = ProductService(baseUrl: Config.apiUrllocal);
      final current = await productService.getCurrentAuctions();
      
      if (current != null) {
        final formattedAuctions = current.map((auction) {
          return productService.convertToAppFormat(auction);
        }).toList();

        setState(() {
          currentAuctions = formattedAuctions;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('เกิดข้อผิดพลาด: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: currentAuctions.length,
      itemBuilder: (context, index) {
        final auction = currentAuctions[index];
        return ListTile(
          title: Text(auction['title']),
          subtitle: Text('${auction['currentPrice']} ${auction['currency']}'),
          trailing: Text(auction['timeRemaining']),
        );
      },
    );
  }
}
```

## การจัดการข้อผิดพลาด

### ตัวอย่างการจัดการ Error
```dart
try {
  final products = await productService.getAllAuctionProducts();
  if (products != null) {
    // จัดการข้อมูลที่ได้
  } else {
    // แสดงข้อความว่าไม่สามารถดึงข้อมูลได้
  }
} catch (e) {
  print('เกิดข้อผิดพลาด: $e');
  // แสดงข้อความ error ให้ผู้ใช้
}
```

## ฟีเจอร์พิเศษ

### 1. การกรอง Auction Quotations
- กรองเฉพาะ quotation ที่มี `quotation_type_code` ขึ้นต้นด้วย "AS"
- ใช้ method `_filterAuctionQuotations()`

### 2. การคำนวณเวลาที่เหลือ
- คำนวณเวลาที่เหลือจนถึงวันสิ้นสุดการประมูล
- แสดงในรูปแบบ "เหลือ X วัน Y ชั่วโมง" หรือ "เหลือ Y ชั่วโมง Z นาที"

### 3. การกำหนดสถานะการประมูล
- `current`: การประมูลที่กำลังดำเนินการ
- `upcoming`: การประมูลที่กำลังจะมาถึง
- `completed`: การประมูลที่จบแล้ว
- `unknown`: ไม่สามารถกำหนดสถานะได้

### 4. การแปลงข้อมูลที่ปลอดภัย
- ใช้ helper functions (`_safeToString`, `_safeToDouble`, `_safeToInt`)
- ป้องกันการ crash เมื่อข้อมูลเป็น null หรือไม่ถูกต้อง

## การทดสอบ

### ตัวอย่างการทดสอบ API
```dart
// ทดสอบขั้นตอนการทำงานทั้งหมด
await ProductServiceExample.testWorkflow();

// ทดสอบเรียกข้อมูลทั้งหมด
await ProductServiceExample.getAllProducts();

// ทดสอบเรียกข้อมูลการประมูลปัจจุบัน
await ProductServiceExample.getCurrentAuctions();

// ทดสอบเรียกข้อมูลสินค้าตาม ID
await ProductServiceExample.getProductById('46');
```

## หมายเหตุสำคัญ

1. **URL Configuration**: ตรวจสอบ URL ใน `config_prod.dart` ให้ถูกต้อง
2. **API Endpoint**: ใช้ `/ERP-Cloudmate/modules/sales/controllers/list_approve_quotation_controller.php`
3. **Error Handling**: ควรจัดการ error ทุกครั้งที่เรียก API
4. **Loading State**: แสดง loading indicator ขณะดึงข้อมูล (อาจใช้เวลานานเนื่องจากต้องเรียก API หลายครั้ง)
5. **Data Validation**: ตรวจสอบข้อมูลที่ได้จาก API ก่อนใช้งาน
6. **Network Timeout**: ตั้งค่า timeout ที่เหมาะสมสำหรับการเรียก API

## การอัปเดต

หากมีการเปลี่ยนแปลง API หรือโครงสร้างข้อมูล ให้อัปเดต:
1. `getAllQuotations()` method
2. `_filterAuctionQuotations()` method
3. `getAuctionProductById()` method
4. `_parseQuotationList()` method
5. `_parseSingleAuctionProduct()` method
6. `_parseAuctionItem()` method
7. `convertToAppFormat()` method
8. Helper functions ตามความจำเป็น

## ประสิทธิภาพ

### การปรับปรุงประสิทธิภาพ
1. **Caching**: ควรเพิ่มการ cache ข้อมูล quotation list เพื่อลดการเรียก API
2. **Batch Processing**: สำหรับ quotation จำนวนมาก ควรใช้ batch processing
3. **Pagination**: หากมี quotation จำนวนมาก ควรเพิ่ม pagination
4. **Background Processing**: ใช้ background processing สำหรับการดึงข้อมูลรายละเอียด

# Product Service Documentation

## Overview
บริการจัดการข้อมูลสินค้าและการประมูลสำหรับแอป E-Auction

## Services

### 1. ProductService
จัดการข้อมูลสินค้าและการประมูล

### 2. UserBidHistoryService  
จัดการประวัติการประมูลของผู้ใช้

### 3. WinnerService
จัดการข้อมูลผู้ชนะการประมูล

## WinnerService Functions

### Save Winner Information
```dart
// บันทึกข้อมูลผู้ชนะ
Future<Map<String, dynamic>> saveWinnerInfo(Map<String, dynamic> winnerInfo)

// สร้างข้อมูลผู้ชนะจาก form
Map<String, dynamic> createWinnerInfo({
  required String customerId,
  required String fullname,
  required String email,
  required String phone,
  required String addr,
  required String provinceId,
  required String districtId,
  required String subDistrictId,
  required String sub,
  String type = 'individual',
  String companyId = '1',
  String taxNumber = '',
  String name = '',
  String code = '',
})
```

### API Endpoint
- **URL**: `http://192.168.1.39/HR-API-morket/login_phone_auction/save_user.php`
- **Method**: POST
- **Content-Type**: application/json

### Request Body Example
```json
{
  "customer_id": "13",
  "fullname": "สมชาย ใจดี",
  "email": "somchai@example.com",
  "phone": "0616590324",
  "addr": "123 ถนนสุขุมวิท",
  "province_id": "1",
  "district_id": "1001",
  "sub_district_id": "100101",
  "sub": "แขวงคลองเตย",
  "type": "individual",
  "company_id": "1",
  "tax_number": "1234567890123",
  "name": "สมชาย",
  "code": "CUST001"
}
```

### Response Example
```json
{
  "success": true,
  "message": "Customer data updated successfully",
  "data": {
    "id": "13",
    "fullname": "สมชาย ใจดี",
    "email": "somchai@example.com",
    "phone": "616590324",
    "addr": "123 ถนนสุขุมวิท",
    "logo": null,
    "type": "individual",
    "company_id": "1",
    "tax_number": "1234567890123",
    "name": "สมชาย",
    "code": "CUST001",
    "province_id": "1",
    "district_id": "1001",
    "sub_district_id": "100101",
    "sub": "แขวงคลองเตย"
  }
}
```

### Usage Example
```dart
// สร้างข้อมูลผู้ชนะ
final winnerInfo = WinnerService.createWinnerInfo(
  customerId: '13',
  fullname: 'สมชาย ใจดี',
  email: 'somchai@example.com',
  phone: '061-659-0324', // จะถูกทำความสะอาดเป็น '0616590324'
  addr: '123 ถนนสุขุมวิท',
  provinceId: '1',
  districtId: '1001',
  subDistrictId: '100101',
  sub: 'แขวงคลองเตย',
  taxNumber: '1234567890123',
);

// บันทึกข้อมูล
final result = await WinnerService.saveWinnerInfo(winnerInfo);

if (result['success'] == true) {
  print('บันทึกข้อมูลสำเร็จ: ${result['data']}');
} else {
  print('บันทึกข้อมูลล้มเหลว: ${result['message']}');
}
```

### Phone Number Cleaning
ระบบจะทำความสะอาดเบอร์โทรศัพท์โดยอัตโนมัติ:
- ลบเครื่องหมาย `-`, `(`, `)`, ` ` (space)
- เหลือเฉพาะตัวเลข
- ตัวอย่าง: `061-659-0324` → `0616590324`

## Other WinnerService Functions

### Get Winner Data
```dart
// ดึงข้อมูลผู้ชนะตาม auction ID
Future<Map<String, dynamic>> getWinnerByAuctionId(String auctionId)

// ดึงข้อมูลผู้ชนะตาม user ID
Future<Map<String, dynamic>> getWinnersByUserId(String userId)

// ดึงข้อมูลผู้ชนะทั้งหมด
Future<Map<String, dynamic>> getAllWinners()
```

### Announce Winner
```dart
// ประกาศผู้ชนะ
Future<Map<String, dynamic>> announceWinner(String auctionId, String userId)

// Trigger ประกาศผู้ชนะโดยตรง
Future<Map<String, dynamic>> triggerAnnounceWinner(String auctionId, String userId)

// เช็คและประกาศผู้ชนะอัตโนมัติ
Future<void> checkAndAnnounceWinner(String auctionId, String userId)
```

### Check Winner Status
```dart
// ตรวจสอบว่าประกาศผู้ชนะแล้วหรือยัง
Future<bool> isWinnerAnnounced(String quotationMoreInformationId)

// ดึงข้อมูลผู้ชนะ
Future<Map<String, dynamic>?> getWinnerData(String quotationMoreInformationId)
```

### Get Announcement Logs
```dart
// ดึง log การประกาศผู้ชนะ
Future<List<dynamic>> getAnnouncementLogs({
  String? quotationMoreInformationId,
  String? announcedBy,
  String? status,
  String? dateFrom,
  String? dateTo,
})
```

## Data Conversion

### Convert Winners to App Format
```dart
// แปลงข้อมูลผู้ชนะเป็นรูปแบบที่ใช้ในแอป
List<Map<String, dynamic>> convertWinnersToAppFormat(List<dynamic> winners)
```

### Filter User Winners
```dart
// กรองเฉพาะผู้ชนะของผู้ใช้
List<Map<String, dynamic>> filterUserWinners(List<Map<String, dynamic>> allWinners, String userId)

// ตรวจสอบว่าผู้ใช้เป็นผู้ชนะหรือไม่
bool isUserWinner(Map<String, dynamic> winner, String userId)
```

## Error Handling
- ทุกฟังก์ชันมีการ handle error และแสดง debug logs
- ใช้ try-catch เพื่อจัดการ exceptions
- ส่งกลับ error messages ที่ชัดเจน

## Debug Logs
ระบบจะแสดง debug logs ต่อไปนี้:
- `💾 SAVE`: การบันทึกข้อมูลผู้ชนะ
- `🚀 ANNOUNCE`: การประกาศผู้ชนะ
- `🔍 CHECK`: การตรวจสอบสถานะ
- `📊 WINNER`: การดึงข้อมูลผู้ชนะ
- `📋 LOGS`: การดึง log
- `❌ ERROR`: ข้อผิดพลาดต่างๆ