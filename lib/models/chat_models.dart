class ChatSession {
  final int id;
  final int customerId;
  final int? adminId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastMessageAt;

  ChatSession({
    required this.id,
    required this.customerId,
    this.adminId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      customerId: json['customer_id'],
      adminId: json['admin_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastMessageAt: DateTime.parse(json['last_message_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'admin_id': adminId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message_at': lastMessageAt.toIso8601String(),
    };
  }
}

class ChatMessage {
  final int id;
  final int sessionId;
  final String senderType; // 'customer' or 'admin'
  final int senderId;
  final String? senderName;
  final String? senderEmail;
  final String? senderPhone;
  final String message;
  final String messageType; // 'text', 'image', 'file'
  final bool isRead;
  final bool? isMine; // null if not provided by API
  final DateTime createdAt;
  final List<ChatAttachment>? attachments;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderType,
    required this.senderId,
    this.senderName,
    this.senderEmail,
    this.senderPhone,
    required this.message,
    required this.messageType,
    required this.isRead,
    this.isMine,
    required this.createdAt,
    this.attachments,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sessionId: json['session_id'],
      senderType: json['sender_type'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderEmail: json['sender_email'],
      senderPhone: json['sender_phone'],
      message: json['message'],
      messageType: json['message_type'],
      isRead: json['is_read'] ?? false,
      isMine: json['is_mine'],
      createdAt: DateTime.parse(json['created_at']),
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((attachment) => ChatAttachment.fromJson(attachment))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'sender_type': senderType,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_email': senderEmail,
      'sender_phone': senderPhone,
      'message': message,
      'message_type': messageType,
      'is_read': isRead,
      'is_mine': isMine,
      'created_at': createdAt.toIso8601String(),
      'attachments': attachments?.map((attachment) => attachment.toJson()).toList(),
    };
  }

  // Helper method to check if message is from customer
  bool get isFromUser => senderType == 'customer';
  
  // Helper method to check if message is from admin
  bool get isFromAdmin => senderType == 'admin';
}

class ChatAttachment {
  final int id;
  final int messageId;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String fileType;
  final DateTime createdAt;

  ChatAttachment({
    required this.id,
    required this.messageId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    required this.createdAt,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: json['id'],
      messageId: json['message_id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      fileSize: json['file_size'],
      fileType: json['file_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'file_type': fileType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ChatAdmin {
  final int id;
  final String adminName;
  final String adminEmail;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatAdmin({
    required this.id,
    required this.adminName,
    required this.adminEmail,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatAdmin.fromJson(Map<String, dynamic> json) {
    return ChatAdmin(
      id: json['id'],
      adminName: json['admin_name'],
      adminEmail: json['admin_email'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_name': adminName,
      'admin_email': adminEmail,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ChatNotification {
  final int id;
  final int sessionId;
  final String recipientType; // 'user' or 'admin'
  final String recipientId;
  final String notificationType;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  ChatNotification({
    required this.id,
    required this.sessionId,
    required this.recipientType,
    required this.recipientId,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatNotification.fromJson(Map<String, dynamic> json) {
    return ChatNotification(
      id: json['id'],
      sessionId: json['session_id'],
      recipientType: json['recipient_type'],
      recipientId: json['recipient_id'],
      notificationType: json['notification_type'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'recipient_type': recipientType,
      'recipient_id': recipientId,
      'notification_type': notificationType,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// API Response Models
class ChatApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;

  ChatApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory ChatApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ChatApiResponse<T>(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : null,
      error: json['error'],
    );
  }
}

class ChatListResponse {
  final List<ChatMessage> messages;
  final bool hasMore;
  final int totalCount;
  final int currentPage;
  final int perPage;

  ChatListResponse({
    required this.messages,
    required this.hasMore,
    required this.totalCount,
    required this.currentPage,
    required this.perPage,
  });

  factory ChatListResponse.fromJson(Map<String, dynamic> json) {
    return ChatListResponse(
      messages: (json['messages'] as List)
          .map((message) => ChatMessage.fromJson(message))
          .toList(),
      hasMore: json['has_more'] ?? false,
      totalCount: json['total_count'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 50,
    );
  }
}
