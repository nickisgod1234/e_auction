import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/models/chat_models.dart';
import 'package:e_auction/services/chat_service.dart';
import 'dart:async';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  ChatSession? _currentSession;
  ChatAdmin? _currentAdmin;
  String? _phoneId; // ควรดึงจาก SharedPreferences หรือ UserProvider
  bool _isLoading = false;
  bool _isSending = false;
  Timer? _pollingTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeChat();
    _startPolling();
  }

  // เริ่มต้นการแชท
  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    
    // ดึง phone_id จาก SharedPreferences หรือ UserProvider
    // ตอนนี้ใช้ค่า mock ก่อน
    _phoneId = '0812345678'; // ควรดึงจากระบบ authentication
    
    if (_phoneId != null) {
      await _createOrGetSession();
      await _loadMessages();
    }
    
    setState(() => _isLoading = false);
  }

  // สร้างหรือดึงข้อมูลการสนทนา
  Future<void> _createOrGetSession() async {
    final response = await ChatService.createOrGetSession(_phoneId!);
    if (response.success && response.data != null) {
      setState(() {
        _currentSession = response.data;
      });
      
      // ดึงข้อมูล admin ถ้ามี
      if (_currentSession!.adminId != null) {
        await _loadAdminInfo();
      }
    } else {
      _showErrorSnackBar(response.message);
    }
  }

  // ดึงข้อมูล admin
  Future<void> _loadAdminInfo() async {
    if (_currentSession?.adminId != null) {
      final response = await ChatService.getSessionAdmin(_currentSession!.id);
      if (response.success && response.data != null) {
        setState(() {
          _currentAdmin = response.data;
        });
      }
    }
  }

  // ดึงข้อความทั้งหมด
  Future<void> _loadMessages() async {
    if (_currentSession != null) {
      final response = await ChatService.getMessages(sessionId: _currentSession!.id);
      if (response.success && response.data != null) {
        setState(() {
          _messages = response.data!.messages;
        });
        _scrollToBottom();
      } else {
        _showErrorSnackBar(response.message);
      }
    }
  }

  // ส่งข้อความ
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending || _currentSession == null) {
      return;
    }

    setState(() => _isSending = true);
    
    final messageText = _messageController.text.trim();
    _messageController.clear();

    final response = await ChatService.sendMessage(
      sessionId: _currentSession!.id,
      senderType: 'user',
      senderId: _phoneId!,
      message: messageText,
    );

    if (response.success && response.data != null) {
      setState(() {
        _messages.add(response.data!);
      });
      _scrollToBottom();
    } else {
      _showErrorSnackBar(response.message);
      // คืนข้อความกลับไปในช่องพิมพ์
      _messageController.text = messageText;
    }

    setState(() => _isSending = false);
  }

  // เริ่ม polling สำหรับข้อความใหม่
  void _startPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkNewMessages();
    });
  }

  // ตรวจสอบข้อความใหม่
  Future<void> _checkNewMessages() async {
    if (_currentSession == null || _messages.isEmpty) return;

    final lastMessageTime = _messages.last.createdAt;
    final response = await ChatService.checkNewMessages(
      sessionId: _currentSession!.id,
      lastMessageTime: lastMessageTime,
    );

    if (response.success && response.data != null && response.data!.isNotEmpty) {
      setState(() {
        _messages.addAll(response.data!);
      });
      _scrollToBottom();
    }
  }

  // เลื่อนไปข้อความล่าสุด
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // แสดงข้อความ error
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
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: context.customTheme.primaryColor,
              child: Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentAdmin?.adminName ?? 'เจ้าหน้าที่บริการลูกค้า',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _currentSession?.adminId != null ? 'ออนไลน์' : 'รอการตอบกลับ',
                  style: TextStyle(
                    fontSize: 12,
                    color: _currentSession?.adminId != null ? Colors.green[300] : Colors.orange[300],
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: context.customTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: context.customTheme.primaryColor,
              ),
            )
          : Column(
              children: [
                // Chat messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
          // Message input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSending 
                          ? Colors.grey 
                          : context.customTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isFromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isFromUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: context.customTheme.primaryColor,
              child: Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 16,
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isFromUser
                    ? context.customTheme.primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isFromUser
                      ? Radius.circular(20)
                      : Radius.circular(4),
                  bottomRight: message.isFromUser
                      ? Radius.circular(4)
                      : Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: message.isFromUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: message.isFromUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isFromUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }
}
