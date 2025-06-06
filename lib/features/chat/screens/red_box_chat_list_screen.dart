import 'package:flutter/material.dart';
import '../../../services/red_box_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/firebase_service.dart';
import '../../user/models/app_user.dart';
import '../../user/models/contact.dart';
import '../../user/screens/contacts_screen.dart';
import '../models/red_box_message.dart';
import 'red_box_chat_screen.dart';

class RedBoxChatListScreen extends StatefulWidget {
  final bool isDecoyMode;

  const RedBoxChatListScreen({
    Key? key,
    this.isDecoyMode = false,
  }) : super(key: key);

  @override
  _RedBoxChatListScreenState createState() => _RedBoxChatListScreenState();
}

class _RedBoxChatListScreenState extends State<RedBoxChatListScreen> {
  final _redBoxService = RedBoxService();
  final _firebaseService = FirebaseService();
  final _notificationService = NotificationService();
  String? _currentUserId;
  
  // Track processed message IDs to prevent duplicate notifications
  final Map<String, String> _processedMessageIds = {};

  @override
  void initState() {
    super.initState();
    // Get current user ID from Firebase Auth
    _currentUserId = _redBoxService.currentUserId;
  }
  
  // Navigate to contacts to select a contact for secure chat
  void _navigateToContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContactsSelectionScreen(),
      ),
    );
  }
  
  // Check for new messages and show notifications
  Future<void> _checkForNewMessage(RedBoxMessage? latestMessage, AppUser sender) async {
    if (latestMessage == null || _currentUserId == null) return;
    
    // Only show notifications for messages from other users that haven't been seen
    if (latestMessage.senderId != _currentUserId && 
        !latestMessage.isSeen &&
        _processedMessageIds[sender.uid] != latestMessage.id) {
      
      // Update processed message ID for this sender
      _processedMessageIds[sender.uid] = latestMessage.id;
      
      // Play notification sound and show popup
      _notificationService.playNotificationSound();
      await _notificationService.showMessageNotification(sender, "New secure message");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not authenticated'),
        ),
      );
    }
    
    // Show empty state for decoy mode
    if (widget.isDecoyMode) {
      return _buildRedBoxChatListScaffold(_buildEmptyState());
    }

    return _buildRedBoxChatListScaffold(
      StreamBuilder<List<AppUser>>(
        stream: _redBoxService.getUsersWithRedBoxChats(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              
              return StreamBuilder<RedBoxMessage?>(
                stream: _redBoxService.getLatestRedBoxMessage(_currentUserId!, user.uid),
                builder: (context, messageSnapshot) {
                  final latestMessage = messageSnapshot.data;
                  
                  // Show loading state if we're still getting the latest message
                  if (messageSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildChatListItemSkeleton();
                  }
                  
                  // If we have no message yet, skip this user
                  if (latestMessage == null) {
                    return const SizedBox.shrink();
                  }
                  
                  // Check for new messages and show notifications
                  // Handle async method in a fire-and-forget way
                  _checkForNewMessage(latestMessage, user).then((_) {
                    // Notification shown or not needed
                  }).catchError((error) {
                    debugPrint('Error showing notification: $error');
                  });
                  
                  return _buildChatListItem(user, latestMessage);
                }
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildRedBoxChatListScaffold(Widget body) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.security, size: 18),
            SizedBox(width: 8),
            Text('Red Box'),
          ],
        ),
        backgroundColor: Colors.red.shade800, // Special red color for Red Box
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pop();
            },
            tooltip: 'Exit Red Box',
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToContacts,
        backgroundColor: Colors.red.shade800,
        child: const Icon(Icons.add),
        tooltip: 'New Secure Chat',
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Secure Chats Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a new secure conversation',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToContacts,
            icon: const Icon(Icons.add),
            label: const Text('New Secure Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatListItem(AppUser user, RedBoxMessage latestMessage) {
    final isMyMessage = latestMessage.senderId == _currentUserId;
    final messageStatus = isMyMessage
        ? latestMessage.isSeen
            ? 'Seen'
            : latestMessage.isDelivered
                ? 'Delivered'
                : 'Sent'
        : '';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.red.shade800,
          backgroundImage: user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty
              ? NetworkImage(user.profilePicUrl!)
              : null,
          child: user.profilePicUrl == null || user.profilePicUrl!.isEmpty
              ? Text(
                  user.displayName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            const Icon(Icons.lock, size: 12, color: Colors.red),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                user.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                isMyMessage ? 'You: ${latestMessage.content}' : latestMessage.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: !isMyMessage && !latestMessage.isSeen
                      ? Colors.red.shade800
                      : null,
                  fontWeight: !isMyMessage && !latestMessage.isSeen
                      ? FontWeight.bold
                      : null,
                ),
              ),
            ),
            if (isMyMessage && messageStatus.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                messageStatus,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDateTime(latestMessage.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            if (!isMyMessage && !latestMessage.isSeen)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red.shade800,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RedBoxChatScreen(otherUser: user),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildChatListItemSkeleton() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[300],
        ),
        title: Container(
          width: 100,
          height: 16,
          color: Colors.grey[300],
        ),
        subtitle: Container(
          width: double.infinity,
          height: 14,
          color: Colors.grey[300],
        ),
        trailing: Container(
          width: 30,
          height: 14,
          color: Colors.grey[300],
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      // Today: show time
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      // Within a week: show day name
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[dateTime.weekday - 1];
    } else {
      // Older: show date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// New screen to select contacts for Red Box chats
class ContactsSelectionScreen extends StatefulWidget {
  const ContactsSelectionScreen({Key? key}) : super(key: key);

  @override
  _ContactsSelectionScreenState createState() => _ContactsSelectionScreenState();
}

class _ContactsSelectionScreenState extends State<ContactsSelectionScreen> {
  final _firebaseService = FirebaseService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _firebaseService.currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not authenticated'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contact'),
        backgroundColor: Colors.red.shade800,
      ),
      body: StreamBuilder<List<Contact>>(
        stream: _firebaseService.getUserContacts(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading contacts: ${snapshot.error}'),
            );
          }

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contact_phone_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No contacts yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add contacts in the Contacts tab first',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: contacts.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return _buildContactItem(contact);
            },
          );
        },
      ),
    );
  }

  Widget _buildContactItem(Contact contact) {
    final user = contact.userDetails;
    
    if (user == null) {
      return const SizedBox.shrink();
    }
    
    // Use custom name if set, otherwise use display name or username
    final displayName = contact.contactName.isNotEmpty 
        ? contact.contactName 
        : user.displayName.isNotEmpty 
            ? user.displayName 
            : user.username;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.red.shade800,
          backgroundImage: user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty
              ? NetworkImage(user.profilePicUrl!)
              : null,
          child: user.profilePicUrl == null || user.profilePicUrl!.isEmpty
              ? Text(
                  displayName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '@${user.username}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to Red Box chat screen with this contact
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RedBoxChatScreen(otherUser: user),
            ),
          );
        },
      ),
    );
  }
} 