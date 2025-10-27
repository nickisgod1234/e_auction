import 'package:flutter/material.dart';
import 'package:e_auction/services/chat_service.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:e_auction/views/first_page/admin_chat_page/admin_chat_page.dart';
import 'dart:async';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _adminId;
  List<Map<String, dynamic>> _pendingSessions = [];
  List<Map<String, dynamic>> _mySessions = [];
  Timer? _pollingTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // เปลี่ยนจาก 2 เป็น 3
    _loadData();
    _startPolling();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // ดึง admin ID จาก SharedPreferences
    _adminId = await UserDataManager.getCustomerID();
    
    if (_adminId != null) {
      await _loadAllSessions();
    } else {
      _showErrorSnackBar('ไม่พบข้อมูล Admin');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadAllSessions() async {
    final response = await ChatService.getAllSessions(status: 'all');
    if (response.success && response.data != null) {
      setState(() {
        // แยก sessions ตาม status
        _pendingSessions = response.data!.where((session) => session['status'] == 'pending').toList();
        _mySessions = response.data!.where((session) => session['status'] == 'active').toList();
      });
    } else {
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      await _loadAllSessions();
    });
  }

  Future<void> _assignSession(int sessionId) async {
    if (_adminId == null) return;
    
    final response = await ChatService.assignAdmin(
      sessionId: sessionId,
      adminId: _adminId!,
    );
    
    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('รับผิดชอบการสนทนาสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadData();
    } else {
      _showErrorSnackBar('ไม่สามารถรับผิดชอบการสนทนาได้: ${response.message}');
    }
  }

  void _openChat(int sessionId, String customerName) {
    // ลบ unread count เมื่อกดเข้าอ่าน
    setState(() {
      final sessionIndex = _mySessions.indexWhere((session) => session['id'] == sessionId);
      if (sessionIndex != -1) {
        _mySessions[sessionIndex]['unread_count'] = 0;
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminChatPage(
          sessionId: sessionId,
          adminId: _adminId!,
          customerName: customerName,
        ),
      ),
    ).then((_) {
      // เมื่อกลับมาจากหน้า chat ให้รีเฟรชข้อมูล
      _loadAllSessions();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'รอตอบกลับ (${_pendingSessions.length})',
              icon: Icon(Icons.pending_actions),
            ),
            Tab(
              text: 'กำลังสนทนา (${_mySessions.length})',
              icon: Icon(Icons.chat),
            ),
            Tab(
              text: 'อนุมัติสินค้า',
              icon: Icon(Icons.approval),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Pending Sessions
                _buildPendingList(),
                // Tab 2: My Sessions
                _buildMySessionsList(),
                // Tab 3: Product Approval
                _buildProductApprovalList(),
              ],
            ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'ไม่มีการสนทนาที่รอตอบกลับ',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllSessions,
      child: ListView.builder(
        itemCount: _pendingSessions.length,
        itemBuilder: (context, index) {
          final session = _pendingSessions[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(
                  session['customer_phone']?.substring(0, 1) ?? 'U',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                _formatPhoneNumber(session['customer_phone']),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    session['last_message'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.message, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'ข้อความ: ${session['message_count'] ?? 0}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        _formatTime(session['created_at']),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => _assignSession(session['id']),
                child: Text('รับ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              onTap: () => _openChat(session['id'], _formatPhoneNumber(session['customer_phone'])),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMySessionsList() {
    if (_mySessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'ไม่มีการสนทนาที่กำลังดูแล',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllSessions,
      child: ListView.builder(
        itemCount: _mySessions.length,
        itemBuilder: (context, index) {
          final session = _mySessions[index];
          final hasUnread = (session['unread_count'] ?? 0) > 0;

          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      session['customer_phone']?.substring(0, 1) ?? 'U',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${session['unread_count']}',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                _formatPhoneNumber(session['customer_phone']),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    session['last_message'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        _formatTime(session['last_message_at']),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (hasUnread) ...[
                        SizedBox(width: 16),
                        Icon(Icons.notifications_active, size: 16, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          'มีข้อความใหม่',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              onTap: () => _openChat(session['id'], _formatPhoneNumber(session['customer_phone'])),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductApprovalList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.approval, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'อนุมัติสินค้า',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'ฟีเจอร์นี้กำลังพัฒนา',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ฟีเจอร์อนุมัติสินค้ากำลังพัฒนา'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: Icon(Icons.info),
            label: Text('ข้อมูลเพิ่มเติม'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // แปลงเบอร์โทรศัพท์เป็นรูปแบบ 0
  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return 'ไม่ระบุเบอร์';
    
    // ถ้าเบอร์เริ่มด้วย 0 อยู่แล้ว ให้คืนค่าเดิม
    if (phone.startsWith('0')) {
      return phone;
    }
    
    // ถ้าเบอร์ไม่เริ่มด้วย 0 ให้เพิ่ม 0 หน้า
    return '0$phone';
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final dateTime = DateTime.parse(isoTime);
      final now = DateTime.now();
      
      if (dateTime.day == now.day) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }
}
