class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isSeen;
  final bool isDelivered;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isSeen = false,
    this.isDelivered = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
    'timestamp': timestamp,
    'isSeen': isSeen,
    'isDelivered': isDelivered,
  };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
    id: map['id'] ?? '',
    senderId: map['senderId'] ?? '',
    receiverId: map['receiverId'] ?? '',
    content: map['content'] ?? '',
    timestamp: _parseTimestamp(map['timestamp']),
    isSeen: map['isSeen'] ?? false,
    isDelivered: map['isDelivered'] ?? false,
  );
  
  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isSeen,
    bool? isDelivered,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isSeen: isSeen ?? this.isSeen,
      isDelivered: isDelivered ?? this.isDelivered,
    );
  }

  // Helper method to parse different timestamp formats from Firestore
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    // Handle Firestore Timestamp
    if (timestamp is DateTime) return timestamp;
    
    // Handle Firestore Timestamp (from server)
    if (timestamp.runtimeType.toString().contains('Timestamp')) {
      return timestamp.toDate();
    }
    
    // Handle ISO8601 string
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }
} 