import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/chat/models/red_box_message.dart';
import '../features/user/models/app_user.dart';

class DecoyMessageService {
  final String _usersCollection = 'users';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of first names for generating fake contacts
  final List<String> _firstNames = [
    'Alex', 'Jordan', 'Taylor', 'Morgan', 'Casey', 
    'Riley', 'Avery', 'Quinn', 'Cameron', 'Dakota',
    'Jamie', 'Skyler', 'Reese', 'Blake', 'Parker',
    'Emerson', 'Hayden', 'Peyton', 'Jordan', 'Dylan',
  ];
  
  // List of last names for generating fake contacts
  final List<String> _lastNames = [
    'Smith', 'Johnson', 'Williams', 'Jones', 'Brown',
    'Davis', 'Miller', 'Wilson', 'Moore', 'Taylor',
    'Anderson', 'Thomas', 'Jackson', 'White', 'Harris',
    'Martin', 'Thompson', 'Garcia', 'Martinez', 'Robinson',
  ];
  
  // Message templates for different types of conversations
  final Map<String, List<String>> _messageTemplates = {
    'work': [
      'Did you get my email about the project?',
      'When is the meeting scheduled for?',
      'Can you send me the updated report?',
      'The client just called, they need the files ASAP.',
      'Are we still on for the conference call?',
      'Just sent you the revised proposal.',
      'The deadline was extended to next Friday.',
      'Team lunch today at noon, can you make it?',
      'Have you reviewed the latest metrics?',
      'Let me know when you\'ve updated the presentation.',
    ],
    'casual': [
      'Hey, how\'s it going?',
      'Are we still meeting later?',
      'Just saw that movie you recommended. It was great!',
      'What time should we meet tomorrow?',
      'Have you tried that new restaurant downtown?',
      'Thanks for the help yesterday!',
      'Do you want to grab lunch tomorrow?',
      'Did you see the game last night?',
      'Can I borrow that book we talked about?',
      'Hope you had a good weekend!',
    ],
    'family': [
      'Don\'t forget Mom\'s birthday on Friday',
      'What time are you coming over for dinner?',
      'Can you pick up the kids from school today?',
      'Did you call Grandma yet?',
      'Remember we have the family reunion next month',
      'Are you bringing anything to the barbecue?',
      'Have you sent the holiday cards yet?',
      'The dog needs to go to the vet on Tuesday',
      'Can you pick up milk on your way home?',
      'Dad wants to know if you can help with the yard work',
    ],
  };

  // Generate a list of fake contacts for decoy mode
  Future<List<AppUser>> generateFakeContacts(int count) async {
    final random = Random();
    final contacts = <AppUser>[];
    final usedNames = <String>{};
    
    for (int i = 0; i < count; i++) {
      String firstName, lastName, fullName;
      
      // Ensure unique names
      do {
        firstName = _firstNames[random.nextInt(_firstNames.length)];
        lastName = _lastNames[random.nextInt(_lastNames.length)];
        fullName = '$firstName $lastName';
      } while (usedNames.contains(fullName));
      
      usedNames.add(fullName);
      
      contacts.add(AppUser(
        uid: const Uuid().v4(),
        email: '${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com',
        username: firstName.toLowerCase(),
        displayName: fullName,
        profilePicUrl: '', // No profile pics for fake contacts
      ));
    }
    
    return contacts;
  }
  
  // Generate fake message history between two users
  Future<List<RedBoxMessage>> generateFakeMessageHistory(String userId, String contactId) async {
    final random = Random();
    final messages = <RedBoxMessage>[];
    
    // Determine conversation type
    final conversationTypes = _messageTemplates.keys.toList();
    final conversationType = conversationTypes[random.nextInt(conversationTypes.length)];
    final messageTemplates = _messageTemplates[conversationType]!;
    
    // Generate between 5-20 messages
    final messageCount = random.nextInt(16) + 5;
    
    // Current time
    final now = DateTime.now();
    
    // Start time for conversations (between 1-14 days ago)
    final startDaysAgo = random.nextInt(14) + 1;
    final startTime = now.subtract(Duration(days: startDaysAgo));
    
    for (int i = 0; i < messageCount; i++) {
      // Random sender (either user or contact)
      final isFromUser = random.nextBool();
      
      // Each message is between 10 minutes and 6 hours after the previous one
      final minutes = random.nextInt((6 * 60) - 10) + 10;
      final timestamp = startTime.add(Duration(
        minutes: minutes * i,
      ));
      
      // Don't create messages in the future
      if (timestamp.isAfter(now)) {
        break;
      }
      
      // Random message from templates with some variations
      String messageText = messageTemplates[random.nextInt(messageTemplates.length)];
      
      // 10% chance of adding some personalization
      if (random.nextInt(10) == 0) {
        final personalizations = [
          'By the way, ',
          'I meant to ask you, ',
          'Also, ',
          'I forgot to mention, ',
        ];
        
        messageText = personalizations[random.nextInt(personalizations.length)] + messageText;
      }
      
      // 5% chance of adding an emoji
      if (random.nextInt(20) == 0) {
        final emojis = ['😊', '👍', '🙏', '🤔', '😂', '❤️', '👌', '👏', '🙌', '🎉'];
        messageText += ' ' + emojis[random.nextInt(emojis.length)];
      }
      
      messages.add(RedBoxMessage(
        id: const Uuid().v4(),
        senderId: isFromUser ? userId : contactId,
        receiverId: isFromUser ? contactId : userId,
        content: messageText,
        timestamp: timestamp,
        isSeen: timestamp.isBefore(now.subtract(const Duration(hours: 1))), // Messages older than 1 hour are seen
        isDelivered: true,
        isEncrypted: true,
      ));
    }
    
    // Sort by timestamp
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }
  
  // Get a list of users with fake Red Box chats
  Stream<List<AppUser>> getDecoyUserList(String currentUserId) async* {
    try {
      // Generate between 3-8 fake contacts
      final random = Random();
      final contactCount = random.nextInt(6) + 3;
      
      // Get stored contacts or generate new ones
      final prefs = await SharedPreferences.getInstance();
      List<AppUser> contacts;
      
      final storedContactsJson = prefs.getStringList('decoy_contacts');
      
      if (storedContactsJson != null && storedContactsJson.isNotEmpty) {
        // Use stored contacts
        contacts = [];
        
        // This would need proper implementation, for now we just generate new ones
        contacts = await generateFakeContacts(contactCount);
      } else {
        // Generate new contacts
        contacts = await generateFakeContacts(contactCount);
        
        // In a real implementation, we'd store these for persistence
        // But that requires more complex JSON conversion
      }
      
      yield contacts;
    } catch (e) {
      debugPrint('Error getting decoy user list: ${e.toString()}');
      yield [];
    }
  }
  
  // Get latest message for a decoy conversation
  Stream<RedBoxMessage?> getLatestDecoyMessage(String currentUserId, String contactId) async* {
    try {
      final messages = await generateFakeMessageHistory(currentUserId, contactId);
      
      if (messages.isNotEmpty) {
        yield messages.last;
      } else {
        yield null;
      }
    } catch (e) {
      debugPrint('Error getting latest decoy message: ${e.toString()}');
      yield null;
    }
  }
  
  // Get all messages for a decoy conversation
  Stream<List<RedBoxMessage>> getDecoyMessages(String currentUserId, String contactId) async* {
    try {
      final messages = await generateFakeMessageHistory(currentUserId, contactId);
      yield messages;
    } catch (e) {
      debugPrint('Error getting decoy messages: ${e.toString()}');
      yield [];
    }
  }
} 