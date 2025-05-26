import 'package:flutter/material.dart';
import '../../../services/firebase_service.dart';
import '../../user/models/app_user.dart';
import '../models/message.dart';
import 'chat_screen.dart';
import 'home_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _firebaseService = FirebaseService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Get current user ID from Firebase Auth
    _currentUserId = _firebaseService.currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please log in to see your chats',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<AppUser>>(
      stream: _firebaseService.getUsersWithChats(_currentUserId!),
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
            
            return StreamBuilder<Message?>(
              stream: _firebaseService.getLatestMessage(_currentUserId!, user.uid),
              builder: (context, messageSnapshot) {
                final latestMessage = messageSnapshot.data;
                
                // Show loading state if we're still getting the latest message
                if (messageSnapshot.connectionState == ConnectionState.waiting) {
                  return const ChatListItemSkeleton();
                }
                
                // If we have no message yet, skip this user
                if (latestMessage == null) {
                  return const SizedBox.shrink();
                }
                
                return ChatListItem(
                  user: user,
                  latestMessage: latestMessage,
                  currentUserId: _currentUserId!,
                );
              }
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting by searching for users',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Find Users'),
            onPressed: () {
              // Navigate to search screen or change tab
              final homeState = context.findAncestorStateOfType<HomeScreenState>();
              if (homeState != null) {
                // Change tab to search (index 1)
                homeState.setState(() {
                  homeState.changeTab(1);
                });
              } else {
                // Fallback to navigation
                Navigator.of(context).pushNamed('/search');
              }
            },
          ),
        ],
      ),
    );
  }
}

// Loading placeholder for chat list item
class ChatListItemSkeleton extends StatelessWidget {
  const ChatListItemSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
      ),
      title: Container(
        height: 16,
        width: 100,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      subtitle: Container(
        height: 12,
        width: 150,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      trailing: Container(
        height: 10,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ChatListItem extends StatelessWidget {
  final AppUser user;
  final Message latestMessage;
  final String currentUserId;
  
  const ChatListItem({
    Key? key,
    required this.user,
    required this.latestMessage,
    required this.currentUserId,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isMyMessage = latestMessage.senderId == currentUserId;
    final messagePreview = isMyMessage 
        ? 'You: ${latestMessage.content}'
        : latestMessage.content;
    
    // Format the timestamp
    final now = DateTime.now();
    final timestamp = DateTime.parse(latestMessage.timestamp.toString());
    final difference = now.difference(timestamp);
    
    String timeText;
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      timeText = '$years year${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      timeText = '$months month${months > 1 ? 's' : ''}';
    } else if (difference.inDays > 0) {
      timeText = '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      timeText = '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      timeText = '${difference.inMinutes}m';
    } else {
      timeText = 'Just now';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(otherUser: user),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                child: user.profilePicUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.network(
                          user.profilePicUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            user.username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        user.username.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              title: Text(
                user.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                messagePreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isMyMessage && !latestMessage.isSeen ? Colors.grey[600] : Colors.grey,
                ),
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!isMyMessage && !latestMessage.isSeen)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text(
                        '',
                      ),
                    ),
                  if (isMyMessage)
                    Icon(
                      latestMessage.isSeen
                          ? Icons.done_all
                          : Icons.done,
                      size: 16,
                      color: latestMessage.isSeen 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.grey,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 