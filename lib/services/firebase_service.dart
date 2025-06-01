import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../features/user/models/app_user.dart';
import '../features/user/models/contact.dart';
import '../features/chat/models/message.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collections
  final String _usersCollection = 'users';
  final String _messagesCollection = 'messages';
  final String _contactsCollection = 'contacts';

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

  // Update user profile with avatar
  Future<void> updateUserWithAvatar(AppUser user, String avatarPath) async {
    try {
      // The avatarPath is the local asset path, we just store it directly
      final updatedUser = user.copyWith(profilePicUrl: avatarPath);
      await createUserProfile(updatedUser);
    } catch (e) {
      throw Exception('Failed to update user with avatar: ${e.toString()}');
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
      
      // First, collect the user IDs from both streams with their latest timestamps
      final userIdsStream = Rx.combineLatest2<QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>, Map<String, dynamic>>(
        sentMessagesQuery,
        receivedMessagesQuery,
        (sentSnapshot, receivedSnapshot) {
          final userTimestamps = <String, dynamic>{};
          
          // Process sent messages
          for (var doc in sentSnapshot.docs) {
            final data = doc.data();
            final receiverId = data['receiverId'] as String;
            final timestamp = data['timestamp'];
            
            if (receiverId != currentUserId) {
              if (!userTimestamps.containsKey(receiverId) || 
                  timestamp != null && (userTimestamps[receiverId] == null || 
                  timestamp.compareTo(userTimestamps[receiverId]) > 0)) {
                userTimestamps[receiverId] = timestamp;
              }
            }
          }
          
          // Process received messages
          for (var doc in receivedSnapshot.docs) {
            final data = doc.data();
            final senderId = data['senderId'] as String;
            final timestamp = data['timestamp'];
            
            if (senderId != currentUserId) {
              if (!userTimestamps.containsKey(senderId) || 
                  timestamp != null && (userTimestamps[senderId] == null || 
                  timestamp.compareTo(userTimestamps[senderId]) > 0)) {
                userTimestamps[senderId] = timestamp;
              }
            }
          }
          
          return userTimestamps;
        },
      );
      
      // Then convert the user IDs to AppUser objects with caching optimization
      return userIdsStream.asyncMap((userTimestamps) async {
        final userEntries = userTimestamps.entries.toList();
        final users = <AppUser>[];
        final usersWithTimestamps = <Map<String, dynamic>>[];
        final futures = <Future<AppUser?>>[];
        
        // Create parallel requests for better performance
        for (final entry in userEntries) {
          futures.add(getUserProfile(entry.key));
        }
        
        // Wait for all requests to complete
        final results = await Future.wait(futures);
        
        // Add non-null results to the list with their timestamps
        for (int i = 0; i < results.length; i++) {
          final user = results[i];
          if (user != null) {
            usersWithTimestamps.add({
              'user': user,
              'timestamp': userTimestamps[userEntries[i].key]
            });
          }
        }
        
        // Sort by timestamp (descending)
        usersWithTimestamps.sort((a, b) {
          final timestampA = a['timestamp'];
          final timestampB = b['timestamp'];
          
          if (timestampA == null && timestampB == null) return 0;
          if (timestampA == null) return 1;
          if (timestampB == null) return -1;
          
          return timestampB.compareTo(timestampA);
        });
        
        // Extract only the users from the sorted list
        for (final item in usersWithTimestamps) {
          users.add(item['user'] as AppUser);
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

  // Contact management methods
  Future<Contact> addContact(String contactUserId, {String customName = ''}) async {
    try {
      final currentUid = currentUserId;
      if (currentUid == null) {
        throw Exception('You must be logged in to add contacts');
      }

      // Check if contact already exists
      final existingContact = await _firestore
          .collection(_contactsCollection)
          .where('userId', isEqualTo: currentUid)
          .where('contactId', isEqualTo: contactUserId)
          .get();

      if (existingContact.docs.isNotEmpty) {
        throw Exception('This contact already exists in your contacts');
      }

      // Create new contact
      final contactId = const Uuid().v4();
      final contactData = Contact(
        id: contactId,
        userId: currentUid,
        contactId: contactUserId,
        contactName: customName,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_contactsCollection)
          .doc(contactId)
          .set(contactData.toMap());

      return contactData;
    } catch (e) {
      throw Exception('Failed to add contact: ${e.toString()}');
    }
  }

  Future<void> removeContact(String contactId) async {
    try {
      final currentUid = currentUserId;
      if (currentUid == null) {
        throw Exception('You must be logged in to remove contacts');
      }

      await _firestore
          .collection(_contactsCollection)
          .doc(contactId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove contact: ${e.toString()}');
    }
  }

  Future<void> updateContactName(String contactId, String newName) async {
    try {
      final currentUid = currentUserId;
      if (currentUid == null) {
        throw Exception('You must be logged in to update contacts');
      }

      await _firestore
          .collection(_contactsCollection)
          .doc(contactId)
          .update({'contactName': newName});
    } catch (e) {
      throw Exception('Failed to update contact name: ${e.toString()}');
    }
  }

  Stream<List<Contact>> getUserContacts(String userId) {
    try {
      return _firestore
          .collection(_contactsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        final contacts = <Contact>[];
        
        for (var doc in snapshot.docs) {
          final contactData = doc.data();
          final contactId = contactData['contactId'] as String;
          
          // Fetch user details for each contact
          final userDoc = await _firestore
              .collection(_usersCollection)
              .doc(contactId)
              .get();
          
          if (userDoc.exists) {
            final user = AppUser.fromMap(userDoc.data() as Map<String, dynamic>);
            contacts.add(Contact.fromMap(contactData, user: user));
          } else {
            contacts.add(Contact.fromMap(contactData));
          }
        }
        
        return contacts;
      });
    } catch (e) {
      debugPrint('Error getting user contacts: ${e.toString()}');
      return Stream.value([]);
    }
  }

  Future<bool> isUserInContacts(String contactUserId) async {
    try {
      final currentUid = currentUserId;
      if (currentUid == null) return false;

      final query = await _firestore
          .collection(_contactsCollection)
          .where('userId', isEqualTo: currentUid)
          .where('contactId', isEqualTo: contactUserId)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user is in contacts: ${e.toString()}');
      return false;
    }
  }
} 