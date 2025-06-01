import '../models/app_user.dart';

class Contact {
  final String id;
  final String userId; // Owner of the contact (current user)
  final String contactId; // ID of the user saved as contact
  final String contactName; // Optional custom contact name
  final DateTime createdAt;
  final AppUser? userDetails; // Optional user details object

  Contact({
    required this.id,
    required this.userId,
    required this.contactId,
    this.contactName = '',
    required this.createdAt,
    this.userDetails,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'contactId': contactId,
    'contactName': contactName,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Contact.fromMap(Map<String, dynamic> map, {AppUser? user}) => Contact(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    contactId: map['contactId'] ?? '',
    contactName: map['contactName'] ?? '',
    createdAt: map['createdAt'] != null 
      ? DateTime.parse(map['createdAt']) 
      : DateTime.now(),
    userDetails: user,
  );
} 