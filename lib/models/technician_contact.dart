class TechnicianMessage {
  final String senderId;
  final String text;
  final String sentAt;

  const TechnicianMessage({
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'text': text,
        'sentAt': sentAt,
      };

  factory TechnicianMessage.fromJson(Map<String, dynamic> json) {
    return TechnicianMessage(
      senderId: json['senderId']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      sentAt: json['sentAt']?.toString() ?? '',
    );
  }
}

class TechnicianThread {
  final String id;
  final String customerId;
  final String customerName;
  final String technicianOwnerId;
  final String technicianName;
  final List<TechnicianMessage> messages;

  const TechnicianThread({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.technicianOwnerId,
    required this.technicianName,
    required this.messages,
  });

  static String makeId(String customerId, String technicianOwnerId) {
    return '$customerId::$technicianOwnerId';
  }

  TechnicianMessage? get lastMessage =>
      messages.isEmpty ? null : messages.last;

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'technicianOwnerId': technicianOwnerId,
        'technicianName': technicianName,
        'messages': messages.map((message) => message.toJson()).toList(),
      };

  factory TechnicianThread.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    return TechnicianThread(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      technicianOwnerId: json['technicianOwnerId']?.toString() ?? '',
      technicianName: json['technicianName']?.toString() ?? '',
      messages: rawMessages is List
          ? rawMessages
              .whereType<Map>()
              .map((item) => TechnicianMessage.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }
}

class TechnicianReview {
  final String customerId;
  final String customerName;
  final String technicianOwnerId;
  final int stars;
  final String comment;
  final String createdAt;

  const TechnicianReview({
    required this.customerId,
    required this.customerName,
    required this.technicianOwnerId,
    required this.stars,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'customerName': customerName,
        'technicianOwnerId': technicianOwnerId,
        'stars': stars,
        'comment': comment,
        'createdAt': createdAt,
      };

  factory TechnicianReview.fromJson(Map<String, dynamic> json) {
    return TechnicianReview(
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      technicianOwnerId: json['technicianOwnerId']?.toString() ?? '',
      stars: _asInt(json['stars']),
      comment: json['comment']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
