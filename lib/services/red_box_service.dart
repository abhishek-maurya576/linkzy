import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';
import '../features/chat/models/red_box_message.dart';
import '../features/user/models/app_user.dart';

class RedBoxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collections
  final String _redBoxMessagesCollection = 'redbox_messages';
  final String _usersCollection = 'users';

  // Secure storage keys
  static const String _redBoxPinKey = 'redbox_pin';
  static const String _redBoxEnabledKey = 'redbox_enabled';
  static const String _redBoxBiometricEnabledKey = 'redbox_biometric_enabled';
  static const String _redBoxDecoyPinKey = 'redbox_decoy_pin';
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Check if Red Box is set up
  Future<bool> isRedBoxSetUp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pin = prefs.getString(_redBoxPinKey);
      return pin != null && pin.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if Red Box is set up: ${e.toString()}');
      return false;
    }
  }
  
  // Set up Red Box with PIN
  Future<bool> setupRedBox(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_redBoxPinKey, pin);
      await prefs.setBool(_redBoxEnabledKey, true);
      return true;
    } catch (e) {
      debugPrint('Error setting up Red Box: ${e.toString()}');
      return false;
    }
  }
  
  // Verify Red Box PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPin = prefs.getString(_redBoxPinKey);
      return storedPin == pin;
    } catch (e) {
      debugPrint('Error verifying PIN: ${e.toString()}');
      return false;
    }
  }
  
  // Change Red Box PIN
  Future<bool> changePin(String newPin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_redBoxPinKey, newPin);
      return true;
    } catch (e) {
      debugPrint('Error changing PIN: ${e.toString()}');
      return false;
    }
  }
  
  // Enable/disable biometric authentication
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_redBoxBiometricEnabledKey, enabled);
      return true;
    } catch (e) {
      debugPrint('Error setting biometric authentication: ${e.toString()}');
      return false;
    }
  }
  
  // Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_redBoxBiometricEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Error checking if biometric authentication is enabled: ${e.toString()}');
      return false;
    }
  }
  
  // Enable/disable Red Box
  Future<bool> setRedBoxEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_redBoxEnabledKey, enabled);
      return true;
    } catch (e) {
      debugPrint('Error enabling/disabling Red Box: ${e.toString()}');
      return false;
    }
  }
  
  // Check if Red Box is enabled
  Future<bool> isRedBoxEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_redBoxEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Error checking if Red Box is enabled: ${e.toString()}');
      return false;
    }
  }
  
  // Set up decoy PIN
  Future<bool> setupDecoyPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_redBoxDecoyPinKey, pin);
      return true;
    } catch (e) {
      debugPrint('Error setting up decoy PIN: ${e.toString()}');
      return false;
    }
  }
  
  // Check if the PIN is a decoy
  Future<bool> isDecoyPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final decoyPin = prefs.getString(_redBoxDecoyPinKey);
      return decoyPin == pin;
    } catch (e) {
      debugPrint('Error checking if PIN is decoy: ${e.toString()}');
      return false;
    }
  }
  
  // Red Box Chat Methods
  
  // Send a message in Red Box
  Future<void> sendRedBoxMessage(
    String senderId,
    String receiverId,
    String content,
  ) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      
      // Create a message document
      final messageRef = _firestore.collection(_redBoxMessagesCollection).doc();
      
      final message = {
        'id': messageRef.id,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'timestamp': timestamp,
        'isDelivered': false,
        'isSeen': false,
        'isEncrypted': true,
      };
      
      await messageRef.set(message);
      
    } catch (e) {
      throw Exception('Failed to send Red Box message: ${e.toString()}');
    }
  }
  
  // Get messages between two users in Red Box
  Stream<List<RedBoxMessage>> getRedBoxMessages(String userId, String otherUserId) {
    try {
      // Get messages where current user is the sender and other user is the receiver
      final sentMessagesQuery = _firestore
          .collection(_redBoxMessagesCollection)
          .where('senderId', isEqualTo: userId)
          .where('receiverId', isEqualTo: otherUserId)
          .orderBy('timestamp', descending: true)
          .limit(50);
          
      // Get messages where current user is the receiver and other user is the sender
      final receivedMessagesQuery = _firestore
          .collection(_redBoxMessagesCollection)
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50);
      
      // Combine both streams
      return Rx.combineLatest2<QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>, List<RedBoxMessage>>(
        sentMessagesQuery.snapshots(),
        receivedMessagesQuery.snapshots(),
        (sentSnapshot, receivedSnapshot) {
          final messages = <RedBoxMessage>[];
          
          // Process sent messages
          for (final doc in sentSnapshot.docs) {
            messages.add(RedBoxMessage.fromMap(doc.data()));
          }
          
          // Process received messages
          for (final doc in receivedSnapshot.docs) {
            messages.add(RedBoxMessage.fromMap(doc.data()));
          }
          
          // Sort combined messages by timestamp (oldest first)
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          return messages;
        }
      );
    } catch (e) {
      debugPrint('Error getting Red Box messages: ${e.toString()}');
      return Stream.value([]);
    }
  }
  
  // Get users with Red Box chats
  Stream<List<AppUser>> getUsersWithRedBoxChats(String currentUserId) {
    try {
      // Get chats where current user is sender
      final sentMessagesQuery = _firestore
          .collection(_redBoxMessagesCollection)
          .where('senderId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots();
          
      // Get chats where current user is receiver
      final receivedMessagesQuery = _firestore
          .collection(_redBoxMessagesCollection)
          .where('receiverId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots();
      
      // Combine the streams and get unique user IDs with timestamps
      final combinedStream = Rx.combineLatest2(
        sentMessagesQuery,
        receivedMessagesQuery,
        (QuerySnapshot<Map<String, dynamic>> sent, QuerySnapshot<Map<String, dynamic>> received) {
          // Map of userId -> timestamp for sorting by latest message
          final userTimestamps = <String, dynamic>{};
          
          // Process sent messages
          for (final doc in sent.docs) {
            final data = doc.data();
            final receiverId = data['receiverId'] as String;
            final timestamp = data['timestamp'];
            
            // Only consider other users, not self
            if (receiverId != currentUserId) {
              // If this is a newer message than previously seen for this user
              if (!userTimestamps.containsKey(receiverId) || 
                  timestamp != null && 
                  _compareTimestamps(timestamp, userTimestamps[receiverId])) {
                userTimestamps[receiverId] = timestamp;
              }
            }
          }
          
          // Process received messages
          for (final doc in received.docs) {
            final data = doc.data();
            final senderId = data['senderId'] as String;
            final timestamp = data['timestamp'];
            
            // Only consider other users, not self
            if (senderId != currentUserId) {
              // If this is a newer message than previously seen for this user
              if (!userTimestamps.containsKey(senderId) || 
                  timestamp != null && 
                  _compareTimestamps(timestamp, userTimestamps[senderId])) {
                userTimestamps[senderId] = timestamp;
              }
            }
          }
          
          return userTimestamps;
        },
      );
      
      // Get user profiles for the IDs
      return combinedStream.asyncMap((userTimestamps) async {
        final users = <AppUser>[];
        
        // Get user details for each ID
        for (final entry in userTimestamps.entries) {
          final userId = entry.key;
          
          try {
            final userDoc = await _firestore
                .collection(_usersCollection)
                .doc(userId)
                .get();
            
            if (userDoc.exists) {
              users.add(AppUser.fromMap(userDoc.data()!));
            }
          } catch (e) {
            debugPrint('Error getting user $userId: ${e.toString()}');
            // Continue with other users even if one fails
          }
        }
        
        return users;
      });
    } catch (e) {
      debugPrint('Error getting users with Red Box chats: ${e.toString()}');
      return Stream.value([]);
    }
  }
  
  // Helper method to compare timestamps for sorting
  bool _compareTimestamps(dynamic timestamp1, dynamic timestamp2) {
    if (timestamp1 == null) return false;
    if (timestamp2 == null) return true;
    
    try {
      // Convert Firebase timestamps to DateTime for comparison
      DateTime dt1;
      DateTime dt2;
      
      if (timestamp1 is DateTime) {
        dt1 = timestamp1;
      } else if (timestamp1.runtimeType.toString().contains('Timestamp')) {
        dt1 = timestamp1.toDate();
      } else if (timestamp1 is String) {
        dt1 = DateTime.parse(timestamp1);
      } else {
        return false;
      }
      
      if (timestamp2 is DateTime) {
        dt2 = timestamp2;
      } else if (timestamp2.runtimeType.toString().contains('Timestamp')) {
        dt2 = timestamp2.toDate();
      } else if (timestamp2 is String) {
        dt2 = DateTime.parse(timestamp2);
      } else {
        return true;
      }
      
      // Return true if timestamp1 is more recent than timestamp2
      return dt1.isAfter(dt2);
    } catch (e) {
      debugPrint('Error comparing timestamps: ${e.toString()}');
      return false;
    }
  }
  
  // Get latest Red Box message between two users
  Stream<RedBoxMessage?> getLatestRedBoxMessage(String userId, String otherUserId) {
    try {
      // Get latest message where current user is sender and other user is receiver
      final sentMessageQuery = _firestore
          .collection(_redBoxMessagesCollection)
          .where('senderId', isEqualTo: userId)
          .where('receiverId', isEqualTo: otherUserId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots();
          
      // Get latest message where other user is sender and current user is receiver
      final receivedMessageQuery = _firestore
          .collection(_redBoxMessagesCollection)
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots();
      
      // Combine streams and return the most recent message
      return Rx.combineLatest2<QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>, RedBoxMessage?>(
        sentMessageQuery,
        receivedMessageQuery,
        (sentSnapshot, receivedSnapshot) {
          final messages = <RedBoxMessage>[];
          
          // Add sent message if exists
          if (sentSnapshot.docs.isNotEmpty) {
            messages.add(RedBoxMessage.fromMap(sentSnapshot.docs.first.data()));
          }
          
          // Add received message if exists
          if (receivedSnapshot.docs.isNotEmpty) {
            messages.add(RedBoxMessage.fromMap(receivedSnapshot.docs.first.data()));
          }
          
          // Return the most recent message or null if no messages
          if (messages.isEmpty) {
            return null;
          }
          
          // Sort by timestamp (newest first)
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages.first;
        }
      );
    } catch (e) {
      debugPrint('Error getting latest Red Box message: ${e.toString()}');
      return Stream.value(null);
    }
  }
  
  // Mark Red Box message as delivered
  Future<void> markRedBoxMessageAsDelivered(String messageId) async {
    try {
      await _firestore
          .collection(_redBoxMessagesCollection)
          .doc(messageId)
          .update({'isDelivered': true});
    } catch (e) {
      debugPrint('Error marking Red Box message as delivered: ${e.toString()}');
    }
  }
  
  // Mark Red Box message as seen
  Future<void> markRedBoxMessageAsSeen(String messageId) async {
    try {
      await _firestore
          .collection(_redBoxMessagesCollection)
          .doc(messageId)
          .update({'isSeen': true});
    } catch (e) {
      debugPrint('Error marking Red Box message as seen: ${e.toString()}');
    }
  }
} 