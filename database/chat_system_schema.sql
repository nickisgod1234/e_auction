-- Chat System Database Schema
-- สำหรับระบบแชทระหว่าง User และ Admin

-- ตารางเก็บข้อมูลการสนทนา (Chat Sessions)
CREATE TABLE chat_sessions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    phone_id VARCHAR(20) NOT NULL, -- หมายเลขโทรศัพท์ของผู้ใช้
    admin_id INT DEFAULT NULL, -- ID ของ admin (NULL ถ้ายังไม่มี admin รับผิดชอบ)
    status ENUM('active', 'closed', 'pending') DEFAULT 'pending', -- สถานะการสนทนา
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_phone_id (phone_id),
    INDEX idx_admin_id (admin_id),
    INDEX idx_status (status),
    INDEX idx_last_message_at (last_message_at)
);

-- ตารางเก็บข้อความในแต่ละการสนทนา
CREATE TABLE chat_messages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    session_id INT NOT NULL, -- รหัสการสนทนา
    sender_type ENUM('user', 'admin') NOT NULL, -- ประเภทผู้ส่ง (user หรือ admin)
    sender_id VARCHAR(20) NOT NULL, -- ID ของผู้ส่ง (phone_id หรือ admin_id)
    message TEXT NOT NULL, -- ข้อความ
    message_type ENUM('text', 'image', 'file') DEFAULT 'text', -- ประเภทข้อความ
    is_read BOOLEAN DEFAULT FALSE, -- สถานะการอ่าน
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE,
    INDEX idx_session_id (session_id),
    INDEX idx_sender_type (sender_type),
    INDEX idx_sender_id (sender_id),
    INDEX idx_created_at (created_at),
    INDEX idx_is_read (is_read)
);

-- ตารางเก็บข้อมูล Admin
CREATE TABLE chat_admins (
    id INT PRIMARY KEY AUTO_INCREMENT,
    admin_name VARCHAR(100) NOT NULL, -- ชื่อ admin
    admin_email VARCHAR(100) UNIQUE NOT NULL, -- อีเมล admin
    is_active BOOLEAN DEFAULT TRUE, -- สถานะการใช้งาน
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_admin_email (admin_email),
    INDEX idx_is_active (is_active)
);

-- ตารางเก็บการแจ้งเตือน (Notifications)
CREATE TABLE chat_notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    session_id INT NOT NULL,
    recipient_type ENUM('user', 'admin') NOT NULL,
    recipient_id VARCHAR(20) NOT NULL, -- phone_id หรือ admin_id
    notification_type ENUM('new_message', 'session_assigned', 'session_closed') NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE,
    INDEX idx_session_id (session_id),
    INDEX idx_recipient_type (recipient_type),
    INDEX idx_recipient_id (recipient_id),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
);

-- ตารางเก็บไฟล์ที่แนบในแชท
CREATE TABLE chat_attachments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    message_id INT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT NOT NULL, -- ขนาดไฟล์เป็น bytes
    file_type VARCHAR(100) NOT NULL, -- MIME type
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (message_id) REFERENCES chat_messages(id) ON DELETE CASCADE,
    INDEX idx_message_id (message_id),
    INDEX idx_file_type (file_type)
);

-- ตารางเก็บสถิติการสนทนา
CREATE TABLE chat_statistics (
    id INT PRIMARY KEY AUTO_INCREMENT,
    date DATE NOT NULL,
    total_sessions INT DEFAULT 0,
    active_sessions INT DEFAULT 0,
    closed_sessions INT DEFAULT 0,
    total_messages INT DEFAULT 0,
    avg_response_time INT DEFAULT 0, -- เวลาเฉลี่ยในการตอบกลับ (วินาที)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_date (date),
    INDEX idx_date (date)
);

-- Insert default admin data
INSERT INTO chat_admins (admin_name, admin_email, is_active) VALUES
('เจ้าหน้าที่บริการลูกค้า', 'support@e-auction.com', TRUE),
('Admin 1', 'admin1@e-auction.com', TRUE),
('Admin 2', 'admin2@e-auction.com', TRUE);
