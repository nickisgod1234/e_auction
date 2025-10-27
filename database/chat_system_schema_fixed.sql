-- Chat System Database Schema
-- สำหรับระบบแชทระหว่าง User และ Admin
-- เชื่อมต่อกับ tb_customers ใน schema cm_hrm
-- สำหรับ PostgreSQL Database

-- ตารางเก็บข้อมูลการสนทนา (Chat Sessions)
CREATE TABLE cm_hrm.chat_sessions (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL, -- ID ของลูกค้าจาก tb_customers (Foreign Key)
    admin_id INT DEFAULT NULL, -- ID ของ admin จาก tb_customers (Foreign Key)
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('active', 'closed', 'pending')), -- สถานะการสนทนา
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES cm_hrm.tb_customers(id) ON DELETE CASCADE,
    FOREIGN KEY (admin_id) REFERENCES cm_hrm.tb_customers(id) ON DELETE SET NULL
);

-- สร้าง Index สำหรับ chat_sessions
CREATE INDEX idx_chat_sessions_customer_id ON cm_hrm.chat_sessions(customer_id);
CREATE INDEX idx_chat_sessions_admin_id ON cm_hrm.chat_sessions(admin_id);
CREATE INDEX idx_chat_sessions_status ON cm_hrm.chat_sessions(status);
CREATE INDEX idx_chat_sessions_last_message_at ON cm_hrm.chat_sessions(last_message_at);

-- ตารางเก็บข้อความในแต่ละการสนทนา
CREATE TABLE cm_hrm.chat_messages (
    id SERIAL PRIMARY KEY,
    session_id INT NOT NULL, -- รหัสการสนทนา
    sender_type VARCHAR(20) NOT NULL CHECK (sender_type IN ('customer', 'admin')), -- ประเภทผู้ส่ง (customer หรือ admin)
    sender_id INT NOT NULL, -- ID ของผู้ส่งจาก tb_customers
    message TEXT NOT NULL, -- ข้อความ
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')), -- ประเภทข้อความ
    is_read BOOLEAN DEFAULT FALSE, -- สถานะการอ่าน
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (session_id) REFERENCES cm_hrm.chat_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES cm_hrm.tb_customers(id) ON DELETE CASCADE
);

-- สร้าง Index สำหรับ chat_messages
CREATE INDEX idx_chat_messages_session_id ON cm_hrm.chat_messages(session_id);
CREATE INDEX idx_chat_messages_sender_type ON cm_hrm.chat_messages(sender_type);
CREATE INDEX idx_chat_messages_sender_id ON cm_hrm.chat_messages(sender_id);
CREATE INDEX idx_chat_messages_created_at ON cm_hrm.chat_messages(created_at);
CREATE INDEX idx_chat_messages_is_read ON cm_hrm.chat_messages(is_read);

-- ตารางเก็บข้อมูล Admin (เชื่อมต่อกับ tb_customers)
CREATE TABLE cm_hrm.chat_admins (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL, -- ID ของ admin จาก tb_customers
    is_active BOOLEAN DEFAULT TRUE, -- สถานะการใช้งาน
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES cm_hrm.tb_customers(id) ON DELETE CASCADE,
    CONSTRAINT unique_customer_admin UNIQUE (customer_id)
);

-- สร้าง Index สำหรับ chat_admins
CREATE INDEX idx_chat_admins_customer_id ON cm_hrm.chat_admins(customer_id);
CREATE INDEX idx_chat_admins_is_active ON cm_hrm.chat_admins(is_active);

-- ตารางเก็บการแจ้งเตือน (Notifications)
CREATE TABLE cm_hrm.chat_notifications (
    id SERIAL PRIMARY KEY,
    session_id INT NOT NULL,
    recipient_type VARCHAR(20) NOT NULL CHECK (recipient_type IN ('customer', 'admin')),
    recipient_id INT NOT NULL, -- ID ของผู้รับจาก tb_customers
    notification_type VARCHAR(20) NOT NULL CHECK (notification_type IN ('new_message', 'session_assigned', 'session_closed')),
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (session_id) REFERENCES cm_hrm.chat_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES cm_hrm.tb_customers(id) ON DELETE CASCADE
);

