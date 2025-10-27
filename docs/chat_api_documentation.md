# Chat System API Documentation

## Overview
ระบบแชทระหว่าง User และ Admin โดยแยกตาม phone_id และรองรับการแชทแบบ real-time

## Database Schema
- **chat_sessions**: เก็บข้อมูลการสนทนาแต่ละครั้ง (เชื่อมต่อกับ tb_customers)
- **chat_messages**: เก็บข้อความทั้งหมด (sender_id เชื่อมต่อกับ tb_customers)
- **chat_admins**: เก็บข้อมูล admin (customer_id เชื่อมต่อกับ tb_customers)
- **chat_notifications**: เก็บการแจ้งเตือน (recipient_id เชื่อมต่อกับ tb_customers)
- **chat_attachments**: เก็บไฟล์แนบ
- **chat_statistics**: เก็บสถิติการสนทนา

## API Endpoints

### 1. สร้างหรือดึงข้อมูลการสนทนา
```
POST /api/chat/sessions
Content-Type: application/json

{
  "customer_id": 123  // ID ของลูกค้าจาก tb_customers (จาก SharedPreferences 'id')
}

Response:
{
  "success": true,
  "message": "Session created/retrieved successfully",
  "data": {
    "id": 1,
    "customer_id": 123,
    "admin_id": null,
    "status": "pending",
    "created_at": "2024-01-01T10:00:00Z",
    "updated_at": "2024-01-01T10:00:00Z",
    "last_message_at": "2024-01-01T10:00:00Z"
  }
}
```

### 2. ส่งข้อความ
```
POST /api/chat/messages
Content-Type: application/json

{
  "session_id": 1,
  "sender_type": "customer",
  "sender_id": 123,  // ID ของผู้ส่งจาก tb_customers
  "message": "สวัสดีครับ",
  "message_type": "text"
}

Response:
{
  "success": true,
  "message": "Message sent successfully",
  "data": {
    "id": 1,
    "session_id": 1,
    "sender_type": "customer",
    "sender_id": 123,
    "message": "สวัสดีครับ",
    "message_type": "text",
    "is_read": false,
    "created_at": "2024-01-01T10:00:00Z"
  }
}
```

### 3. ดึงข้อความทั้งหมด
```
GET /api/chat/sessions/{session_id}/messages?page=1&limit=50

Response:
{
  "success": true,
  "message": "Messages retrieved successfully",
  "data": {
    "messages": [
      {
        "id": 1,
        "session_id": 1,
        "sender_type": "customer",
        "sender_id": 123,
        "message": "สวัสดีครับ",
        "message_type": "text",
        "is_read": true,
        "created_at": "2024-01-01T10:00:00Z"
      }
    ],
    "has_more": false,
    "total_count": 1
  }
}
```

### 4. ตรวจสอบข้อความใหม่
```
GET /api/chat/sessions/{session_id}/new-messages?since=2024-01-01T10:00:00Z

Response:
{
  "success": true,
  "message": "New messages retrieved successfully",
  "data": [
    {
      "id": 2,
      "session_id": 1,
      "sender_type": "admin",
      "sender_id": 26,
      "message": "สวัสดีครับ ยินดีให้บริการครับ",
      "message_type": "text",
      "is_read": false,
      "created_at": "2024-01-01T10:05:00Z"
    }
  ]
}
```

### 5. อัปเดตสถานะการอ่าน
```
PUT /api/chat/sessions/{session_id}/mark-read
Content-Type: application/json

{
  "recipient_type": "customer",
  "recipient_id": 123
}

Response:
{
  "success": true,
  "message": "Messages marked as read",
  "data": true
}
```

### 6. ดึงข้อมูล Admin
```
GET /api/chat/sessions/{session_id}/admin

Response:
{
  "success": true,
  "message": "Admin retrieved successfully",
  "data": {
    "id": 1,
    "customer_id": 26,
    "is_active": true,
    "created_at": "2024-01-01T09:00:00Z",
    "updated_at": "2024-01-01T09:00:00Z",
    "customer_info": {
      "id": 26,
      "name": "เจ้าหน้าที่บริการลูกค้า",
      "email": "support@e-auction.com",
      "phone": "0812345678"
    }
  }
}
```

