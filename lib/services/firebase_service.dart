import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../features/user/models/app_user.dart';
import '../features/chat/models/message.dart';
import 'package:rxdart/rxdart.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collections
  final String _usersCollection = 'users';
  final String _messagesCollection = 'messages';

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Get current user stream
  Stream<User?> get userStream => _auth.authStateChanges();
  
  // Authentication methods
  Future<Map<String, dynamic>> registerUser(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return {
        'user': {
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
        }
      };
    } catch (e) {
      throw Exception('Failed to register user: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return {
        'user': {
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
        }
      };
    } catch (e) {
      throw Exception('Invalid email or password');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // User profile methods
  Future<void> createUserProfile(AppUser user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: ${e.toString()}');
      return null;
    }
  }

  Future<AppUser?> getCurrentUserProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return getUserProfile(uid);
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('username', isEqualTo: username)
          .get();
      
      return query.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check username availability: ${e.toString()}');
    }
  }

  Future<List<AppUser>> searchUsersByUsername(String query) async {
    try {
      // Use case insensitive search if your Firebase plan supports it
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: query + 'z')
          .get();
      
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error searching users: ${e.toString()}');
      return [];
    }
  }

  // Chat methods
  Future<void> sendMessage(
    String senderId,
    String receiverId,
    String content,
  ) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      
      // Create a message document
      final messageRef = _firestore.collection(_messagesCollection).doc();
      
      final message = {
        'id': messageRef.id,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'timestamp': timestamp,
        'isDelivered': false,
        'isSeen': false,
      };
      
      await messageRef.set(message);
      
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Stream<List<Message>> getMessages(String userId1, String userId2) {
    try {
      // Use two separate queries with simpler index requirements
      final query1 = _firestore
          .collection(_messagesCollection)
          .where('senderId', isEqualTo: userId1)
          .where('receiverId', isEqualTo: userId2)
          .orderBy('timestamp', descending: true)
          .snapshots();
          
      final query2 = _firestore
          .collection(_messagesCollection)
          .where('senderId', isEqualTo: userId2)
          .where('receiverId', isEqualTo: userId1)
          .orderBy('timestamp', descending: true)
          .snapshots();
          
      // Combine the streams
      return Rx.combineLatest2<QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>, List<Message>>(
        query1,
        query2,
        (snapshot1, snapshot2) {
          final messages = <Message>[];
          
          // Process messages from user1 to user2
          for (var doc in snapshot1.docs) {
            try {
              final data = doc.data();
              messages.add(Message.fromMap(data));
            } catch (e) {
              debugPrint('Error parsing message: $e');
            }
          }
          
          // Process messages from user2 to user1
          for (var doc in snapshot2.docs) {
            try {
              final data = doc.data();
              messages.add(Message.fromMap(data));
            } catch (e) {
              debugPrint('Error parsing message: $e');
            }
          }
          
          // Sort all messages by timestamp
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages;
        },
      );
    } catch (e) {
      debugPrint('Error getting messages: ${e.toString()}');
      return Stream.value([]);
    }
  }

  // Mark message as delivered
  Future<void> markMessageAsDelivered(String messageId) async {
    try {
      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .update({'isDelivered': true});
    } catch (e) {
      debugPrint('Error marking message as delivered: ${e.toString()}');
    }
  }

  // Mark message as read
  Future<void> markMessageAsSeen(String messageId) async {
    try {
      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .update({'isSeen': true});
    } catch (e) {
      debugPrint('Error marking message as read: ${e.toString()}');
    }
  }

  // Upload profile picture
  Future<String> uploadProfilePicture(String userId, dynamic file) async {
    try {
      final ref = _storage.ref().child('profile_pictures').child('$userId.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload profile picture: ${e.toString()}');
    }
  }

  // Get all users with recent chats
  Stream<List<AppUser>> getUsersWithChats(String currentUserId) {
    try {
      // Use two separate queries but make them more efficient
      final sentMessagesQuery = _firestore
          .collection(_messagesCollection)
          .where('senderId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to most recent
          .snapshots();
          
      final receivedMessagesQuery = _firestore
          .collection(_messagesCollection)
          .where('receiverId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to most recent
          .snapshots();
      
      // First, collect the user IDs from both streams
      final userIdsStream = Rx.combineLatest2<QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>, Set<String>>(
        sentMessagesQuery,
        receivedMessagesQuery,
        (sentSnapshot, receivedSnapshot) {
          final uniqueUserIds = <String>{};
          
          // Process sent messages
          for (var doc in sentSnapshot.docs) {
            final data = doc.data();
            final receiverId = data['receiverId'] as String;
            if (receiverId != currentUserId) uniqueUserIds.add(receiverId);
          }
          
          // Process received messages
          for (var doc in receivedSnapshot.docs) {
            final data = doc.data();
            final senderId = data['senderId'] as String;
            if (senderId != currentUserId) uniqueUserIds.add(senderId);
          }
          
          return uniqueUserIds;
        },
      );
      
      // Then convert the user IDs to AppUser objects with caching optimization
      return userIdsStream.asyncMap((uniqueUserIds) async {
        final users = <AppUser>[];
        final futures = <Future<AppUser?>>[];
        
        // Create parallel requests for better performance
        for (final id in uniqueUserIds) {
          futures.add(getUserProfile(id));
        }
        
        // Wait for all requests to complete
        final results = await Future.wait(futures);
        
        // Add non-null results to the list
        for (final user in results) {
          if (user != null) {
            users.add(user);
          }
        }
        
        return users;
      });
    } catch (e) {
      debugPrint('Error getting users with chats: ${e.toString()}');
      return Stream.value([]);
    }
  }
  
  // Get latest message between two users
  Stream<Message?> getLatestMessage(String userId1, String userId2) {
    try {
      // Use two separate queries with simpler index requirements
      final query1 = _firestore
          .collection(_messagesCollection)
          .where('senderId', isEqualTo: userId1)
          .where('receiverId', isEqualTo: userId2)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots();
          
      final query2 = _firestore
          .collection(_messagesCollection)
          .where('senderId', isEqualTo: userId2)
          .where('receiverId', isEqualTo: userId1)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots();
      
      // Combine the streams
      return Rx.combineLatest2<QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>, Message?>(
        query1,
        query2,
        (snapshot1, snapshot2) {
          final messages = <Message>[];
          
          // Process messages from user1 to user2
          if (snapshot1.docs.isNotEmpty) {
            try {
              final doc = snapshot1.docs.first;
              final data = doc.data();
              messages.add(Message.fromMap(data));
            } catch (e) {
              debugPrint('Error parsing message: $e');
            }
          }
          
          // Process messages from user2 to user1
          if (snapshot2.docs.isNotEmpty) {
            try {
              final doc = snapshot2.docs.first;
              final data = doc.data();
              messages.add(Message.fromMap(data));
            } catch (e) {
              debugPrint('Error parsing message: $e');
            }
          }
          
          // Return the most recent message
          if (messages.isEmpty) return null;
          
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages.first;
        },
      );
    } catch (e) {
      debugPrint('Error getting latest message: ${e.toString()}');
      return Stream.value(null);
    }
  }
} 