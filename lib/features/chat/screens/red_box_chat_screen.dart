import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../../services/red_box_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/decoy_message_service.dart';
import '../../../services/panic_button_service.dart';
import '../../../services/connectivity_service.dart';
import '../../user/models/app_user.dart';
import '../models/red_box_message.dart';

class RedBoxChatScreen extends StatefulWidget {
  final AppUser otherUser;
  final bool isDecoyMode;

  const RedBoxChatScreen({
    Key? key,
    required this.otherUser,
    this.isDecoyMode = false,
  }) : super(key: key);

  @override
  _RedBoxChatScreenState createState() => _RedBoxChatScreenState();
}

class _RedBoxChatScreenState extends State<RedBoxChatScreen> {
  final _messageController = TextEditingController();
  final _redBoxService = RedBoxService();
  final _notificationService = NotificationService();
  final _decoyMessageService = DecoyMessageService();
  final _panicButtonService = PanicButtonService();
  final _connectivityService = ConnectivityService();
  
  bool _isTyping = false;
  bool _isOnline = true;
  String? _currentUserId;
  bool _isEmojiPickerVisible = false;
  final FocusNode _messageFocusNode = FocusNode();
  
  // Track last processed message ID to prevent duplicate notifications
  String? _lastProcessedMessageId;
  
  // Regular expression for emoji detection
  final RegExp _emojiRegex = RegExp(
    r'((\u0023|\u002a|[\u0030-\u0039])\ufe0f\u20e3){1}|\p{Emoji}|\u200D|\uFE0F',
    unicode: true,
  );

