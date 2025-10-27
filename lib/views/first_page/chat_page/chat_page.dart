import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/models/chat_models.dart';
import 'package:e_auction/services/chat_service.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:e_auction/widgets/typing_indicator.dart';
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
  int? _customerId; // ดึงจาก SharedPreferences 'id' key
  bool _isLoading = false;
  bool _isSending = false;
  bool _isPolling = false; // เพิ่ม flag สำหรับป้องกัน polling ซ้ำ
  bool _isTyping = false; // เพิ่มตัวแปรสำหรับ tracking การพิมพ์
  bool _isInChatScreen = true; // เพิ่ม flag สำหรับตรวจสอบว่าอยู่ในหน้าแชทหรือไม่
  Timer? _pollingTimer;
  Timer? _typingTimer; // Timer สำหรับส่งสัญญาณหยุดพิมพ์
  
  @override
  void initState() {
    super.initState();
 
    _initializeChat();
    // ไม่เริ่ม polling ที่นี่ เพราะจะเริ่มหลังจากโหลดข้อความเสร็จ
  }

  // เริ่มต้นการแชท
  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    
 
    
    // ดึง customer_id จาก SharedPreferences ที่บันทึกจากการล็อกอิน
    await _loadUserData();
    
    if (_customerId != null) {
   
      await _createOrGetSession();
      await _loadMessages();
      // Mark messages as read เมื่อเข้าหน้าแชท
      await _markMessagesAsRead();
      // เริ่ม polling หลังจากโหลดข้อความเสร็จ
      _startPolling();
    } else {
     
      _showErrorSnackBar('ไม่พบข้อมูลผู้ใช้ กรุณาล็อกอินใหม่');
    }
    
 
    setState(() => _isLoading = false);
  }

  // ดึงข้อมูลผู้ใช้จาก SharedPreferences
  Future<void> _loadUserData() async {
    try {
      // ตรวจสอบว่าผู้ใช้ล็อกอินแล้วหรือไม่
      final isLoggedIn = await UserDataManager.isLoggedIn();
      if (!isLoggedIn) {
    
        return;
      }

      // ดึง customer_id
      final customerId = await UserDataManager.getCustomerID();
      if (customerId != null) {
        setState(() {
          _customerId = customerId;
        });
     
        
          // ดึงข้อมูลเพิ่มเติม
          // final phoneNumber = await UserDataManager.getPhoneNumber();
          // final name = await UserDataManager.getName();
     
      } else {
      
      }
    } catch (e) {
    
    }
  }

  // สร้างหรือดึงข้อมูลการสนทนา
  Future<void> _createOrGetSession() async {
    final response = await ChatService.createOrGetSession(customerId: _customerId!);
    if (response.success && response.data != null) {
      setState(() {
        _currentSession = ChatSession.fromJson(response.data!);
      });
    } else {
      _showErrorSnackBar(response.message);
    }
  }

  // ดึงข้อมูล admin (ไม่ใช้แล้ว เพราะไม่มี API)
  // Future<void> _loadAdminInfo() async {
  //   // API ไม่มีแล้ว
  // }

  // ดึงข้อความทั้งหมด
  Future<void> _loadMessages() async {
    if (_currentSession != null && _customerId != null) {
     
      final response = await ChatService.getMessages(
        sessionId: _currentSession!.id,
        customerId: _customerId!,
      );
      if (response.success && response.data != null) {
        setState(() {
          // ล้างข้อความเก่าและโหลดใหม่ทั้งหมด
          _messages = response.data!;
        });
        _scrollToBottom();
      
      } else {
      
        _showErrorSnackBar(response.message);
      }
    }
  }

  // ส่งข้อความ
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending || _currentSession == null || _customerId == null) {
   
      return;
    }

    setState(() => _isSending = true);
    
    final messageText = _messageController.text.trim();
    _messageController.clear();
    
   

    final response = await ChatService.sendMessage(
      sessionId: _currentSession!.id,
      customerId: _customerId!,
      message: messageText,
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
      
      } else {
     
      }
    } else {
      _showErrorSnackBar(response.message);
      // คืนข้อความกลับไปในช่องพิมพ์
      _messageController.text = messageText;
    }

    setState(() => _isSending = false);
  }

  // เริ่ม polling สำหรับข้อความใหม่
  void _startPolling() {
    // หยุด polling เก่าก่อน (ถ้ามี)
    _pollingTimer?.cancel();
    
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkNewMessages();
    });
  
  }

  // ตรวจสอบข้อความใหม่
  Future<void> _checkNewMessages() async {
    if (_currentSession == null || _customerId == null || _isPolling) {
    
      return;
    }

    _isPolling = true;
   
    
    try {
      final response = await ChatService.checkNewMessages(
        sessionId: _currentSession!.id,
        customerId: _customerId!,
        since: _messages.isNotEmpty ? _messages.last.createdAt.toIso8601String() : null,
      );

   

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        // ตรวจสอบว่าข้อความใหม่ไม่ซ้ำกับที่มีอยู่
        final existingMessageIds = _messages.map((m) => m.id).toSet();
        final newMessages = response.data!.where((msg) => !existingMessageIds.contains(msg.id)).toList();
        
         
        
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
                    itemCount: _messages.length + (_isTyping ? 1 : 0), // เพิ่ม 1 ถ้ากำลังพิมพ์
                    itemBuilder: (context, index) {
                      // แสดง typing indicator ที่ท้ายสุด
                      if (index == _messages.length && _isTyping) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: TypingIndicator(
                            senderName: 'Admin',
                            backgroundColor: Colors.grey[200],
                            dotColor: Colors.grey[500],
                          ),
                        );
                      }
                      
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
                      onChanged: _onTextChanged, // เพิ่ม callback สำหรับ typing indicator
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
                      onSubmitted: (_) {
                        if (!_isSending) {
                          _sendMessage();
                        }
                      },
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
    // ใช้ is_mine จาก API หรือ fallback เป็น isFromUser
    final isMine = message.isMine ?? message.isFromUser;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
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
                color: isMine
                    ? context.customTheme.primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isMine
                      ? Radius.circular(20)
                      : Radius.circular(4),
                  bottomRight: isMine
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
                      color: isMine ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: isMine
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[600],
                          fontSize: 11,
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
                            ? Colors.white.withOpacity(0.8)  // สีขาวจาง = อ่านแล้ว
                            : Colors.white.withOpacity(0.5), // สีขาวจางมาก = ส่งแล้วแต่ยังไม่อ่าน
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMine) ...[
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

    // ถ้าเป็นวันเดียวกัน แสดงเวลา
    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    // ถ้าเป็นวันอื่น แสดงวันที่และเวลา
    else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  // ส่งสัญญาณกำลังพิมพ์
  void _sendTypingIndicator(bool isTyping) async {
    if (_currentSession == null || _customerId == null) return;
    
    try {
      await ChatService.sendTypingIndicator(
        sessionId: _currentSession!.id,
        customerId: _customerId!,
        senderType: 'customer',
        isTyping: isTyping,
      );

    } catch (e) {
        
    }
  }

  // Mark messages as read
  Future<void> _markMessagesAsRead() async {
    if (!_isInChatScreen || _currentSession == null || _customerId == null) {
      
      return;
    }
    
  
    try {
      final response = await ChatService.markMessagesAsRead(
        sessionId: _currentSession!.id,
        recipientType: 'customer',
        recipientId: _customerId!,
      );
      
      if (response.success) {
     
      } else {
    
      }
    } catch (e) {
    
    }
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
    _messageController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}
