import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';
import '../features/chat/models/red_box_message.dart';
import '../features/user/models/app_user.dart';
import 'panic_button_service.dart';
import 'connectivity_service.dart';

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
  static const String _redBoxCacheKey = 'redbox_message_cache';
  static const String _lastSyncTimeKey = 'redbox_last_sync_time';
  
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
  
  // Get the primary PIN (for comparison only, used when setting up decoy PIN)
  Future<String?> getPrimaryPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_redBoxPinKey);
    } catch (e) {
      debugPrint('Error getting primary PIN: ${e.toString()}');
      return null;
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
      final savedPin = prefs.getString(_redBoxPinKey);
      return pin == savedPin;
    } catch (e) {
      debugPrint('Error verifying PIN: ${e.toString()}');
      return false;
    }
  }
  
  // Enable/disable biometric authentication for Red Box
  Future<bool> toggleBiometricAuth(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_redBoxBiometricEnabledKey, enabled);
      return true;
    } catch (e) {
      debugPrint('Error toggling biometric auth: ${e.toString()}');
      return false;
    }
  }
  
  // Check if biometric auth is enabled
  Future<bool> isBiometricAuthEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_redBoxBiometricEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Error checking if biometric auth is enabled: ${e.toString()}');
      return false;
    }
  }
  
  // Enable/disable Red Box
  Future<bool> toggleRedBox(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_redBoxEnabledKey, enabled);
      return true;
    } catch (e) {
      debugPrint('Error toggling Red Box: ${e.toString()}');
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
  
  // Check if decoy PIN is set up
  Future<bool> isDecoyPinSetUp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final decoyPin = prefs.getString(_redBoxDecoyPinKey);
      return decoyPin != null && decoyPin.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if decoy PIN is set up: ${e.toString()}');
      return false;
    }
  }
  
  // Remove the decoy PIN
  Future<bool> removeDecoyPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_redBoxDecoyPinKey);
      return true;
    } catch (e) {
      debugPrint('Error removing decoy PIN: ${e.toString()}');
      return false;
    }
  }

  // Clear any cached Red Box data (for panic button)
  Future<void> clearRedBoxCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_redBoxCacheKey);
    } catch (e) {
      debugPrint('Error clearing Red Box cache: ${e.toString()}');
    }
  }
  
  // Red Box Chat Methods
  
  // Send a message in Red Box
  Future<void> sendRedBoxMessage({
    required String senderId,
    required String receiverId,
    required String content,
    required bool isEncrypted,
    String status = 'sent',
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      final messageId = const Uuid().v4();
      
      // Create a message document
      final messageRef = _firestore.collection(_redBoxMessagesCollection).doc(messageId);
      
      final message = {
        'id': messageId,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'timestamp': timestamp,
        'isDelivered': false,
        'isSeen': false,
        'isEncrypted': isEncrypted,
        'status': status,
      };
      
      // Try to send to Firestore if online
      final connectivityService = ConnectivityService();
      if (connectivityService.hasConnection && status != 'pending') {
        await messageRef.set(message);
      } else {
        // Store locally for offline use
        await _cacheMessageLocally(senderId, receiverId, content, isEncrypted);
      }
    } catch (e) {
      // If failed due to connectivity, cache locally
      if (e is FirebaseException && e.message?.contains('network') == true) {
        await _cacheMessageLocally(senderId, receiverId, content, isEncrypted);
      } else {
        throw Exception('Failed to send Red Box message: ${e.toString()}');
      }
    }
  }
  
  // Cache message locally when offline
  Future<void> _cacheMessageLocally(
    String senderId, 
    String receiverId, 
    String content,
    bool isEncrypted,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messageId = const Uuid().v4();
      
      // Create a local message
      final message = {
        'id': messageId,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isDelivered': false,
        'isSeen': false,
        'isEncrypted': isEncrypted,
        'status': 'pending',
      };
      
      // Get existing cache or create new one
      List<Map<String, dynamic>> cachedMessages = [];
      final cachedData = prefs.getString(_redBoxCacheKey);
      
      if (cachedData != null) {
        final decoded = jsonDecode(cachedData) as List;
        cachedMessages = decoded.cast<Map<String, dynamic>>();
      }
      
      // Add new message to cache
      cachedMessages.add(message);
      
      // Save updated cache
      await prefs.setString(_redBoxCacheKey, jsonEncode(cachedMessages));
      
    } catch (e) {
      debugPrint('Error caching message locally: ${e.toString()}');
    }
  }
  
  // Sync pending messages when back online
  Future<SyncResult> syncPendingMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_redBoxCacheKey);
      
      if (cachedData == null || cachedData.isEmpty) {
        return SyncResult(
          success: true,
          messagesSynced: 0,
          errors: [],
        );
      }
      
      final cachedMessages = jsonDecode(cachedData) as List<dynamic>;
      final syncErrors = <String>[];
      int syncedCount = 0;
      
      // Process each cached message
      for (int i = 0; i < cachedMessages.length; i++) {
        final messageData = cachedMessages[i];
        final isPending = messageData['isPending'] == true || messageData['status'] == 'pending';
        
        if (isPending) {
          try {
            // Create a message reference
            final messageId = messageData['id'];
            final messageRef = _firestore.collection(_redBoxMessagesCollection).doc(messageId);
            
            // Update the message data for consistency
            messageData['isPending'] = false;
            messageData['status'] = 'sent';
            
            // Set message data in Firestore
            await messageRef.set(messageData);
            
            syncedCount++;
          } catch (e) {
            syncErrors.add('Failed to sync message ${messageData['id']}: ${e.toString()}');
          }
        }
      }
      
      // Update the cache with the new statuses
      await prefs.setString(_redBoxCacheKey, jsonEncode(cachedMessages));
      await prefs.setString(_lastSyncTimeKey, DateTime.now().toIso8601String());
      
      return SyncResult(
        success: syncErrors.isEmpty,
        messagesSynced: syncedCount,
        errors: syncErrors,
      );
    } catch (e) {
      debugPrint('Error syncing pending messages: ${e.toString()}');
      return SyncResult(
        success: false,
        messagesSynced: 0,
        errors: ['Error syncing messages: ${e.toString()}'],
      );
    }
  }
  
  // Get messages between two users in Red Box
  Stream<List<RedBoxMessage>> getRedBoxMessages(String userId, String otherUserId, {bool isDecoyMode = false}) {
    try {
      if (isDecoyMode) {
        // For decoy mode, we'll implement this in DecoyMessageService
        return Stream.value([]);
      }
      
      // Use two separate queries instead of Filter.or
      final query1 = _firestore
          .collection(_redBoxMessagesCollection)
          .where('senderId', isEqualTo: userId)
          .where('receiverId', isEqualTo: otherUserId);
          
      final query2 = _firestore
          .collection(_redBoxMessagesCollection)
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: userId);
          
      // Combine both queries
      final combinedStream = Rx.combineLatest2(
        query1.snapshots(),
        query2.snapshots(),
        (QuerySnapshot snapshot1, QuerySnapshot snapshot2) {
          final messages = <RedBoxMessage>[];
          
          // Process first query results
          for (final doc in snapshot1.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Handle Firestore timestamp
            final timestamp = data['timestamp'] as Timestamp?;
            final dateTime = timestamp != null
                ? timestamp.toDate()
                : DateTime.now();
            
            messages.add(RedBoxMessage(
              id: data['id'] ?? doc.id,
              senderId: data['senderId'] ?? '',
              receiverId: data['receiverId'] ?? '',
              content: data['content'] ?? '',
              timestamp: dateTime,
              isSeen: data['isSeen'] ?? false,
              isDelivered: data['isDelivered'] ?? false,
              isEncrypted: data['isEncrypted'] ?? true,
            ));
          }
          
          // Process second query results
          for (final doc in snapshot2.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Handle Firestore timestamp
            final timestamp = data['timestamp'] as Timestamp?;
            final dateTime = timestamp != null
                ? timestamp.toDate()
                : DateTime.now();
            
            messages.add(RedBoxMessage(
              id: data['id'] ?? doc.id,
              senderId: data['senderId'] ?? '',
              receiverId: data['receiverId'] ?? '',
              content: data['content'] ?? '',
              timestamp: dateTime,
              isSeen: data['isSeen'] ?? false,
              isDelivered: data['isDelivered'] ?? false,
              isEncrypted: data['isEncrypted'] ?? true,
            ));
          }
          
          // Sort by timestamp
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          return _mergeCachedMessages(messages, userId, otherUserId);
        }
      );
      
      return combinedStream;
    } catch (e) {
      debugPrint('Error getting Red Box messages: ${e.toString()}');
      return Stream.value([]);
    }
  }
  
  // Merge cached messages with server messages
  Future<List<RedBoxMessage>> _mergeCachedMessagesAsync(
    List<RedBoxMessage> serverMessages,
    String userId,
    String otherUserId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_redBoxCacheKey);
      
      if (cachedData == null) return serverMessages;
      
      final decoded = jsonDecode(cachedData) as List;
      final cachedMessages = decoded.cast<Map<String, dynamic>>();
      
      if (cachedMessages.isEmpty) return serverMessages;
      
      // Filter cached messages for this conversation
      final conversationMessages = cachedMessages.where((msg) =>
          ((msg['senderId'] == userId && msg['receiverId'] == otherUserId) ||
              (msg['senderId'] == otherUserId && msg['receiverId'] == userId)) &&
          msg['isPending'] == true).toList();
      
      // Convert to RedBoxMessage objects
      final pendingMessages = conversationMessages.map((data) {
        return RedBoxMessage(
          id: data['id'],
          senderId: data['senderId'],
          receiverId: data['receiverId'],
          content: data['content'],
          timestamp: DateTime.parse(data['timestamp']),
          isSeen: data['isSeen'] ?? false,
          isDelivered: data['isDelivered'] ?? false,
          isEncrypted: data['isEncrypted'] ?? true,
        );
      }).toList();
      
      // Combine and sort messages
      final allMessages = [...serverMessages, ...pendingMessages];
      allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return allMessages;
    } catch (e) {
      debugPrint('Error merging cached messages: ${e.toString()}');
      return serverMessages;
    }
  }
  
  // Synchronous version that doesn't actually merge cached messages
  List<RedBoxMessage> _mergeCachedMessages(
    List<RedBoxMessage> serverMessages,
    String userId,
    String otherUserId,
  ) {
    // Just return the server messages for now
    // We'll implement cache merging in a different place
    return serverMessages;
  }
  
  // Get users that have Red Box chats with the current user
  Stream<List<AppUser>> getUsersWithRedBoxChats(String userId, {bool isDecoyMode = false}) {
    if (isDecoyMode) {
      // For decoy mode, we'll implement this in DecoyMessageService
      return Stream.value([]);
    }
    
    try {
      // Create a StreamController to manage our custom stream
      final controller = StreamController<List<AppUser>>();
      
      // Listen to both queries
      final querySender = _firestore
          .collection(_redBoxMessagesCollection)
          .where('senderId', isEqualTo: userId)
          .snapshots();
          
      final queryReceiver = _firestore
          .collection(_redBoxMessagesCollection)
          .where('receiverId', isEqualTo: userId)
          .snapshots();
      
      // Subscribe to both streams
      final senderSubscription = querySender.listen((senderSnapshot) {
        _processSnapshots(senderSnapshot, queryReceiver, userId, controller);
      });
      
      // Handle cleanup when the stream is cancelled
      controller.onCancel = () {
        senderSubscription.cancel();
      };
      
      return controller.stream;
    } catch (e) {
      debugPrint('Error getting users with Red Box chats: ${e.toString()}');
      return Stream.value([]);
    }
  }
  
  // Helper method to process snapshots and get user details
  void _processSnapshots(
    QuerySnapshot senderSnapshot,
    Stream<QuerySnapshot> receiverStream,
    String userId,
    StreamController<List<AppUser>> controller
  ) async {
    try {
      // Get the receiver snapshot once
      final receiverSnapshot = await receiverStream.first;
      
      // Extract unique user IDs
      final userIds = <String>{};
      
      // Process sender results
      for (final doc in senderSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final receiverId = data['receiverId'] as String?;
        if (receiverId != null) {
          userIds.add(receiverId);
        }
      }
      
      // Process receiver results
      for (final doc in receiverSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final senderId = data['senderId'] as String?;
        if (senderId != null) {
          userIds.add(senderId);
        }
      }
      
      if (userIds.isEmpty) {
        controller.add([]);
        return;
      }
      
      // Get user details - but this will need to be done in batches
      // since Firestore 'whereIn' is limited to 10 values
      final userIdsList = userIds.toList();
      final List<AppUser> allUsers = [];
      
      // Process users in batches of 10
      for (int i = 0; i < userIdsList.length; i += 10) {
        final end = (i + 10 < userIdsList.length) ? i + 10 : userIdsList.length;
        final batch = userIdsList.sublist(i, end);
        
        // Query this batch of users
        final userSnapshot = await _firestore
          .collection(_usersCollection)
          .where('uid', whereIn: batch)
          .get();
          
        // Process user data
        for (final doc in userSnapshot.docs) {
          final data = doc.data();
          
          allUsers.add(AppUser(
            uid: data['uid'] ?? doc.id,
            email: data['email'] ?? '',
            username: data['username'] ?? data['email'] ?? '',
            displayName: data['displayName'] ?? 'User',
            profilePicUrl: data['profilePicUrl'] ?? '',
          ));
        }
      }
      
      // Add the users to the stream
      controller.add(allUsers);
    } catch (e) {
      debugPrint('Error processing snapshots: ${e.toString()}');
      controller.add([]);
    }
  }
  
  // Get the latest message between two users in Red Box
  Stream<RedBoxMessage?> getLatestRedBoxMessage(String userId, String otherUserId, {bool isDecoyMode = false}) {
    if (isDecoyMode) {
      // For decoy mode, we'll implement this in DecoyMessageService
      return Stream.value(null);
    }
    
    try {
      // Use two separate queries and combine results
      final query1 = _firestore
          .collection(_redBoxMessagesCollection)
          .where('senderId', isEqualTo: userId)
          .where('receiverId', isEqualTo: otherUserId)
          .orderBy('timestamp', descending: true)
          .limit(1);
          
      final query2 = _firestore
          .collection(_redBoxMessagesCollection)
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1);
      
      return Rx.combineLatest2(
        query1.snapshots(),
        query2.snapshots(),
        (QuerySnapshot snapshot1, QuerySnapshot snapshot2) {
          // Check which snapshot has the most recent message, or if both are empty
          if (snapshot1.docs.isEmpty && snapshot2.docs.isEmpty) {
            return null;
          }
          
          DocumentSnapshot? latestDoc;
          
          if (snapshot1.docs.isEmpty) {
            latestDoc = snapshot2.docs.first;
          } else if (snapshot2.docs.isEmpty) {
            latestDoc = snapshot1.docs.first;
          } else {
            // Compare timestamps to find the latest message
            final data1 = snapshot1.docs.first.data() as Map<String, dynamic>;
            final data2 = snapshot2.docs.first.data() as Map<String, dynamic>;
            final timestamp1 = data1['timestamp'] as Timestamp;
            final timestamp2 = data2['timestamp'] as Timestamp;
            
            latestDoc = timestamp1.compareTo(timestamp2) > 0
                ? snapshot1.docs.first
                : snapshot2.docs.first;
          }
          
          if (latestDoc == null) {
            return null;
          }
          
          final data = latestDoc.data() as Map<String, dynamic>;
          
          // Handle Firestore timestamp
          final timestamp = data['timestamp'] as Timestamp?;
          final dateTime = timestamp != null
              ? timestamp.toDate()
              : DateTime.now();
          
          return RedBoxMessage(
            id: data['id'] ?? latestDoc.id,
            senderId: data['senderId'] ?? '',
            receiverId: data['receiverId'] ?? '',
            content: data['content'] ?? '',
            timestamp: dateTime,
            isSeen: data['isSeen'] ?? false,
            isDelivered: data['isDelivered'] ?? false,
            isEncrypted: data['isEncrypted'] ?? true,
          );
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

  // Check if there are any pending messages that need to be synced
  Future<bool> hasPendingMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_redBoxCacheKey);
      
      if (cachedData == null || cachedData.isEmpty) {
        return false;
      }
      
      final cachedMessages = jsonDecode(cachedData) as List<dynamic>;
      
      // Check if any cached messages are marked as pending
      for (final messageData in cachedMessages) {
        if (messageData['status'] == 'pending') {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking for pending messages: ${e.toString()}');
      return false;
    }
  }
  
  // Get count of pending messages
  Future<int> getPendingMessageCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_redBoxCacheKey);
      
      if (cachedData == null || cachedData.isEmpty) {
        return 0;
      }
      
      final cachedMessages = jsonDecode(cachedData) as List<dynamic>;
      
      // Count cached messages that are marked as pending
      int pendingCount = 0;
      for (final messageData in cachedMessages) {
        if (messageData['status'] == 'pending') {
          pendingCount++;
        }
      }
      
      return pendingCount;
    } catch (e) {
      debugPrint('Error getting pending message count: ${e.toString()}');
      return 0;
    }
  }



  // Method to cache all user data for offline use
  Future<bool> cacheAppData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cache user contacts
      final contacts = await _cacheUserContacts(userId);
      
      // Cache recent messages for each contact
      int cachedMessagesCount = 0;
      for (final contact in contacts) {
        final messages = await _cacheContactMessages(userId, contact.uid);
        cachedMessagesCount += messages;
      }
      
      // Store last cache time
      await prefs.setInt('app_data_last_cache_time', DateTime.now().millisecondsSinceEpoch);
      
      return true;
    } catch (e) {
      debugPrint('Error caching app data: ${e.toString()}');
      return false;
    }
  }
  
  // Helper method to cache user contacts
  Future<List<AppUser>> _cacheUserContacts(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsSnapshot = await _firestore
          .collection(_usersCollection)
          .get();
      
      final List<Map<String, dynamic>> contactsData = [];
      final List<AppUser> contacts = [];
      
      for (final doc in contactsSnapshot.docs) {
        final userData = doc.data();
        
        // Skip current user
        if (doc.id == userId) continue;
        
        contactsData.add(userData);
        
        final appUser = AppUser(
          uid: doc.id,
          email: userData['email'] ?? '',
          username: userData['username'] ?? '',
          displayName: userData['displayName'] ?? '',
          profilePicUrl: userData['profilePicUrl'] ?? '',
        );
        
        contacts.add(appUser);
      }
      
      // Store contacts data
      await prefs.setString('cached_contacts', jsonEncode(contactsData));
      
      return contacts;
    } catch (e) {
      debugPrint('Error caching contacts: ${e.toString()}');
      return [];
    }
  }
  
  // Helper method to cache messages for a specific contact
  Future<int> _cacheContactMessages(String userId, String contactId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get the most recent messages (limit to 50)
      final messagesSnapshot = await _firestore
          .collection(_redBoxMessagesCollection)
          .where('senderId', whereIn: [userId, contactId])
          .where('receiverId', whereIn: [userId, contactId])
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      final List<Map<String, dynamic>> messagesData = [];
      
      for (final doc in messagesSnapshot.docs) {
        messagesData.add(doc.data());
      }
      
      // Store messages for this contact
      final cacheKey = 'cached_messages_${userId}_$contactId';
      await prefs.setString(cacheKey, jsonEncode(messagesData));
      
      return messagesData.length;
    } catch (e) {
      debugPrint('Error caching messages for contact $contactId: ${e.toString()}');
      return 0;
    }
  }

  // Get cached contacts when offline
  Future<List<AppUser>> getCachedContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_contacts');
      
      if (cachedData == null || cachedData.isEmpty) {
        return [];
      }
      
      final contactsData = jsonDecode(cachedData) as List<dynamic>;
      final contacts = <AppUser>[];
      
      for (final userData in contactsData) {
        contacts.add(AppUser(
          uid: userData['uid'] ?? '',
          email: userData['email'] ?? '',
          username: userData['username'] ?? '',
          displayName: userData['displayName'] ?? '',
          profilePicUrl: userData['profilePicUrl'] ?? '',
        ));
      }
      
      return contacts;
    } catch (e) {
      debugPrint('Error getting cached contacts: ${e.toString()}');
      return [];
    }
  }
  
  // Get cached messages for a specific contact when offline
  Future<List<RedBoxMessage>> getCachedContactMessages(String userId, String contactId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_messages_${userId}_$contactId';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData == null || cachedData.isEmpty) {
        return [];
      }
      
      final messagesData = jsonDecode(cachedData) as List<dynamic>;
      final messages = <RedBoxMessage>[];
      
      for (final messageData in messagesData) {
        messages.add(RedBoxMessage(
          id: messageData['id'] ?? '',
          senderId: messageData['senderId'] ?? '',
          receiverId: messageData['receiverId'] ?? '',
          content: messageData['content'] ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(messageData['timestamp'] ?? 0),
          isSeen: messageData['isSeen'] ?? false,
          isDelivered: messageData['isDelivered'] ?? false,
          isEncrypted: messageData['isEncrypted'] ?? true,
        ));
      }
      
      // Sort by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return messages;
    } catch (e) {
      debugPrint('Error getting cached messages for contact $contactId: ${e.toString()}');
      return [];
    }
  }
  
  // Check if app data is cached and fresh (less than 24 hours old)
  Future<bool> hasFreshCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCacheTimeMs = prefs.getInt('app_data_last_cache_time');
      
      if (lastCacheTimeMs == null) {
        return false;
      }
      
      final lastCacheTime = DateTime.fromMillisecondsSinceEpoch(lastCacheTimeMs);
      final now = DateTime.now();
      
      // Data is fresh if cached less than 24 hours ago
      return now.difference(lastCacheTime).inHours < 24;
    } catch (e) {
      debugPrint('Error checking cached data freshness: ${e.toString()}');
      return false;
    }
  }
}

// Class to represent sync operation results
class SyncResult {
  final bool success;
  final int messagesSynced;
  final List<String> errors;
  
  SyncResult({
    required this.success,
    required this.messagesSynced,
    required this.errors,
  });
} 