  @override
  void initState() {
    super.initState();
    _currentUserId = _redBoxService.currentUserId;
    _messageFocusNode.addListener(_onFocusChange);
    
    // Initialize connectivity monitoring
    _initConnectivity();
    
    // Add this to request focus when the chat screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_messageFocusNode);
    });
  }
  
  Future<void> _initConnectivity() async {
    // Start monitoring connectivity
    await _connectivityService.initialize();
    
    // Listen for connectivity changes
    _connectivityService.connectionStream.listen((isConnected) {
      setState(() {
        _isOnline = isConnected;
      });
    });
    
    // Get initial connection status
    _isOnline = _connectivityService.hasConnection;
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.removeListener(_onFocusChange);
    _messageFocusNode.dispose();
    super.dispose();
  }
  
  void _onFocusChange() {
    if (_messageFocusNode.hasFocus && _isEmojiPickerVisible) {
      setState(() {
        _isEmojiPickerVisible = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    // Clear the input field
    _messageController.clear();
    
    // Don't actually send messages in decoy mode
    if (widget.isDecoyMode) {
      // Just show a "sending" animation for effect
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
    
    try {
      await _redBoxService.sendRedBoxMessage(
        _currentUserId!,
        widget.otherUser.uid,
        message,
      );
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _onEmojiSelected(Category? category, Emoji emoji) {
    _messageController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
  }
  
  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiPickerVisible = !_isEmojiPickerVisible;
      if (_isEmojiPickerVisible) {
        FocusScope.of(context).unfocus();
      } else {
        FocusScope.of(context).requestFocus(_messageFocusNode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrap everything with panic button detection
    return _panicButtonService.wrapWithTripleTapDetection(
      context,
      _buildChatScreen(),
    );
  }
  
  Widget _buildChatScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.red.shade800,
              backgroundImage: widget.otherUser.profilePicUrl != null && 
                            widget.otherUser.profilePicUrl!.isNotEmpty
                  ? NetworkImage(widget.otherUser.profilePicUrl!)
                  : null,
              child: (widget.otherUser.profilePicUrl == null || 
                  widget.otherUser.profilePicUrl!.isEmpty)
                  ? Text(
                      widget.otherUser.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      widget.otherUser.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Secure Chat',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show info about secure chat
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Secure Chat Information'),
                  content: const Text(
                    'Messages in this chat are stored securely in your Red Box. '
                    'They are separate from your regular chats and can only be '
                    'accessed with your PIN.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline indicator
          if (!widget.isDecoyMode && !_isOnline)
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
          
          // Message list
          Expanded(
            child: _buildMessageList(),
          ),
          
          // Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                // Emoji picker toggle
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: _toggleEmojiPicker,
                  color: _isEmojiPickerVisible 
                      ? Colors.red.shade800
                      : Colors.grey[600],
                ),
                
                // Text input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Type a secure message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    onChanged: (text) {
                      final isTypingNow = text.isNotEmpty;
                      if (_isTyping != isTypingNow) {
                        setState(() {
                          _isTyping = isTypingNow;
                        });
                      }
                    },
                    onSubmitted: (text) {
                      if (_isTyping) {
                        _sendMessage();
                      }
                    },
                    textInputAction: TextInputAction.send,
                  ),
                ),
                
                // Send button
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isTyping
                      ? IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Colors.red.shade800,
                          ),
                          onPressed: _sendMessage,
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.mic,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            // Voice recording feature would go here
                          },
                        ),
                ),
              ],
            ),
          ),
          
          // Emoji picker
          if (_isEmojiPickerVisible)
            Container(
              height: 250,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) => _onEmojiSelected(category, emoji),
                textEditingController: _messageController,
                onBackspacePressed: () {
                  if (_messageController.text.isNotEmpty) {
                    _messageController.text = _messageController.text.characters.skipLast(1).toString();
                  }
                },
                config: Config(
                  height: 250,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    emojiSizeMax: 32 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.30 : 1.0),
                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    gridPadding: EdgeInsets.zero,
                    recentsLimit: 28,
                    loadingIndicator: const SizedBox.shrink(),
                    noRecents: const Text(
                      'No Recents',
                      style: TextStyle(fontSize: 20, color: Colors.black26),
                      textAlign: TextAlign.center,
                    ),
                    buttonMode: ButtonMode.MATERIAL,
                  ),
                  skinToneConfig: const SkinToneConfig(),
                  categoryViewConfig: CategoryViewConfig(
                    initCategory: Category.RECENT,
                    iconColor: Colors.grey,
                    iconColorSelected: Colors.red.shade800,
                    backspaceColor: Colors.red.shade800,
                    backgroundColor: Theme.of(context).colorScheme.background,
                    indicatorColor: Colors.red.shade800,
                    recentTabBehavior: RecentTabBehavior.RECENT,
                  ),
                  bottomActionBarConfig: BottomActionBarConfig(
                    backgroundColor: Colors.red.shade800,
                    buttonIconColor: Colors.white,
                  ),
                  searchViewConfig: const SearchViewConfig(),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMessageList() {
    if (_currentUserId == null) {
      return const Center(
        child: Text('Not authenticated'),
      );
    }
    
    // For decoy mode, use special decoy messages
    if (widget.isDecoyMode) {
      return _buildDecoyMessageList();
    }
    
    // For real mode, use actual messages
    return StreamBuilder<List<RedBoxMessage>>(
      stream: _redBoxService.getRedBoxMessages(_currentUserId!, widget.otherUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        final messages = snapshot.data ?? [];
        
        if (messages.isEmpty) {
          return _buildEmptyChatState();
        }
        
        // Mark messages as seen
        for (final message in messages) {
          if (message.senderId == widget.otherUser.uid && !message.isSeen) {
            _redBoxService.markRedBoxMessageAsSeen(message.id);
          }
        }
        
        return _buildMessageListView(messages);
      },
    );
  }
  
  Widget _buildDecoyMessageList() {
    return StreamBuilder<List<RedBoxMessage>>(
      stream: _decoyMessageService.getDecoyMessages(_currentUserId!, widget.otherUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        final messages = snapshot.data ?? [];
        
        if (messages.isEmpty) {
          return _buildEmptyChatState();
        }
        
        return _buildMessageListView(messages);
      },
    );
  }
  
  Widget _buildEmptyChatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock,
            size: 48,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No secure messages yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your messages will be stored in your Red Box',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageListView(List<RedBoxMessage> messages) {
    // Show messages in chronological order (oldest first at the top)
    final sortedMessages = messages.toList();
    
    return ListView.builder(
      reverse: false,
      padding: const EdgeInsets.all(16),
      itemCount: sortedMessages.length,
      itemBuilder: (context, index) {
        final message = sortedMessages[index];
        final isMyMessage = message.senderId == _currentUserId;
        
        // Group messages by sender and time
        final isFirstInGroup = index == 0 ||
            sortedMessages[index - 1].senderId != message.senderId ||
            _shouldShowTimestamp(sortedMessages[index - 1].timestamp, message.timestamp);
            
        final isLastInGroup = index == sortedMessages.length - 1 ||
            sortedMessages[index + 1].senderId != message.senderId ||
            _shouldShowTimestamp(message.timestamp, sortedMessages[index + 1].timestamp);
        
        return Column(
          children: [
            if (isFirstInGroup && index > 0)
              const SizedBox(height: 8),
              
            if (isFirstInGroup || _shouldShowTimestamp(sortedMessages[max(0, index - 1)].timestamp, message.timestamp))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _formatFullDateTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            
            _buildMessageBubble(
              message: message,
              isMyMessage: isMyMessage,
              isFirstInGroup: isFirstInGroup,
              isLastInGroup: isLastInGroup,
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildMessageBubble({
    required RedBoxMessage message,
    required bool isMyMessage,
    required bool isFirstInGroup,
    required bool isLastInGroup,
  }) {
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMyMessage ? 20 : (isLastInGroup ? 5 : 20)),
      bottomRight: Radius.circular(isMyMessage ? (isLastInGroup ? 5 : 20) : 20),
    );
    
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: isFirstInGroup ? 2 : 1,
          bottom: isLastInGroup ? 2 : 1,
          left: isMyMessage ? 50 : 0,
          right: isMyMessage ? 0 : 50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMyMessage 
              ? Colors.red.shade800
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
          borderRadius: bubbleRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMyMessage ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock,
                  size: 10,
                  color: isMyMessage ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMyMessage ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                  ),
                ),
                if (isMyMessage) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isSeen ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.isSeen ? Colors.white : Colors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  bool _shouldShowTimestamp(DateTime time1, DateTime time2) {
    // Show timestamp if more than 5 minutes between messages
    return time2.difference(time1).inMinutes > 5;
  }
  
  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatFullDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    if (messageDate == today) {
      // Today: just show time
      return timeStr;
    } else if (messageDate == yesterday) {
      // Yesterday: show "Yesterday" + time
      return 'Yesterday, $timeStr';
    } else {
      // Other date: show full date + time
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, $timeStr';
    }
  }
}

int max(int a, int b) => a > b ? a : b; 