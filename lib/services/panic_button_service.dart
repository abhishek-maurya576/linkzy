import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'red_box_service.dart';

enum PanicGestureType {
  tripleTap,
  volumeKeySequence,
  shake,
  doubleTapBack,
  swipeDown,
}

class PanicButtonService {
  static const _panicGestureKey = 'panic_gesture_type';
  static const _panicGestureDataKey = 'panic_gesture_data';
  static const _panicEnabledKey = 'panic_button_enabled';
  
  final _redBoxService = RedBoxService();
  
  // Get the current panic gesture type
  Future<PanicGestureType> getPanicGestureType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gestureTypeIndex = prefs.getInt(_panicGestureKey) ?? 0;
      return PanicGestureType.values[gestureTypeIndex];
    } catch (e) {
      debugPrint('Error getting panic gesture type: ${e.toString()}');
      return PanicGestureType.tripleTap; // Default to triple tap
    }
  }
  
  // Check if panic button is enabled
  Future<bool> isPanicButtonEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_panicEnabledKey) ?? true; // Enabled by default
    } catch (e) {
      debugPrint('Error checking if panic button is enabled: ${e.toString()}');
      return true;
    }
  }
  
  // Enable or disable panic button
  Future<bool> togglePanicButton(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_panicEnabledKey, enabled);
      return true;
    } catch (e) {
      debugPrint('Error toggling panic button: ${e.toString()}');
      return false;
    }
  }
  
  // Configure the panic gesture
  Future<bool> configurePanicGesture(PanicGestureType gestureType, Map<String, dynamic> gestureData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_panicGestureKey, gestureType.index);
      await prefs.setString(_panicGestureDataKey, jsonEncode(gestureData));
      return true;
    } catch (e) {
      debugPrint('Error configuring panic gesture: ${e.toString()}');
      return false;
    }
  }
  
  // Get gesture configuration data
  Future<Map<String, dynamic>> getGestureData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gestureDataJson = prefs.getString(_panicGestureDataKey);
      
      if (gestureDataJson != null) {
        return jsonDecode(gestureDataJson);
      }
      
      return {}; // Default empty configuration
    } catch (e) {
      debugPrint('Error getting gesture data: ${e.toString()}');
      return {};
    }
  }
  
  // Handle panic button trigger
  Future<void> handlePanic(BuildContext context) async {
    // Clear Red Box cache
    await _redBoxService.clearRedBoxCache();
    
    // Close all dialogs
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    
    // Reset any in-memory sensitive data
    // This could be expanded based on what sensitive data the app holds
    
    // Optional: Show a snackbar or feedback that the app has exited secure mode
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exited secure mode'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  // Detect triple tap gesture
  GestureDetector wrapWithTripleTapDetection(BuildContext context, Widget child) {
    return GestureDetector(
      onTap: () {
        // Implement tap counter with timing logic
        _handleTapDetection(context);
      },
      child: child,
    );
  }
  
  // Track tap count and timing
  DateTime? _lastTap;
  int _tapCount = 0;
  
  void _handleTapDetection(BuildContext context) async {
    final now = DateTime.now();
    
    // Reset counter if more than 1 second since last tap
    if (_lastTap != null && now.difference(_lastTap!).inMilliseconds > 1000) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    
    _lastTap = now;
    
    // Check for triple tap
    if (_tapCount == 3) {
      _tapCount = 0; // Reset counter
      
      final isEnabled = await isPanicButtonEnabled();
      if (isEnabled) {
        await handlePanic(context);
      }
    }
  }
  
  // Detect shake gesture (to be implemented with accelerometer package)
  // This would require adding the 'sensors_plus' package
  void startShakeDetection(BuildContext context) {
    // Implementation would go here
    // For a complete implementation, add:
    // import 'package:sensors_plus/sensors_plus.dart';
    // Then implement shake detection with the accelerometer data
  }
  
  // Detect volume key sequence
  // This would require a platform-specific implementation with method channels
  void startVolumeKeyDetection(BuildContext context) {
    // This requires platform-specific code on Android/iOS
    // Would need a MethodChannel implementation
  }
} 