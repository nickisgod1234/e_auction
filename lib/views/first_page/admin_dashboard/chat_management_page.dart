import 'package:flutter/material.dart';
import 'dart:async';
import 'package:e_auction/services/chat_service.dart';

class ChatManagementPage extends StatefulWidget {
  final List<Map<String, dynamic>> pendingSessions;
  final List<Map<String, dynamic>> mySessions;
  final int adminId;
  final Function(int) onAssignSession;
  final Function(int, String) onOpenChat;
  final Future<void> Function() onRefresh;

  const ChatManagementPage({
    super.key,
    required this.pendingSessions,
    required this.mySessions,
    required this.adminId,
    required this.onAssignSession,
    required this.onOpenChat,
    required this.onRefresh,
  });

  @override
  State<ChatManagementPage> createState() => _ChatManagementPageState();
}

class _ChatManagementPageState extends State<ChatManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _pendingScrollController = ScrollController();
  final ScrollController _mySessionsScrollController = ScrollController();
  Timer? _pollingTimer;
  
  // Local state variables
  List<Map<String, dynamic>> _pendingSessions = [];
  List<Map<String, dynamic>> _mySessions = [];
  Set<int> _assigningSessions = {}; // Track sessions being assigned

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // กำหนดข้อมูลเริ่มต้น
    _pendingSessions = List.from(widget.pendingSessions);
    _mySessions = List.from(widget.mySessions);
    
    // เลื่อนไปล่างสุดเมื่อโหลดเสร็จ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToBottom();
      }
    });
    
    // เริ่ม polling เพื่อ refresh ข้อมูลอัตโนมัติ
    _startPolling();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('การแชท'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            // เลื่อนไปล่างสุดเมื่อเปลี่ยนแท็บ
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _scrollToBottom();
              }
            });
          },
          tabs: [
            Tab(
              text: 'รอตอบกลับ (${_pendingSessions.length})',
              icon: Icon(Icons.pending_actions),
            ),
            Tab(
              text: 'กำลังสนทนา (${_mySessions.length})',
              icon: Icon(Icons.chat),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await _refreshData();
              // Restart polling หลังจาก manual refresh
              _startPolling();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingList(),
          _buildMySessionsList(),
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
      onRefresh: () async {
        await _refreshData();
        // Restart polling หลังจาก manual refresh
        _startPolling();
      },
      child: ListView.builder(
        controller: _pendingScrollController,
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
                onPressed: _assigningSessions.contains(session['id']) ? null : () async {
                  setState(() {
                    _assigningSessions.add(session['id']);
                  });
                  
                  try {
                    await widget.onAssignSession(session['id']);
                    // อัปเดต local state หลังจากรับ session
                    await _refreshData();
                    
                    // เปลี่ยนไป tab "กำลังสนทนา" หลังจากรับสำเร็จ
                    if (_tabController.index == 0) {
                      _tabController.animateTo(1);
                    }
                    
                    // ไปที่หน้าแชทของคนนั้นทันที
                    widget.onOpenChat(session['id'], _formatPhoneNumber(session['customer_phone']));
                  } finally {
                    setState(() {
                      _assigningSessions.remove(session['id']);
                    });
                  }
                },
                child: _assigningSessions.contains(session['id']) 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('รับ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              onTap: () => widget.onOpenChat(session['id'], _formatPhoneNumber(session['customer_phone'])),
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
      onRefresh: () async {
        await _refreshData();
        // Restart polling หลังจาก manual refresh
        _startPolling();
      },
      child: ListView.builder(
        controller: _mySessionsScrollController,
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
              onTap: () => widget.onOpenChat(session['id'], _formatPhoneNumber(session['customer_phone'])),
            ),
          );
        },
      ),
    );
  }

  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return 'ไม่ระบุเบอร์';
    
    if (phone.startsWith('0')) {
      return phone;
    }
    
    return '0$phone';
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final dateTime = DateTime.parse(isoTime).toLocal();
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

  void _startPolling() {
    // หยุด timer เก่าก่อน (ถ้ามี)
    _pollingTimer?.cancel();
    
    // เริ่ม timer ใหม่ - refresh ทุก 5 วินาที
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (mounted) {
        await _refreshData();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _refreshData() async {
    try {
      // เรียก API โดยตรงเพื่อดึงข้อมูลล่าสุด
      final response = await ChatService.getAllSessions(status: 'all');
      
      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            // แยก sessions ตาม status
            _pendingSessions = response.data!.where((session) => session['status'] == 'pending').toList();
            _mySessions = response.data!.where((session) => session['status'] == 'active').toList();
          });
        }
      }
      
      // เรียก onRefresh เพื่ออัปเดตข้อมูลใน AdminDashboard ด้วย
      await widget.onRefresh();
      
      // เลื่อนไปล่างสุดหลังจาก refresh
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      print('Error refreshing data: $e');
      // ถ้าเกิดข้อผิดพลาด ให้ใช้ข้อมูลจาก widget
      if (mounted) {
        setState(() {
          _pendingSessions = List.from(widget.pendingSessions);
          _mySessions = List.from(widget.mySessions);
        });
      }
    }
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _scrollToBottom() {
    if (!mounted) return;
    
    // เลื่อนไปล่างสุดของแท็บที่กำลังแสดงอยู่
    if (_tabController.index == 0) {
      // แท็บ "รอตอบกลับ"
      if (_pendingScrollController.hasClients) {
        _pendingScrollController.animateTo(
          _pendingScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else {
      // แท็บ "กำลังสนทนา"
      if (_mySessionsScrollController.hasClients) {
        _mySessionsScrollController.animateTo(
          _mySessionsScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _stopPolling(); // หยุด polling เมื่อ dispose
    _tabController.dispose();
    _pendingScrollController.dispose();
    _mySessionsScrollController.dispose();
    super.dispose();
  }
}
