# Flutter API Documentation - create_flutter_auction

## ✅ API พร้อมใช้งานแล้ว!

API endpoint `create_flutter_auction` ทำงานได้เรียบร้อยแล้ว และพร้อมรับ request จาก Flutter app

---

## 📍 Endpoint

```
POST http://www.cm-mecustomers.com/ERP-Cloudmate/modules/sales/controllers/quotation_controller.php?action=create_flutter_auction
```

---

## 📋 Request Format

### Content-Type

```
multipart/form-data
```

### Required Fields

| Field Name | Type | Description | Example |
|------------|------|-------------|---------|
| `data` | String (JSON) | JSON string ที่มีข้อมูลการประมูล | ดูตัวอย่างด้านล่าง |
| `images[]` | File (Optional) | รูปภาพสินค้า (สูงสุด 5 รูป) | JPG, PNG, GIF, WEBP |

### Field: `data` (JSON String)

```json
{
  "product_name": "ชื่อสินค้า",
  "description": "รายละเอียดสินค้า",
  "customer_id": 26,
  "notes": "หมายเหตุ",
  "starting_price": "200",
  "min_increment": "40",
  "start_date": "2026-01-05",
  "end_date": "2026-01-06",
  "purchase_order_type_id": "3",
  "sourcing": true,
  "created_by": 2,
  "vendor_id": 8
}
```

**Required Fields ใน JSON:**

- `product_name` (string)
- `starting_price` (string/number)
- `min_increment` (string/number)
- `start_date` (string, format: YYYY-MM-DD)
- `end_date` (string, format: YYYY-MM-DD)
- `purchase_order_type_id` (string/number)
- `created_by` (number)
- `vendor_id` (number)

**Optional Fields:**

- `description` (string)
- `customer_id` (number)
- `notes` (string)
- `sourcing` (boolean, default: true)

---

## 📤 Success Response (201)

```json
{
  "status": "success",
  "message": "Auction created successfully",
  "data": {
    "quotation_id": "312",
    "product_name": "ทดสอบ",
    "images": [
      "auction_695b29089d07c3.36828976_1767581960.png",
      "auction_695b29089db9e7.49373662_1767581960.jpg"
    ]
  }
}
```

---

## ❌ Error Response (500)

```json
{
  "status": "error",
  "message": "Error message here",
  "error_code": "INTERNAL_ERROR",
  "file": "/path/to/file.php",
  "line": 123
}
```

---

## 💻 Flutter Implementation

โค้ด Flutter ถูก implement ใน `lib/services/add_auction_service/add_auction_service.dart`

### การใช้งาน

```dart
import 'package:e_auction/services/add_auction_service/add_auction_service.dart';
import 'dart:io';

// Format data
final auctionData = await AddAuctionService.formatAuctionDataForAPI({
  'product_name': 'ทดสอบ',
  'description': 'ทดสอบ1',
  'notes': 'ยังไม่มี | ส่งราคาเหมา: ฿50',
  'starting_price': 200.0,
  'min_increment': 40.0,
  'start_date': '2026-01-05',
  'end_date': '2026-01-06',
  'purchase_order_type_id': '3',
});

// Save auction
final result = await AddAuctionService.saveAuction(
  auctionData: auctionData,
  imageFiles: [File('/path/to/image1.png'), File('/path/to/image2.jpg')],
);

if (result['status'] == 'success') {
  print('Success! Quotation ID: ${result['data']['quotation_id']}');
}
```

---

## 📝 ข้อกำหนดสำคัญ

### 1. JSON String ใน Field `data`

- ต้องเป็น **JSON string** (ไม่ใช่ JSON object)
- ใช้ `jsonEncode()` เพื่อแปลง Map เป็น JSON string

### 2. Field Name สำหรับรูปภาพ

- ต้องใช้ `images[]` (มี `[]` ด้วย)
- สามารถส่งหลายไฟล์ได้ (สูงสุด 5 ไฟล์)

### 3. รูปแบบวันที่

- Format: `YYYY-MM-DD` (เช่น `2026-01-05`)
- ใช้ `toIso8601String().split('T')[0]` เพื่อแปลง DateTime

### 4. ประเภทไฟล์รูปภาพ

- รองรับ: JPG, JPEG, PNG, GIF, WEBP
- ตรวจสอบ MIME type และ file extension

### 5. จำนวนรูปภาพ

- สูงสุด 5 รูป
- ถ้าเกินจะได้รับ error

---

## 🔍 Validation Rules

### Required Fields

- `product_name`: ไม่ว่าง
- `starting_price`: มากกว่า 0
- `min_increment`: มากกว่า 0
- `start_date`: รูปแบบถูกต้อง (YYYY-MM-DD)
- `end_date`: รูปแบบถูกต้อง และต้องหลัง start_date
- `purchase_order_type_id`: ต้องมีอยู่ในระบบ
- `created_by`: ต้องเป็น number
- `vendor_id`: ต้องเป็น number

### Date Validation

- `end_date` ต้องหลัง `start_date`
- Format ต้องเป็น `YYYY-MM-DD`

### Price Validation

- `starting_price` ต้องมากกว่า 0
- `min_increment` ต้องมากกว่า 0

---

## 🐛 Error Handling

### Common Errors

1. **Missing data field**
   ```json
   {
     "status": "error",
     "message": "Missing data field"
   }
   ```

2. **Invalid JSON**
   ```json
   {
     "status": "error",
     "message": "Invalid JSON: ..."
   }
   ```

3. **Missing required field**
   ```json
   {
     "status": "error",
     "message": "Missing or empty required field: product_name"
   }
   ```

4. **Invalid date format**
   ```json
   {
     "status": "error",
     "message": "Invalid date format. Expected format: YYYY-MM-DD"
   }
   ```

5. **Too many images**
   ```json
   {
     "status": "error",
     "message": "Cannot upload more than 5 images. You tried to upload 6 images."
   }
   ```

---

## ✅ Testing

API ได้รับการทดสอบแล้วและทำงานได้เรียบร้อย:

- ✅ สร้าง auction สำเร็จ
- ✅ อัปโหลดรูปภาพได้ (หลายไฟล์)
- ✅ Validation ทำงานถูกต้อง
- ✅ Error handling ครบถ้วน

---

## 📞 Support

หากพบปัญหาหรือมีคำถาม:

1. ตรวจสอบ error message ใน response
2. ตรวจสอบ PHP error logs
3. ตรวจสอบว่า JSON string ถูกต้อง
4. ตรวจสอบว่า field names ถูกต้อง (`data` และ `images[]`)

---

**Last Updated**: 2026-01-05  
**Status**: ✅ Ready for Production