### 7. ดึงการแจ้งเตือน
```
GET /api/chat/notifications?customer_id=123&page=1&limit=20

Response:
{
  "success": true,
  "message": "Notifications retrieved successfully",
  "data": [
    {
      "id": 1,
      "session_id": 1,
      "recipient_type": "customer",
      "recipient_id": 123,
      "notification_type": "new_message",
      "title": "ข้อความใหม่",
      "message": "คุณมีข้อความใหม่จากเจ้าหน้าที่",
      "is_read": false,
      "created_at": "2024-01-01T10:05:00Z"
    }
  ]
}
```

### 8. ปิดการสนทนา
```
PUT /api/chat/sessions/{session_id}/close

Response:
{
  "success": true,
  "message": "Session closed successfully",
  "data": true
}
```

### 9. อัปโหลดไฟล์แนบ
```
POST /api/chat/attachments
Content-Type: multipart/form-data

Fields:
- message_id: 1
- file_name: "image.jpg"
- file_size: 1024000
- file_type: "image/jpeg"
- file: [binary data]

Response:
{
  "success": true,
  "message": "File uploaded successfully",
  "data": {
    "id": 1,
    "message_id": 1,
    "file_name": "image.jpg",
    "file_path": "/uploads/chat/2024/01/01/image_123456.jpg",
    "file_size": 1024000,
    "file_type": "image/jpeg",
    "created_at": "2024-01-01T10:00:00Z"
  }
}
```

## Business Logic

### User Flow
1. User เข้าสู่หน้าแชท → ดึง `id` จาก SharedPreferences (ที่บันทึกจากการล็อกอิน)
2. User ส่งข้อความ → บันทึกในฐานข้อมูลด้วย `customer_id` = `id` จาก SharedPreferences
3. Admin (id=26) ตอบกลับ → User ได้รับข้อความใหม่ผ่าน polling
4. User อ่านข้อความ → อัปเดตสถานะการอ่าน

### Admin Flow
1. Admin (id=26) เข้าสู่ระบบ → เห็นรายการ session ที่รอการตอบกลับ
2. Admin เลือก session → รับผิดชอบการสนทนา (admin_id = 26)
3. Admin ตอบกลับ → User ได้รับข้อความใหม่
4. Admin ปิด session → จบการสนทนา

### Session Management
- **pending**: รอการตอบกลับจาก admin
- **active**: admin รับผิดชอบแล้ว
- **closed**: ปิดการสนทนาแล้ว

### Message Types
- **text**: ข้อความธรรมดา
- **image**: รูปภาพ
- **file**: ไฟล์อื่นๆ

## Security Considerations
1. ตรวจสอบ customer_id (id จาก SharedPreferences) ว่าถูกต้อง
2. ตรวจสอบสิทธิ์การเข้าถึง session
3. จำกัดขนาดไฟล์แนบ
4. ตรวจสอบ MIME type ของไฟล์
5. Rate limiting สำหรับการส่งข้อความ
6. Admin id=26 เท่านั้นที่สามารถตอบแชทได้

## Performance Optimization
1. ใช้ pagination สำหรับข้อความ
2. ใช้ polling ทุก 5 วินาทีสำหรับข้อความใหม่
3. Index ในฐานข้อมูลสำหรับการค้นหาที่เร็ว
4. Cache ข้อมูล admin และ session
5. Compress ไฟล์รูปภาพก่อนอัปโหลด

## Error Handling
- HTTP 400: Bad Request (ข้อมูลไม่ถูกต้อง)
- HTTP 401: Unauthorized (ไม่ได้รับอนุญาต)
- HTTP 404: Not Found (ไม่พบข้อมูล)
- HTTP 500: Internal Server Error (ข้อผิดพลาดของเซิร์ฟเวอร์)

## Testing
- Unit tests สำหรับ business logic
- Integration tests สำหรับ API endpoints
- Load testing สำหรับ performance
- Security testing สำหรับ vulnerabilities
