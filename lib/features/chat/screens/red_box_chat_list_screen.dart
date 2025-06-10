import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/red_box_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/firebase_service.dart';
import '../../../services/panic_button_service.dart';
import '../../../services/decoy_message_service.dart';
import '../../../services/connectivity_service.dart';
import '../../user/models/app_user.dart';
import '../../user/models/contact.dart';
import '../../user/screens/contacts_screen.dart';
import '../models/red_box_message.dart';
import 'red_box_chat_screen.dart';
import '../widgets/sync_status_indicator.dart';

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
  final _panicButtonService = PanicButtonService();
  final _decoyMessageService = DecoyMessageService();
  final _connectivityService = ConnectivityService();
  
  bool _isOnline = true;
  String? _currentUserId;
  
  // Track processed message IDs to prevent duplicate notifications
  final Map<String, String> _processedMessageIds = {};
  bool _isDecoyMode = false;
  bool _isLoading = false;
  List<AppUser> _cachedUsers = [];

  @override
  void initState() {
    super.initState();
    _isDecoyMode = widget.isDecoyMode;
    _currentUserId = _redBoxService.currentUserId;
    
    // Initialize connectivity monitoring
    _initConnectivity();
    _checkAndCacheData();
  }
  
  Future<void> _initConnectivity() async {
    // Start monitoring connectivity
    await _connectivityService.initialize();
    
    // Listen for connectivity changes
    _connectivityService.connectionStream.listen((isConnected) {
      setState(() {
        _isOnline = isConnected;
      });
      
      if (isConnected) {
        _syncPendingMessages();
      }
    });
    
    // Get initial connection status
    _isOnline = _connectivityService.hasConnection;
  }
  
  Future<void> _syncPendingMessages() async {
    try {
      await _redBoxService.syncPendingMessages();
    } catch (e) {
      debugPrint('Error syncing pending messages: ${e.toString()}');
    }
  }
  
  // Navigate to contacts to select a contact for secure chat
  void _navigateToContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactsSelectionScreen(
          isDecoyMode: widget.isDecoyMode,
        ),
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
  
  // Configure panic button options
  void _configurePanicButton() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              'Panic Button Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Configure your emergency exit gesture for Red Box:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildPanicGestureOptions(setDialogState),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('SAVE'),
              ),
            ],
          );
        }
      ),
    );
  }
  
  Widget _buildPanicGestureOptions(StateSetter setDialogState) {
    return FutureBuilder<PanicGestureType>(
      future: _panicButtonService.getPanicGestureType(),
      builder: (context, snapshot) {
        final currentGesture = snapshot.data ?? PanicGestureType.tripleTap;
        
        void updateGesture(PanicGestureType value) {
          if (value != null) {
            Map<String, dynamic> gestureData = {};
            if (value == PanicGestureType.shake) {
              gestureData = {'sensitivity': 'medium'};
            }
            
            _panicButtonService.configurePanicGesture(value, gestureData);
            
            // Update the dialog state immediately
            setDialogState(() {});
            
            // Provide haptic feedback
            HapticFeedback.lightImpact();
          }
        }
        
        return Column(
          children: [
            InkWell(
              onTap: () => updateGesture(PanicGestureType.tripleTap),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: RadioListTile<PanicGestureType>(
                  title: const Text(
                    'Triple Tap (anywhere)',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Tap screen three times quickly to exit'),
                  value: PanicGestureType.tripleTap,
                  groupValue: currentGesture,
                  activeColor: Colors.red.shade700,
                  onChanged: (value) => updateGesture(value!),
                ),
              ),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: () => updateGesture(PanicGestureType.shake),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: RadioListTile<PanicGestureType>(
                  title: const Text(
                    'Shake Device',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Shake your device to quickly exit'),
                  value: PanicGestureType.shake,
                  groupValue: currentGesture,
                  activeColor: Colors.red.shade700,
                  onChanged: (value) => updateGesture(value!),
                ),
              ),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: () => updateGesture(PanicGestureType.doubleTapBack),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: RadioListTile<PanicGestureType>(
                  title: const Text(
                    'Double Tap Back Button', 
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Tap back button twice to exit'),
                  value: PanicGestureType.doubleTapBack,
                  groupValue: currentGesture,
                  activeColor: Colors.red.shade700,
                  onChanged: (value) => updateGesture(value!),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap everything with panic button detection
    return _panicButtonService.wrapWithTripleTapDetection(
      context,
      _buildScreen(),
    );
  }
  
  Widget _buildScreen() {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not authenticated'),
        ),
      );
    }
    
    // Show decoy mode or regular mode
    return _buildRedBoxChatListScaffold(
      widget.isDecoyMode ? _buildDecoyList() : _buildRealList(),
    );
  }
  
  Widget _buildDecoyList() {
    if (_currentUserId == null) return _buildEmptyState();
    
    return StreamBuilder<List<AppUser>>(
      stream: _decoyMessageService.getDecoyUserList(_currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final contacts = snapshot.data ?? [];
        
        if (contacts.isEmpty) {
          return _buildEmptyState();
        }
        
        return ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            
            return StreamBuilder<RedBoxMessage?>(
              stream: _decoyMessageService.getLatestDecoyMessage(
                _currentUserId!,
                contact.uid,
              ),
              builder: (context, messageSnapshot) {
                final latestMessage = messageSnapshot.data;
                
                if (messageSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildChatListItemSkeleton();
                }
                
                if (latestMessage == null) {
                  return const SizedBox.shrink();
                }
                
                return _buildChatListItem(contact, latestMessage, isDecoy: true);
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildRealList() {
    if (_currentUserId == null) return _buildEmptyState();
    
    return Column(
      children: [
        // Offline indicator
        if (!_isOnline)
          Container(
            width: double.infinity,
            color: Colors.orange.shade800,
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
            child: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Offline Mode - Messages will sync when connection returns',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        
        // Chat list
        Expanded(
          child: StreamBuilder<List<AppUser>>(
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
                      _checkForNewMessage(latestMessage, user);
                      
                      return _buildChatListItem(user, latestMessage, isDecoy: false);
                    }
                  );
                },
              );
            },
          ),
        ),
      ],
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
          // Sync status indicator
          const SyncStatusIndicator(size: 18, showLabel: false),
          const SizedBox(width: 8),
          
          // Refresh and sync button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAndSync,
            tooltip: 'Refresh & Sync',
          ),
          
          // Panic button configuration
          if (!widget.isDecoyMode)
            IconButton(
              icon: const Icon(Icons.warning_amber),
              onPressed: _configurePanicButton,
              tooltip: 'Configure Panic Button',
            ),
          
          // Exit button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pop();
            },
            tooltip: 'Exit Red Box',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Offline indicator
                if (!_isOnline)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.shade100,
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.orange.shade900, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Offline Mode - Messages will sync when connection returns',
                            style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: _refreshAndSync,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            backgroundColor: Colors.orange.shade200,
                            foregroundColor: Colors.orange.shade900,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('SYNC'),
                        ),
                      ],
                    ),
                  ),
                
                // Chat list
                Expanded(child: body),
              ],
            ),
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
  
  Widget _buildChatListItem(AppUser user, RedBoxMessage latestMessage, {bool isDecoy = false}) {
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RedBoxChatScreen(
                otherUser: user,
                isDecoyMode: isDecoy,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.red.shade800,
            backgroundImage: user.profilePicUrl != null && user.profilePicUrl.isNotEmpty
                ? NetworkImage(user.profilePicUrl)
                : null,
            child: (user.profilePicUrl == null || user.profilePicUrl.isEmpty)
                ? Text(
                    user.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMyMessage ? "You: ${latestMessage.content}" : latestMessage.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: !latestMessage.isSeen && !isMyMessage
                      ? Colors.black
                      : Colors.grey[600],
                  fontWeight: !latestMessage.isSeen && !isMyMessage
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _formatMessageTime(latestMessage.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (isMyMessage && messageStatus.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      messageStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      latestMessage.isSeen
                          ? Icons.done_all
                          : Icons.done,
                      size: 12,
                      color: latestMessage.isSeen ? Colors.blue : Colors.grey[600],
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Offline message indicator
              if (!isDecoy && !_isOnline && _isMessagePending(latestMessage))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  bool _isMessagePending(RedBoxMessage message) {
    // In a real implementation, we'd check if this message is in the pending queue
    // For now, just check if it's recent and from the current user
    return message.senderId == _currentUserId && 
           DateTime.now().difference(message.timestamp).inMinutes < 5 &&
           !message.isDelivered;
  }
  
  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      // Today, show time
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Other day, show date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
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
          height: 14,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 10,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkAndCacheData() async {
    final connectivityService = ConnectivityService();
    final currentUserId = _currentUserId;
    final hasConnection = connectivityService.hasConnection;
    
    if (currentUserId != null) {
      // If online and no fresh cached data, cache app data
      final hasFreshCache = await _redBoxService.hasFreshCachedData();
      if (hasConnection && !hasFreshCache) {
        await _redBoxService.cacheAppData(currentUserId);
      }
      
      // Check for pending messages and sync if online
      if (hasConnection) {
        final hasPending = await _redBoxService.hasPendingMessages();
        if (hasPending) {
          connectivityService.forceSyncPendingMessages();
        }
      }
      
      // Load cached users for offline mode
      _loadCachedUsers();
    }
  }

  Future<void> _loadCachedUsers() async {
    final cachedUsers = await _redBoxService.getCachedContacts();
    if (mounted) {
      setState(() {
        _cachedUsers = cachedUsers;
      });
    }
  }

  Future<void> _refreshAndSync() async {
    if (_currentUserId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Cache app data for offline use
      await _redBoxService.cacheAppData(_currentUserId!);
      
      // Reload cached users
      await _loadCachedUsers();

      // Force sync if online
      if (_connectivityService.hasConnection) {
        await _connectivityService.forceSyncPendingMessages();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data synced successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are offline. App data cached for offline use.'),
              backgroundColor: Colors.amber,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} // End of _RedBoxChatListScreenState class

// New screen to select contacts for Red Box chats
class ContactsSelectionScreen extends StatefulWidget {
  final bool isDecoyMode;

  const ContactsSelectionScreen({
    Key? key,
    this.isDecoyMode = false,
  }) : super(key: key);

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
      body: widget.isDecoyMode
          ? _buildDecoyContactsList()
          : _buildRealContactsList(),
    );
  }

  Widget _buildDecoyContactsList() {
    // For decoy mode, we need to generate fake contacts that aren't already shown in the chat list
    final _decoyMessageService = DecoyMessageService();
    
    return FutureBuilder<List<AppUser>>(
      future: _decoyMessageService.generateFakeContacts(15), // Generate a larger pool of fake contacts
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
          return _buildEmptyContactsList();
        }

        return ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade800,
                child: Text(
                  contact.displayName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(contact.displayName),
              subtitle: Text(contact.email),
              onTap: () {
                // Navigate to chat screen with the selected contact
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RedBoxChatScreen(
                      otherUser: contact,
                      isDecoyMode: true,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRealContactsList() {
    return StreamBuilder<List<Contact>>(
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
          return _buildEmptyContactsList();
        }

        return ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            // Skip contacts without user details
            if (contact.userDetails == null) {
              return const SizedBox.shrink();
            }
            
            // Use the userDetails for display
            final user = contact.userDetails!;
            
            // Use custom name if set, otherwise display name from userDetails
            final displayName = contact.contactName.isNotEmpty 
                ? contact.contactName 
                : user.displayName;
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade800,
                backgroundImage: user.profilePicUrl != null && 
                              user.profilePicUrl.isNotEmpty
                    ? NetworkImage(user.profilePicUrl)
                    : null,
                child: user.profilePicUrl == null || user.profilePicUrl.isEmpty
                    ? Text(
                        displayName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              title: Text(displayName),
              subtitle: Text(user.email),
              onTap: () {
                // Navigate to chat screen with the selected contact
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RedBoxChatScreen(
                      otherUser: user,
                      isDecoyMode: false,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyContactsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contact_phone_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No contacts found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add contacts to start secure chats',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
} 