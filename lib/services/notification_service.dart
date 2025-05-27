import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../features/user/models/app_user.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundEnabled = true;
  
  // Platform channel for showing native notifications
  static const MethodChannel _channel = MethodChannel('com.example.linkzy/notifications');
  
  // Singleton pattern
  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Initialize the notification service
  Future<void> init() async {
    // Initialize audio player
    await _audioPlayer.setAsset('assets/sounds/sound_1.mp3');
    
    // Request permission for Firebase Messaging
    await _requestNotificationPermissions();
  }
  
  // Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    debugPrint('User granted permission: ${settings.authorizationStatus}');
    
    // Get FCM token
    final token = await messaging.getToken();
    debugPrint('FCM Token: $token');
  }

  // Play notification sound
  Future<void> playNotificationSound() async {
    if (_isSoundEnabled) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    }
  }

  // Toggle notification sound
  void toggleSound(bool enabled) {
    _isSoundEnabled = enabled;
  }

  // Show notification for a new message
  Future<void> showMessageNotification(AppUser sender, String message) async {
    // Play sound
    playNotificationSound();
    
    // Show a system notification
    try {
      await _channel.invokeMethod('showNotification', {
        'title': sender.username,
        'body': message,
      });
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
    
    // For testing, print the notification info
    debugPrint('New message notification from: ${sender.username}');
    debugPrint('Message content: $message');
  }
  
  // This method will be used by the app.dart to handle Firebase messages
  Future<void> handleFirebaseMessage(RemoteMessage message) async {
    // Play sound for new messages
    playNotificationSound();
    
    // Show a system notification 
    try {
      await _channel.invokeMethod('showNotification', {
        'title': message.notification?.title ?? 'New Message',
        'body': message.notification?.body ?? '',
      });
    } catch (e) {
      debugPrint('Error showing notification from Firebase: $e');
    }
    
    // Log the message
    debugPrint('Handling Firebase message: ${message.notification?.title}');
    debugPrint('Message body: ${message.notification?.body}');
  }
} 