-- สร้าง Index สำหรับ chat_notifications
CREATE INDEX idx_chat_notifications_session_id ON cm_hrm.chat_notifications(session_id);
CREATE INDEX idx_chat_notifications_recipient_type ON cm_hrm.chat_notifications(recipient_type);
CREATE INDEX idx_chat_notifications_recipient_id ON cm_hrm.chat_notifications(recipient_id);
CREATE INDEX idx_chat_notifications_is_read ON cm_hrm.chat_notifications(is_read);
CREATE INDEX idx_chat_notifications_created_at ON cm_hrm.chat_notifications(created_at);

-- ตารางเก็บไฟล์ที่แนบในแชท
CREATE TABLE cm_hrm.chat_attachments (
    id SERIAL PRIMARY KEY,
    message_id INT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT NOT NULL, -- ขนาดไฟล์เป็น bytes
    file_type VARCHAR(100) NOT NULL, -- MIME type
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (message_id) REFERENCES cm_hrm.chat_messages(id) ON DELETE CASCADE
);

-- สร้าง Index สำหรับ chat_attachments
CREATE INDEX idx_chat_attachments_message_id ON cm_hrm.chat_attachments(message_id);
CREATE INDEX idx_chat_attachments_file_type ON cm_hrm.chat_attachments(file_type);

-- ตารางเก็บสถิติการสนทนา
CREATE TABLE cm_hrm.chat_statistics (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    total_sessions INT DEFAULT 0,
    active_sessions INT DEFAULT 0,
    closed_sessions INT DEFAULT 0,
    total_messages INT DEFAULT 0,
    avg_response_time INT DEFAULT 0, -- เวลาเฉลี่ยในการตอบกลับ (วินาที)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_date UNIQUE (date)
);

-- สร้าง Index สำหรับ chat_statistics
CREATE INDEX idx_chat_statistics_date ON cm_hrm.chat_statistics(date);

-- สร้าง Trigger Functions สำหรับอัปเดต updated_at อัตโนมัติ
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- สร้าง Trigger สำหรับ chat_sessions
CREATE TRIGGER update_chat_sessions_updated_at 
    BEFORE UPDATE ON cm_hrm.chat_sessions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- สร้าง Trigger สำหรับ chat_admins
CREATE TRIGGER update_chat_admins_updated_at 
    BEFORE UPDATE ON cm_hrm.chat_admins 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- สร้าง Trigger สำหรับอัปเดต last_message_at เมื่อมีข้อความใหม่
CREATE OR REPLACE FUNCTION update_session_last_message_at()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE cm_hrm.chat_sessions 
    SET last_message_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.session_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_chat_sessions_last_message_at 
    AFTER INSERT ON cm_hrm.chat_messages 
    FOR EACH ROW EXECUTE FUNCTION update_session_last_message_at();

-- Insert default admin data (เชื่อมต่อกับ tb_customers)
-- หมายเหตุ: ต้องเพิ่ม field user_type ใน tb_customers ก่อน แล้วค่อยรัน INSERT นี้
-- INSERT INTO cm_hrm.chat_admins (customer_id, is_active) VALUES
-- (26, TRUE);  -- admin ที่ id = 26 ใน tb_customers

-- หมายเหตุ: ต้องสร้าง admin ใน tb_customers ก่อน โดยใช้ field ใหม่ที่สร้างขึ้น

-- ===== ขั้นตอนการติดตั้งระบบแชท =====
-- 1. เพิ่ม field user_type ใน tb_customers ก่อน
-- 2. กำหนด admin ใน tb_customers
-- 3. รัน INSERT INTO chat_admins
-- 4. ทดสอบระบบแชท

-- ===== คำแนะนำสำหรับการแยก Admin และ User ใน tb_customers =====
-- สร้าง field ใหม่สำหรับแยก admin/user โดยเก็บ field 'type' เดิมไว้

