import 'package:flutter/material.dart';
import 'package:e_auction/models/chat_models.dart';
import 'package:e_auction/services/chat_service.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/widgets/typing_indicator.dart';
import 'dart:async';

class AdminChatPage extends StatefulWidget {
  final int sessionId;
  final int adminId;
  final String customerName;

  const AdminChatPage({
    super.key,
    required this.sessionId,
    required this.adminId,
    required this.customerName,
  });

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isPolling = false;
  bool _isTyping = false; // เพิ่มตัวแปรสำหรับ tracking การพิมพ์
  bool _isInChatScreen = true; // เพิ่ม flag สำหรับตรวจสอบว่าอยู่ในหน้าแชทหรือไม่
  Timer? _pollingTimer;
  Timer? _typingTimer; // Timer สำหรับส่งสัญญาณหยุดพิมพ์

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    
    await _loadMessages();
    // Mark messages as read เมื่อเข้าหน้าแชท
    await _markMessagesAsRead();
    _startPolling();
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadMessages() async {
    final response = await ChatService.getMessages(
      sessionId: widget.sessionId,
      customerId: widget.adminId, // Admin ID สำหรับการดึงข้อความ
    );

    if (response.success && response.data != null) {
      setState(() {
        _messages = response.data!;
      });
      _scrollToBottom();
    } else {
      _showErrorSnackBar(response.message);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);

    final messageText = _messageController.text.trim();
    _messageController.clear();

    final response = await ChatService.sendMessage(
      sessionId: widget.sessionId,
      customerId: widget.adminId,
      message: messageText,
      senderType: 'admin', // Admin ส่งข้อความ
    );

    if (response.success && response.data != null) {
      // สร้าง ChatMessage object จาก response
      final newMessage = ChatMessage.fromJson(response.data!);

      // ตรวจสอบว่าข้อความนี้ยังไม่มีในรายการ
      final messageExists = _messages.any((msg) => msg.id == newMessage.id);
      if (!messageExists) {
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      } else {}
    } else {
      _showErrorSnackBar(response.message);
      // คืนข้อความกลับไปในช่องพิมพ์
      _messageController.text = messageText;
    }

    setState(() => _isSending = false);
  }

