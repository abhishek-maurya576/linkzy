import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:google_fonts/google_fonts.dart';
import '../../../services/firebase_service.dart';
import '../../../services/notification_service.dart';
import '../../user/models/app_user.dart';
import '../models/message.dart';
import '../../../core/utils/animated_background.dart';

class ChatScreen extends StatefulWidget {
  final AppUser otherUser;

  const ChatScreen({
    Key? key,
    required this.otherUser,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _firebaseService = FirebaseService();
  final _notificationService = NotificationService();
  bool _isTyping = false;
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
    _currentUserId = _firebaseService.currentUserId;
    _messageFocusNode.addListener(_onFocusChange);
    
    // Add this to request focus when the chat screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_messageFocusNode);
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.removeListener(_onFocusChange);
    _messageFocusNode.dispose();
    super.dispose();
  }

  // Helper method to create text spans with emoji styling
  List<TextSpan> _getStyledTextSpans(String text, Color? textColor) {
    final List<TextSpan> spans = [];
    final matches = _emojiRegex.allMatches(text).toList();
    
    if (matches.isEmpty) {
      // If no emojis found, return plain text with regular style
      return [TextSpan(
        text: text,
        style: GoogleFonts.notoSans(
          color: textColor,
          fontSize: 16,
        ),
      )];
    }
    
    int currentPosition = 0;
    
    for (final match in matches) {
      // Add text before emoji with regular style
      if (match.start > currentPosition) {
        spans.add(TextSpan(
          text: text.substring(currentPosition, match.start),
          style: GoogleFonts.notoSans(
            color: textColor,
            fontSize: 16,
          ),
        ));
      }
      
      // Add emoji with color emoji style
      spans.add(TextSpan(
        text: match.group(0),
        style: GoogleFonts.notoColorEmoji(
          fontSize: 16,
        ),
      ));
      
      currentPosition = match.end;
    }
    
    // Add any remaining text after last emoji
    if (currentPosition < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPosition),
        style: GoogleFonts.notoSans(
          color: textColor,
          fontSize: 16,
        ),
      ));
    }
    
    return spans;
  }

  void _onFocusChange() {
    // Only update state if emoji picker is visible and we have focus
    if (_messageFocusNode.hasFocus && _isEmojiPickerVisible) {
      setState(() {
        _isEmojiPickerVisible = false;
      });
    }
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    // Don't use setState just to update _isTyping
    // We'll handle this in onChanged of the TextField instead
    _isTyping = _messageController.text.trim().isNotEmpty;
  }

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiPickerVisible = !_isEmojiPickerVisible;
      if (_isEmojiPickerVisible) {
        _messageFocusNode.unfocus();
      } else {
        _messageFocusNode.requestFocus();
      }
    });
  }

  // Check for new messages and show notifications
  Future<void> _checkForNewMessages(List<Message> messages) async {
    if (messages.isEmpty) return;
    
    // Sort messages by timestamp to get the latest one
    final sortedMessages = List<Message>.from(messages)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    final latestMessage = sortedMessages.first;
    
    // Only process messages from the other user and not yet seen
    if (latestMessage.senderId == widget.otherUser.uid && 
        !latestMessage.isSeen && 
        latestMessage.id != _lastProcessedMessageId) {
      
      // Play notification sound
      _notificationService.playNotificationSound();
      
      // Show notification
      try {
        await _notificationService.showMessageNotification(
          widget.otherUser, 
          latestMessage.content
        );
      } catch (e) {
        debugPrint('Error showing notification: $e');
      }
      
      // Update last processed message ID
      _lastProcessedMessageId = latestMessage.id;
    }
  }

  Future<void> _sendMessage() async {
    if (_currentUserId == null) return;
    
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      return;
    }

    try {
      // Save the current focus state before modifying the text
      final hadFocus = _messageFocusNode.hasFocus;
      
      // Update typing status and clear text without using setState
      _isTyping = false;
      _messageController.clear();
      
      // Only update UI to show the sending state is complete
      setState(() {});
      
      // Maintain focus if it was focused before
      if (hadFocus) {
        // Use a short delay to prevent keyboard flicker
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) _messageFocusNode.requestFocus();
        });
      }
      
      await _firebaseService.sendMessage(
        _currentUserId!,
        widget.otherUser.uid,
        content,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.otherUser.displayName.isNotEmpty ? 
              widget.otherUser.displayName : widget.otherUser.username),
        ),
        body: const Center(
          child: Text('Please log in to send messages'),
        ),
      );
    }
    
    return WillPopScope(
      onWillPop: () async {
        if (_isEmojiPickerVisible) {
          setState(() {
            _isEmojiPickerVisible = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              _buildUserAvatar(context),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.otherUser.displayName.isNotEmpty ? 
                        widget.otherUser.displayName : widget.otherUser.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.otherUser.displayName.isNotEmpty)
                      Text(
                        '@${widget.otherUser.username}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show options menu
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _buildOptionsMenu(),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            // Add the animated background
            AnimatedParticlesBackground(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary,
                Colors.blue.shade300,
              ],
              numberOfParticles: 30, // Fewer particles than login screen
              animateGradient: true,
            ),
            // Content
            Column(
              children: [
                // Messages list
                Expanded(
                  child: StreamBuilder<List<Message>>(
                    stream: _firebaseService.getMessages(
                      _currentUserId!,
                      widget.otherUser.uid,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return _buildEmptyChat();
                      }

                      // Check for new messages and show notifications
                      _checkForNewMessages(messages);

                      // Mark messages as seen
                      for (final message in messages) {
                        if (message.receiverId == _currentUserId && !message.isSeen) {
                          _firebaseService.markMessageAsSeen(message.id);
                        }
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == _currentUserId;

                          return _buildMessageBubble(message, isMe);
                        },
                      );
                    },
                  ),
                ),
                // Message input
                _buildMessageInput(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    if (widget.otherUser.profilePicUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: widget.otherUser.profilePicUrl.startsWith('assets/')
            ? AssetImage(widget.otherUser.profilePicUrl) as ImageProvider
            : NetworkImage(widget.otherUser.profilePicUrl),
        onBackgroundImageError: (_, __) {
          // No return value needed here, just log the error
        },
      );
    } else {
      return CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
        child: Text(
          widget.otherUser.username.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
              backgroundImage: widget.otherUser.profilePicUrl.isNotEmpty
                  ? widget.otherUser.profilePicUrl.startsWith('assets/')
                      ? AssetImage(widget.otherUser.profilePicUrl) as ImageProvider
                      : NetworkImage(widget.otherUser.profilePicUrl)
                  : null,
              child: widget.otherUser.profilePicUrl.isEmpty
                  ? Text(
                      widget.otherUser.username.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? Theme.of(context).primaryColor.withOpacity(0.9)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: _getStyledTextSpans(
                      message.content,
                      isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _formatTimeForMessage(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (isMe) Icon(
                      message.isSeen ? Icons.done_all : (message.isDelivered ? Icons.done : Icons.access_time),
                      size: 12,
                      color: message.isSeen ? Colors.white70 : Colors.white54,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Message text field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isTyping 
                          ? Theme.of(context).primaryColor.withOpacity(0.7) 
                          : Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: IconButton(
                        icon: Icon(
                          _isEmojiPickerVisible 
                              ? Icons.keyboard
                              : Icons.emoji_emotions_outlined,
                          color: _isEmojiPickerVisible
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                        ),
                        onPressed: _toggleEmojiPicker,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onChanged: (value) {
                      final newIsTyping = value.trim().isNotEmpty;
                      // Only update state if typing status changes to avoid unnecessary rebuilds
                      if (newIsTyping != _isTyping) {
                        setState(() {
                          _isTyping = newIsTyping;
                        });
                      }
                    },
                    onSubmitted: (_) => _sendMessage(),
                    style: GoogleFonts.notoSans(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isTyping 
                      ? Theme.of(context).primaryColor
                      : Colors.grey[400],
                  boxShadow: _isTyping ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ] : null,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: Colors.white,
                  onPressed: _isTyping ? _sendMessage : null,
                ),
              ),
            ],
          ),
        ),
        // Emoji Picker
        Offstage(
          offstage: !_isEmojiPickerVisible,
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: EmojiPicker(
              onEmojiSelected: _onEmojiSelected,
              textEditingController: _messageController,
              onBackspacePressed: () {
                if (_messageController.text.isNotEmpty) {
                  _messageController.text = _messageController.text.characters.skipLast(1).toString();
                }
              },
              config: Config(
                height: 250,
                checkPlatformCompatibility: true,
                emojiTextStyle: GoogleFonts.notoColorEmoji(
                  fontSize: 28,
                ),
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 32 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.30 : 1.0),
                  verticalSpacing: 0,
                  horizontalSpacing: 0,
                  gridPadding: EdgeInsets.zero,
                  recentsLimit: 28,
                  loadingIndicator: const SizedBox.shrink(),
                  noRecents: const Text(
                    'No Recents',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  buttonMode: ButtonMode.MATERIAL,
                ),
                skinToneConfig: const SkinToneConfig(),
                categoryViewConfig: CategoryViewConfig(
                  initCategory: Category.RECENT,
                  iconColor: Colors.grey,
                  iconColorSelected: Theme.of(context).primaryColor,
                  backspaceColor: Theme.of(context).primaryColor,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  indicatorColor: Theme.of(context).primaryColor,
                  recentTabBehavior: RecentTabBehavior.RECENT,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor: Theme.of(context).primaryColor,
                  buttonIconColor: Colors.white,
                ),
                searchViewConfig: const SearchViewConfig(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 4,
              ),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Send a message to start the conversation with ${widget.otherUser.username}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Scroll to message input and focus it
                    _messageController.clear();
                    FocusScope.of(context).requestFocus(_messageFocusNode);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                    elevation: 5,
                    shadowColor: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Start Conversation',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to profile view in a real app
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Block User'),
            onTap: () {
              Navigator.pop(context);
              // Show block confirmation
              _showBlockUserConfirmation();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete Conversation'),
            onTap: () {
              Navigator.pop(context);
              // Show delete confirmation
              _showDeleteConversationConfirmation();
            },
          ),
        ],
      ),
    );
  }

  void _showBlockUserConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User?'),
        content: Text(
          'Are you sure you want to block ${widget.otherUser.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User blocked')),
              );
              // In a real app, we would block the user here
              Navigator.pop(context); // Go back to chat list
            },
            child: const Text('Block'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConversationConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation?'),
        content: const Text(
          'This will permanently delete all messages in this conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conversation deleted')),
              );
              // In a real app, we would delete the conversation here
              Navigator.pop(context); // Go back to chat list
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeForMessage(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year, 
      timestamp.month, 
      timestamp.day
    );
    
    final minutes = timestamp.minute.toString().padLeft(2, '0');
    final hours = timestamp.hour.toString().padLeft(2, '0');
    final time = '$hours:$minutes';

    if (messageDate.isAtSameMomentAs(today)) {
      return time;
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday, $time';
    } else {
      final month = timestamp.month.toString().padLeft(2, '0');
      final day = timestamp.day.toString().padLeft(2, '0');
      return '$day/$month, $time';
    }
  }
} 