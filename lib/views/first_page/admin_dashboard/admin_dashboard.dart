import 'package:flutter/material.dart';
import 'package:e_auction/services/chat_service.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:e_auction/views/first_page/admin_chat_page/admin_chat_page.dart';
import 'package:e_auction/views/first_page/admin_dashboard/product_approval_page.dart';
import 'package:e_auction/views/first_page/admin_dashboard/chat_management_page.dart';
import 'package:e_auction/views/first_page/admin_dashboard/user_management_page.dart';
import 'package:e_auction/views/first_page/admin_dashboard/winner_management_page.dart';
import 'package:e_auction/views/first_page/admin_dashboard/coupon_management_page.dart';
import 'dart:async';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int? _adminId;
  List<Map<String, dynamic>> _pendingSessions = [];
  List<Map<String, dynamic>> _mySessions = [];
  Timer? _pollingTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
    if (_adminId == null) return;
    
    // ดึง pending sessions (ทั้งหมดที่รอตอบกลับ) - ไม่ต้องแก้
    final pendingResponse = await ChatService.getPendingSessions();
    if (pendingResponse.success && pendingResponse.data != null) {
      setState(() {
        _pendingSessions = pendingResponse.data!;
      });
    }
    
    // ดึง sessions ที่ admin คนนี้รับผิดชอบเท่านั้น (เฉพาะกำลังสนทนา)
    final mySessionsResponse = await ChatService.getMySessions(
      adminId: _adminId!,
      status: 'active',
    );
    if (mySessionsResponse.success && mySessionsResponse.data != null) {
      setState(() {
        _mySessions = mySessionsResponse.data!;
      });
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

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChatManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatManagementPage(
          pendingSessions: _pendingSessions,
          mySessions: _mySessions,
          adminId: _adminId!,
          onAssignSession: _assignSession,
          onOpenChat: _openChat,
          onRefresh: _refreshData,
        ),
      ),
    );
  }

  void _openProductApproval() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductApprovalPage(),
      ),
    );
  }

  void _openUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserManagementPage(),
      ),
    );
  }

  void _openWinnerManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WinnerManagementPage(),
      ),
    );
  }

  void _openCouponManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CouponManagementPage(),
      ),
    );
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ฟีเจอร์การตั้งค่ากำลังพัฒนา'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadAllSessions();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    icon: Icons.chat,
                    title: 'การแชท',
                    subtitle: 'รอ: ${_pendingSessions.length} | กำลัง: ${_mySessions.length}',
                    color: Colors.blue,
                    onTap: () => _openChatManagement(),
                  ),
                  _buildDashboardCard(
                    icon: Icons.approval,
                    title: 'อนุมัติสินค้า',
                    subtitle: 'จัดการการอนุมัติ',
                    color: Colors.green,
                    onTap: () => _openProductApproval(),
                  ),
                  _buildDashboardCard(
                    icon: Icons.people,
                    title: 'รายการผู้ใช้งาน',
                    subtitle: 'จัดการผู้ใช้งาน',
                    color: Colors.purple,
                    onTap: () => _openUserManagement(),
                  ),
                  _buildDashboardCard(
                    icon: Icons.emoji_events,
                    title: 'ตรวจสอบผู้ชนะ',
                    subtitle: 'ดูรายการผู้ชนะ',
                    color: Colors.amber,
                    onTap: () => _openWinnerManagement(),
                  ),
                  _buildDashboardCard(
                    icon: Icons.local_offer,
                    title: 'จัดการคูปอง',
                    subtitle: 'ดูและจัดการคูปอง',
                    color: Colors.pink,
                    onTap: () => _openCouponManagement(),
                  ),
                  _buildDashboardCard(
                    icon: Icons.settings,
                    title: 'การตั้งค่า',
                    subtitle: 'ตั้งค่าระบบ',
                    color: Colors.grey,
                    onTap: () => _openSettings(),
                  ),
                ],
              ),
            ),
    );
  }


  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
