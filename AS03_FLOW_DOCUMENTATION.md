# Flow การทำงานของระบบประมูลแบบลดจำนวน (AS03 - Quantity Reduction Auction)

## 📋 สารบัญ
1. [ภาพรวมระบบ](#ภาพรวมระบบ)
2. [Flow การสร้างประมูล AS03](#flow-การสร้างประมูล-as03)
3. [Flow การแสดงรายการประมูล](#flow-การแสดงรายการประมูล)
4. [Flow การดูรายละเอียดประมูล](#flow-การดูรายละเอียดประมูล)
5. [Flow การจองสินค้า](#flow-การจองสินค้า)
6. [Flow การสิ้นสุดการประมูล](#flow-การสิ้นสุดการประมูล)
7. [Key Points](#key-points)

---

## 🎯 ภาพรวมระบบ

ระบบประมูลแบบลดจำนวน (AS03) เป็นระบบการขายสินค้าแบบเหมา โดย:
- **ไม่มีการประมูลราคาขึ้นลง** แต่เป็นการจองสินค้าตามจำนวนที่ต้องการ
- **ราคาเดียว** (ราคาเหมา) ตลอดการประมูล
- **จองได้หลายครั้ง** โดยผู้ใช้คนเดียวกันสามารถจองได้หลายครั้ง
- **สิ้นสุดเมื่อ** จำนวนสินค้าครบตาม `max_quantity_available` หรือหมดเวลา

---

## 📝 Flow การสร้างประมูล AS03

### 1. เริ่มต้น → กรอกข้อมูลประมูล

ผู้ขายกรอกข้อมูลใน Add Auction Page:
- เลือก **Quotation Type: AS03** (การซื้อสินค้าตามจำนวนที่ต้องการ)
- กรอกข้อมูลสินค้า:
  - ชื่อสินค้า (product_name)
  - รายละเอียด (description)
  - **จำนวนสินค้าทั้งหมด** (max_quantity_available) ⭐
  - **ราคาเหมา** (starting_price) ⭐
- เลือกวันที่เริ่มต้นและสิ้นสุด
- อัปโหลดรูปภาพ (หลายรูป)
- กดบันทึก

### 2. ตรวจสอบข้อมูล (validateAuctionData)

**File:** `lib/services/add_auction_service/add_auction_service.dart`

ตรวจสอบว่า:
- ✅ `product_name` ไม่ว่าง
- ✅ `description` ไม่ว่าง
- ✅ `starting_price` > 0 (สำหรับ AS03 = ราคาเหมา)
- ✅ `max_quantity_available` > 0 (จำนวนสินค้าทั้งหมด) ⭐
- ✅ `start_date` และ `end_date` ไม่ว่าง
- ✅ `purchase_order_type_id` ไม่ว่าง

**ถ้าไม่ผ่าน:** กลับไปกรอกข้อมูลใหม่

**ถ้าผ่าน:** ไปขั้นตอนถัดไป

### 3. จัดรูปแบบข้อมูล (formatAuctionDataForAPI)

**File:** `lib/services/add_auction_service/add_auction_service.dart`

จัดรูปแบบข้อมูลให้พร้อมส่งไป Server:
- แปลงราคาเป็น `int` (ไม่ใช่ string)
- ตั้งค่า `min_increment = 1` (สำหรับ AS03, API ต้องการ > 0)
- เพิ่ม `quotation_type_code: 'AS03'`
- จัดรูปแบบวันที่
- จัดเตรียมรูปภาพ

### 4. บันทึกประมูล (ส่งข้อมูลไป Server)

- ส่งข้อมูลไป Server ผ่าน API
- ใช้ `MultipartRequest` เพื่อส่ง JSON + รูปภาพ
- ส่ง `max_quantity_available` ทั้งใน JSON `data` และเป็น separate field

### 5. แสดงผลสำเร็จ

- แสดงข้อความ "สร้างประมูลสำเร็จ"
- กลับไปหน้า Home หรือรายการประมูล

---

## 📱 Flow การแสดงรายการประมูล

### 1. เปิดหน้า Home / Quantity Reduction Auctions Page

**File:** `lib/views/first_page/home_screen.dart`
**File:** `lib/views/first_page/auction_page/quantity_reduction_auctions_page.dart`

### 2. โหลดข้อมูลประมูล AS03

- เรียก API เพื่อดึงข้อมูลประมูลทั้งหมด
- กรองเฉพาะ AS03 (`quotation_type_code == 'AS03'`)

### 3. กรองรายการ

แสดงตาม Filter ที่เลือก:
- **all:** แสดงทั้งหมด
- **current:** กำลังประมูล (ยังไม่ครบจำนวน + ยังไม่หมดเวลา)
- **upcoming:** ยังไม่เริ่ม (ยังไม่ถึงวันเริ่มต้น + ยังไม่ครบจำนวน)
- **completed:** สิ้นสุดแล้ว (ครบจำนวน หรือ หมดเวลาและครบจำนวน)

**เงื่อนไขพิเศษ:**
- ✅ **แสดง:** ถ้าครบจำนวน (`current_quantity_sold >= max_quantity_available`)
- ✅ **แสดง:** ถ้ากำลังประมูลและยังไม่ครบจำนวน
- ❌ **ซ่อน:** ถ้าหมดเวลาก่อนครบจำนวน (`isTimeExpired && !isQuantityFull`)

### 4. แสดงรายการประมูล

**File:** `lib/views/first_page/widget_home_cm/current_auction_card.dart`

แต่ละ Card แสดง:
- รูปภาพสินค้า
- ชื่อสินค้า
- **ราคาต่อชิ้น** (ไม่ใช่ "ราคาเริ่มต้น")
- จำนวนคงเหลือ: `max_quantity_available - current_quantity_sold`
- สี **เขียว** สำหรับ AS03

### 5. กดที่ประมูล

- ไปหน้า Detail Page เพื่อดูรายละเอียด

---

## 🔍 Flow การดูรายละเอียดประมูล

### 1. เปิดหน้า Detail

**File:** `lib/views/first_page/auction_page/quantity_reduction_auction_detail_page.dart`

เมื่อเปิดหน้า:
- `initState()` ทำงาน
- `_parseImages()` - Parse รูปภาพหลายรูป
- `_checkIfUserHasJoined()` - ตรวจสอบว่าผู้ใช้จองแล้วหรือยัง
- `_loadLatestData()` - โหลดข้อมูลล่าสุด

### 2. โหลดข้อมูลล่าสุด

- เรียก API เพื่อดึงข้อมูลประมูลล่าสุด
- เรียก API เพื่อดึง Bid History (ผู้จองล่าสุด)
- อัปเดตข้อมูลในหน้า

### 3. แสดงรายละเอียด

แสดงข้อมูล:
- **รูปภาพ:** แสดงหลายรูปพร้อม thumbnail gallery (กดเพื่อดู fullscreen)
- **ข้อมูลสินค้า:** ชื่อ, รายละเอียด
- **ราคาเหมา:** ราคาต่อชิ้น (ไม่เปลี่ยนแปลง)
- **จำนวนคงเหลือ:** `max_quantity_available - current_quantity_sold`
- **ผู้จองล่าสุด:** แสดง 5 คนล่าสุด (เรียงตาม `bid_time` DESC)
  - Format เบอร์โทร: `0XX-XXX-XXXX` (ปิด 4 ตัวท้ายด้วย XXXX)
- **สถานะ:** 
  - กำลังประมูล
  - สิ้นสุดการประมูล (พร้อมเหตุผล)

### 4. กดปุ่ม "เข้าร่วมการจอง"

- ไป Flow การจองสินค้า

---

## 🛒 Flow การจองสินค้า

### 1. แสดง Dialog (_showBookingDialog)

**File:** `lib/views/first_page/auction_page/quantity_reduction_auction_detail_page.dart`

Dialog แสดง:
- **จำนวนคงเหลือ:** X รายการ
- **Input:** จำนวนที่จะจอง (1 - X)
- **ปุ่ม:** "เข้าร่วมการจอง (เหลือ X รายการ)" หรือ "จองเพิ่ม" (ถ้าจองไปแล้ว)

### 2. กรอกจำนวน + ยืนยัน

ผู้ใช้กรอกจำนวนที่ต้องการจอง

### 3. ตรวจสอบ

ตรวจสอบว่า:
- ✅ จำนวน > 0
- ✅ จำนวน <= จำนวนคงเหลือ

**ถ้าไม่ผ่าน:** แสดงข้อความแจ้งเตือน, กลับไป Dialog

**ถ้าผ่าน:** ไปขั้นตอนถัดไป

### 4. จองสินค้า (_joinAuction)

- ดึงข้อมูลจาก SharedPreferences:
  - `userId` (key: 'id')
  - `phoneNumber` (key: 'phone_number') ⭐ **สำคัญ: ใช้ 'phone_number' ไม่ใช่ 'phone'**
- ส่งข้อมูลไป Server:
  - `bidder_id`: userId
  - `bidder_name`: phoneNumber (เบอร์โทรศัพท์)
  - `bid_amount`: current_price (ราคาปัจจุบัน)
  - `quantity_requested`: จำนวนที่จอง

### 5. สำเร็จ → เริ่ม Countdown 15 วินาที

หลังจองสำเร็จ:
- เริ่ม Timer นับถอยหลัง 15 วินาที
- แสดง UI:
  - "ยกเลิกได้ใน X วินาที"
  - ปุ่ม "ยกเลิกการจอง" (สามารถยกเลิกได้ภายใน 15 วินาที)

### 6. หลัง 15 วินาทีผ่าน

- `_isCountdownActive = false`
- `_loadLatestData()` - โหลดข้อมูลใหม่
- แสดง UI:
  - "คุณจองแล้ว: X รายการ"
  - ปุ่ม "จองเพิ่ม (จองแล้ว X รายการ)" (ไม่ disable)

### 7. จองเพิ่ม?

**ถ้าต้องการจองเพิ่ม:**
- กดปุ่ม "จองเพิ่ม"
- กลับไป Flow ข้อ 1 (แสดง Dialog)

**ถ้าไม่ต้องการ:**
- เสร็จสิ้น

**หมายเหตุ:** ผู้ใช้สามารถจองได้หลายครั้ง ไม่มี limit ต่อคน

---

## 🏁 Flow การสิ้นสุดการประมูล

### 1. ตรวจสอบเงื่อนไข (_isAuctionEnded)

**File:** `lib/views/first_page/auction_page/quantity_reduction_auction_detail_page.dart`

ตรวจสอบว่า:
- **ครบจำนวน:** `current_quantity_sold >= max_quantity_available`
- **หมดเวลา:** `now.isAfter(endDate)`

### 2. แสดงสถานะ

**ถ้าครบจำนวน:**
- แสดง "สิ้นสุดการประมูล"
- เหตุผล: "สินค้าครบจำนวนแล้ว"
- ปุ่ม "สิ้นสุดการประมูล" (disabled)

**ถ้าหมดเวลา:**
- แสดง "สิ้นสุดการประมูล"
- เหตุผล: "หมดเวลาการประมูลแล้ว"
- ปุ่ม "สิ้นสุดการประมูล" (disabled)

**ถ้ายังไม่สิ้นสุด:**
- ยังประมูลต่อได้

### 3. การซ่อนจากรายการ

**File:** `lib/views/first_page/home_screen.dart`
**File:** `lib/views/first_page/auction_page/quantity_reduction_auctions_page.dart`

**เงื่อนไขการซ่อน:**
- ถ้าหมดเวลาก่อนครบจำนวน (`isTimeExpired && !isQuantityFull`)
  - **ซ่อนจากรายการ** (ไม่แสดงใน filter ใดๆ)

**เงื่อนไขการแสดง:**
- ถ้าครบจำนวน → แสดงใน "completed"
- ถ้าหมดเวลาและครบจำนวน → แสดงใน "completed"
- ถ้ากำลังประมูลและยังไม่ครบ → แสดงใน "current"

---

## 🔑 Key Points

### ⭐ สิ่งสำคัญที่ต้องจำ

1. **max_quantity_available:**
   - เก็บจำนวนสินค้าทั้งหมด
   - ส่งไป Server ทั้งใน JSON `data` และเป็น separate field
   - ต้องเป็น `int` ไม่ใช่ `string`

2. **bidder_name:**
   - ใช้เบอร์โทรศัพท์จาก `SharedPreferences['phone_number']`
   - **ไม่ใช่** `SharedPreferences['phone']` ❌

3. **min_increment:**
   - สำหรับ AS03 = 1 (Server ต้องการ > 0)
   - ไม่ใช่ 0

4. **ราคา:**
   - `starting_price` = ราคาเหมา (ไม่เปลี่ยนแปลง)
   - ไม่มีการคำนวณยอดรวมเพิ่ม (ใช้ราคาเดียว)

5. **การจอง:**
   - ผู้ใช้สามารถจองได้หลายครั้ง
   - ไม่มี limit ต่อคน
   - มี countdown 15 วินาทีหลังจอง (สามารถยกเลิกได้)

6. **การสิ้นสุด:**
   - ครบจำนวน: `current_quantity_sold >= max_quantity_available`
   - หมดเวลา: `now.isAfter(endDate)`
   - ถ้าหมดเวลาก่อนครบจำนวน = ซ่อนจากรายการ

7. **รูปภาพ:**
   - รองรับหลายรูป
   - มี thumbnail gallery
   - กดเพื่อดู fullscreen (swipe, zoom)

8. **การอัปเดตข้อมูล:**
   - ไม่มี real-time updates
   - อัปเดตเมื่อเข้าหน้าหรือกด refresh
   - แสดงผู้จองล่าสุด 5 คน (เรียงตาม `bid_time` DESC)

---

## 📊 สถานะการประมูล

### กำลังประมูล
- ยังไม่ครบจำนวน (`current_quantity_sold < max_quantity_available`)
- ยังไม่หมดเวลา (`now < endDate`)

### สิ้นสุดแล้ว
- ครบจำนวน (`current_quantity_sold >= max_quantity_available`) **หรือ**
- หมดเวลา (`now >= endDate`)

### ซ่อนจากรายการ
- หมดเวลาก่อนครบจำนวน (`isTimeExpired && !isQuantityFull`)

---

## 📝 Notes

- **Real-time Updates:** ไม่มี (อัปเดตเมื่อเข้าหน้าหรือกด refresh)
- **Image Gallery:** รองรับหลายรูป พร้อม thumbnail และ fullscreen viewer
- **Phone Format:** แสดงเป็น `0XX-XXX-XXXX` (ปิด 4 ตัวท้ายด้วย XXXX)
- **Countdown:** 15 วินาทีหลังจอง (สามารถยกเลิกได้)

---

**Last Updated:** 2026-01-07  
**Version:** 1.0
