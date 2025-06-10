import 'package:flutter/material.dart';
import '../models/red_box_message.dart';

class MessageStatusIndicator extends StatelessWidget {
  final RedBoxMessage message;
  final Color? color;
  final double size;
  
  const MessageStatusIndicator({
    Key? key,
    required this.message,
    this.color,
    this.size = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Colors.grey;
    
    return Tooltip(
      message: _getTooltipMessage(),
      child: _buildIcon(defaultColor),
    );
  }

  Widget _buildIcon(Color defaultColor) {
    // If the message is still pending (not yet synced to server)
    if (message.status == 'pending') {
      return Icon(
        Icons.schedule,
        size: size,
        color: defaultColor,
      );
    }
    
    // If message has error status
    if (message.status == 'error') {
      return Icon(
        Icons.error_outline,
        size: size,
        color: Colors.red,
      );
    }
    
    // Message is sent to server but not yet delivered
    if (!message.isDelivered) {
      return Icon(
        Icons.check,
        size: size,
        color: defaultColor,
      );
    }
    
    // Message is delivered but not seen
    if (message.isDelivered && !message.isSeen) {
      return Icon(
        Icons.done_all,
        size: size,
        color: defaultColor,
      );
    }
    
    // Message is seen
    return Icon(
      Icons.done_all,
      size: size,
      color: Colors.blue,
    );
  }

  String _getTooltipMessage() {
    if (message.status == 'pending') {
      return 'Waiting to sync';
    }
    
    if (message.status == 'error') {
      return 'Error sending message - tap to retry';
    }
    
    if (!message.isDelivered) {
      return 'Sent';
    }
    
    if (message.isDelivered && !message.isSeen) {
      return 'Delivered';
    }
    
    return 'Seen';
  }
} 