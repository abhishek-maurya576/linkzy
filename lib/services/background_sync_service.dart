import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
import 'red_box_service.dart';

class BackgroundSyncService {
  // Singleton pattern
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  
  factory BackgroundSyncService() => _instance;
  
  BackgroundSyncService._internal();
  
  final _redBoxService = RedBoxService();
  final _connectivityService = ConnectivityService();
  
  Timer? _syncTimer;
  bool _isInitialized = false;
  
  // Initialize background sync
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Set up periodic sync
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _performBackgroundSync();
    });
    
    // Also sync when connectivity changes
    _connectivityService.connectionStream.listen((isConnected) {
      if (isConnected) {
        _performBackgroundSync();
      }
    });
    
    _isInitialized = true;
  }
  
  // Perform background sync
  Future<void> _performBackgroundSync() async {
    try {
      if (!_connectivityService.hasConnection) {
        return; // Don't try to sync when offline
      }
      
      final currentUserId = _redBoxService.currentUserId;
      if (currentUserId == null) {
        return; // Don't sync if not authenticated
      }
      
      // Check if we have pending messages
      final hasPending = await _redBoxService.hasPendingMessages();
      
      // Check if we need to refresh cached data
      final needsDataRefresh = await _needsDataRefresh();
      
      // Sync pending messages if any
      if (hasPending) {
        await _connectivityService.forceSyncPendingMessages();
      }
      
      // Refresh cached data if needed
      if (needsDataRefresh) {
        await _redBoxService.cacheAppData(currentUserId);
        await _updateLastCacheTime();
      }
    } catch (e) {
      debugPrint('Error in background sync: ${e.toString()}');
    }
  }
  
  // Check if we need to refresh cached data
  Future<bool> _needsDataRefresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCacheTimeMs = prefs.getInt('app_data_last_cache_time');
      
      if (lastCacheTimeMs == null) {
        return true; // Never cached before
      }
      
      final lastCacheTime = DateTime.fromMillisecondsSinceEpoch(lastCacheTimeMs);
      final now = DateTime.now();
      
      // Refresh if last cache was more than 2 hours ago
      return now.difference(lastCacheTime).inHours >= 2;
    } catch (e) {
      debugPrint('Error checking data refresh: ${e.toString()}');
      return false;
    }
  }
  
  // Update last cache time
  Future<void> _updateLastCacheTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_data_last_cache_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating last cache time: ${e.toString()}');
    }
  }
  
  // Force manual sync
  Future<void> forceSync() async {
    await _performBackgroundSync();
  }
  
  // Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _isInitialized = false;
  }
} 