-- วิธีที่ 1: เพิ่ม field 'user_role' (แนะนำ)
-- ALTER TABLE cm_hrm.tb_customers ADD COLUMN user_role VARCHAR(20) DEFAULT 'customer';
-- UPDATE cm_hrm.tb_customers SET user_role = 'admin' WHERE id = 26;
-- CREATE INDEX idx_customers_user_role ON cm_hrm.tb_customers(user_role);

-- วิธีที่ 2: เพิ่ม field 'account_type' (ชัดเจนที่สุด)
-- ALTER TABLE cm_hrm.tb_customers ADD COLUMN account_type VARCHAR(20) DEFAULT 'customer';
-- UPDATE cm_hrm.tb_customers SET account_type = 'admin' WHERE id = 26;
-- CREATE INDEX idx_customers_account_type ON cm_hrm.tb_customers(account_type);

-- วิธีที่ 3: เพิ่ม field 'is_admin' (ง่ายที่สุด)
-- ALTER TABLE cm_hrm.tb_customers ADD COLUMN is_admin BOOLEAN DEFAULT FALSE;
-- UPDATE cm_hrm.tb_customers SET is_admin = TRUE WHERE id = 26;
-- CREATE INDEX idx_customers_is_admin ON cm_hrm.tb_customers(is_admin);

-- วิธีที่ 4: เพิ่ม field 'user_type' (ตรงกับการใช้งาน)
-- ALTER TABLE cm_hrm.tb_customers ADD COLUMN user_type VARCHAR(20) DEFAULT 'customer';
-- UPDATE cm_hrm.tb_customers SET user_type = 'admin' WHERE id = 26;
-- CREATE INDEX idx_customers_user_type ON cm_hrm.tb_customers(user_type);

-- ===== ตัวอย่างการใช้งาน =====
-- Query หา admin ทั้งหมด:
-- SELECT * FROM cm_hrm.tb_customers WHERE user_type = 'admin' AND isdelete = false;

-- Query หา customer ทั้งหมด:
-- SELECT * FROM cm_hrm.tb_customers WHERE user_type = 'customer' AND isdelete = false;

-- Query หา admin ที่สามารถตอบแชทได้:
-- SELECT c.* FROM cm_hrm.tb_customers c 
-- INNER JOIN cm_hrm.chat_admins ca ON c.id = ca.customer_id 
-- WHERE c.user_type = 'admin' AND ca.is_active = true AND c.isdelete = false;

-- ===== สคริปต์ติดตั้งระบบแชท (รันตามลำดับ) =====

-- ขั้นตอนที่ 1: เพิ่ม field user_type ใน tb_customers
-- ALTER TABLE cm_hrm.tb_customers ADD COLUMN user_type VARCHAR(20) DEFAULT 'customer';
-- CREATE INDEX idx_tb_customers_user_type ON cm_hrm.tb_customers(user_type);

-- ขั้นตอนที่ 2: กำหนดค่าเริ่มต้นให้กับข้อมูลที่มีอยู่
-- UPDATE cm_hrm.tb_customers SET user_type = 'customer' WHERE user_type IS NULL;

-- ขั้นตอนที่ 3: กำหนด admin (เปลี่ยน id ตามต้องการ)
-- UPDATE cm_hrm.tb_customers SET user_type = 'admin' WHERE id = 26;

-- ขั้นตอนที่ 4: เพิ่ม admin ใน chat_admins (เปลี่ยน id ตามต้องการ)
-- INSERT INTO cm_hrm.chat_admins (customer_id, is_active) VALUES
-- (26, TRUE);  -- admin ที่ id = 26 ใน tb_customers

-- ขั้นตอนที่ 5: ตรวจสอบผลลัพธ์
-- SELECT id, name, email, user_type FROM cm_hrm.tb_customers WHERE user_type = 'admin';
-- SELECT * FROM cm_hrm.chat_admins;