  void _startPolling() {
    // หยุด polling เก่าก่อน (ถ้ามี)
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkNewMessages();
    });
  }

  Future<void> _checkNewMessages() async {
    if (_isPolling) {
      return;
    }

    _isPolling = true;

    try {
      final response = await ChatService.checkNewMessages(
        sessionId: widget.sessionId,
        customerId: widget.adminId, // Admin ID สำหรับการตรวจสอบข้อความใหม่
        since: _messages.isNotEmpty
            ? _messages.last.createdAt.toIso8601String()
            : null,
      );

      if (response.success &&
          response.data != null &&
          response.data!.isNotEmpty) {
        // ตรวจสอบว่าข้อความใหม่ไม่ซ้ำกับที่มีอยู่
        final existingMessageIds = _messages.map((m) => m.id).toSet();
        final newMessages = response.data!
            .where((msg) => !existingMessageIds.contains(msg.id))
            .toList();

        if (newMessages.isNotEmpty) {
          setState(() {
            _messages.addAll(newMessages);
          });
          _scrollToBottom();
          
          // Mark messages as read ทันทีเมื่อได้ข้อความใหม่
          await _markMessagesAsRead();
          
          // Refresh ข้อความเพื่อแสดงสถานะ is_read ที่อัปเดตแล้ว
          await _loadMessages();
        } else {
          // ไม่มีข้อความใหม่ แต่ยังต้องดึงสถานะ read ที่อัปเดต
          await _loadMessages();
        }
      }
    } finally {
      _isPolling = false;
    }
  }

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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _closeSession() async {
    // TODO: Implement close session functionality later
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ฟีเจอร์ปิดการสนทนาจะเปิดใช้งานในอนาคต'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customerName,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'Admin Chat',
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: _closeSession,
            tooltip: 'ปิดการสนทนา',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'ยังไม่มีข้อความ',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length +
                            (_isTyping ? 1 : 0), // เพิ่ม 1 ถ้ากำลังพิมพ์
                        itemBuilder: (context, index) {
                          // แสดง typing indicator ที่ท้ายสุด
                          if (index == _messages.length && _isTyping) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: TypingIndicator(
                                senderName: widget.customerName,
                                backgroundColor: Colors.blue[100],
                                dotColor: Colors.blue[600],
                              ),
                            );
                          }

                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),

          // Input Box
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged:
                        _onTextChanged, // เพิ่ม callback สำหรับ typing indicator
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ข้อความ...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!_isSending) {
                        _sendMessage();
                      }
                    },
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
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
          SizedBox(
            height: 25,
          )
        ],
      ),
    );
  }

  // แปลงเบอร์โทรศัพท์เป็นรูปแบบ 0
  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return 'Customer';

    // ถ้าเบอร์เริ่มด้วย 0 อยู่แล้ว ให้คืนค่าเดิม
    if (phone.startsWith('0')) {
      return phone;
    }

    // ถ้าเบอร์ไม่เริ่มด้วย 0 ให้เพิ่ม 0 หน้า
    return '0$phone';
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMine = message.senderType == 'admin';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMine ? context.customTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: isMine ? Radius.circular(20) : Radius.circular(4),
            bottomRight: isMine ? Radius.circular(4) : Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // ชื่อผู้ส่ง (ถ้าไม่ใช่ของฉัน) - ซ่อนชื่อ customer
            if (!isMine) ...[
              Text(
                _formatPhoneNumber(message.senderPhone),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
            ],

            // ข้อความ
            Text(
              message.message,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),

            SizedBox(height: 4),

            // เวลาและ Read status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                // Read status สำหรับข้อความของตัวเอง
                if (isMine) ...[
                  SizedBox(width: 4),
                  Icon(
                    message.isRead 
                      ? Icons.done_all  // อ่านแล้ว (ติ๊กสองอัน)
                      : Icons.done,     // ส่งแล้ว (ติ๊กอันเดียว)
                    size: 12,
                    color: message.isRead 
                      ? Colors.white  // สีขาว = อ่านแล้ว
                      : Colors.white70, // สีขาวจาง = ส่งแล้วแต่ยังไม่อ่าน
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    // ถ้าเป็นวันเดียวกัน แสดงเวลา
    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    // ถ้าเป็นวันอื่น แสดงวันที่และเวลา
    else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  // Mark messages as read
  Future<void> _markMessagesAsRead() async {
    if (!_isInChatScreen) {
      return;
    }
    
    try {
      final response = await ChatService.markMessagesAsRead(
        sessionId: widget.sessionId,
        recipientType: 'admin',
        recipientId: widget.adminId,
      );
      
      if (response.success) {
        // Success
      } else {
        // Failed
      }
    } catch (e) {
      // Error
    }
  }

  // ส่งสัญญาณกำลังพิมพ์
  void _sendTypingIndicator(bool isTyping) async {
    try {
      await ChatService.sendTypingIndicator(
        sessionId: widget.sessionId,
        customerId: widget.adminId,
        senderType: 'admin',
        isTyping: isTyping,
      );
    } catch (e) {}
  }

  // เริ่มต้นการพิมพ์
  void _onTextChanged(String text) {
    if (!_isTyping && text.isNotEmpty) {
      _isTyping = true;
      _sendTypingIndicator(true);
    }

    // รีเซ็ต timer สำหรับหยุดพิมพ์
    _typingTimer?.cancel();
    if (text.isNotEmpty) {
      _typingTimer = Timer(Duration(seconds: 2), () {
        if (_isTyping) {
          _isTyping = false;
          _sendTypingIndicator(false);
        }
      });
    } else {
      // ถ้าไม่มีข้อความ ให้หยุดพิมพ์ทันที
      if (_isTyping) {
        _isTyping = false;
        _sendTypingIndicator(false);
      }
    }
  }

  @override
  void dispose() {
    _isInChatScreen = false; // ออกจากหน้าแชท
    _pollingTimer?.cancel();
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }
}
