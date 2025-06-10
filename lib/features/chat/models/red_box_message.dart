import 'package:flutter/foundation.dart';

class RedBoxMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isSeen;
  final bool isDelivered;
  final bool isEncrypted;
  final String status;

  RedBoxMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isSeen = false,
    this.isDelivered = false,
    this.isEncrypted = true,
    this.status = 'sent',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'isSeen': isSeen,
    'isDelivered': isDelivered,
    'isEncrypted': isEncrypted,
    'status': status,
  };

  factory RedBoxMessage.fromMap(Map<String, dynamic> map) => RedBoxMessage(
    id: map['id'] ?? '',
    senderId: map['senderId'] ?? '',
    receiverId: map['receiverId'] ?? '',
    content: map['content'] ?? '',
    timestamp: map['timestamp'] != null 
        ? (map['timestamp'] is DateTime 
            ? map['timestamp'] 
            : DateTime.fromMillisecondsSinceEpoch(map['timestamp']))
        : DateTime.now(),
    isSeen: map['isSeen'] ?? false,
    isDelivered: map['isDelivered'] ?? false,
    isEncrypted: map['isEncrypted'] ?? true,
    status: map['status'] ?? 'sent',
  );
  
  RedBoxMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isSeen,
    bool? isDelivered,
    bool? isEncrypted,
    String? status,
  }) {
    return RedBoxMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isSeen: isSeen ?? this.isSeen,
      isDelivered: isDelivered ?? this.isDelivered,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      status: status ?? this.status,
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