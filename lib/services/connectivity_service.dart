import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'red_box_service.dart';

enum SyncStatus {
  synced,       // All messages are synced
  syncing,      // Currently syncing messages
  pendingSync,  // Messages are waiting to be synced
  error,        // Error occurred during sync
  offline       // Device is offline
}

class ConnectivityService {
  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  
  factory ConnectivityService() => _instance;
  
  ConnectivityService._internal();
  
  final _connectivity = Connectivity();
  final _redBoxService = RedBoxService();
  
  // Stream controller to broadcast connection status changes
  final _connectionStatusController = StreamController<bool>.broadcast();
  
  // Stream controller for sync status
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  
  // Current connection status
  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;
  
  // Current sync status
  SyncStatus _syncStatus = SyncStatus.synced;
  SyncStatus get syncStatus => _syncStatus;
  
  // Last sync time
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;
  
  // Error details from last sync attempt
  String? _lastSyncError;
  String? get lastSyncError => _lastSyncError;
  
  // Stream of connection status (true = connected, false = disconnected)
  Stream<bool> get connectionStream => _connectionStatusController.stream;
  
  // Stream of sync status
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  
  // Constants
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _pendingChangesKey = 'pending_changes_count';
  static const Duration _syncInterval = Duration(minutes: 15);
  static const int _maxRetryAttempts = 3;
  
  // Initialize service and start monitoring connectivity
  Future<void> initialize() async {
    // Load last sync time
    await _loadLastSyncTime();
    
    // Check if there are pending changes
    await _checkPendingChanges();
    
    // Check initial connection status
    _checkConnectionStatus();
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      _processConnectivityResult(result);
    });
    
    // Set up periodic sync
    Timer.periodic(_syncInterval, (_) {
      if (_hasConnection && _syncStatus == SyncStatus.pendingSync) {
        _syncPendingMessages();
      }
    });
  }
  
  // Load last sync time from persistent storage
  Future<void> _loadLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTimeMs = prefs.getInt(_lastSyncTimeKey);
      if (lastSyncTimeMs != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncTimeMs);
      }
    } catch (e) {
      debugPrint('Error loading last sync time: ${e.toString()}');
    }
  }
  
  // Save last sync time to persistent storage
  Future<void> _saveLastSyncTime() async {
    try {
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncTimeKey, _lastSyncTime!.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving last sync time: ${e.toString()}');
    }
  }
  
  // Check for pending changes
  Future<void> _checkPendingChanges() async {
    try {
      final hasPendingChanges = await _redBoxService.hasPendingMessages();
      if (hasPendingChanges) {
        _updateSyncStatus(SyncStatus.pendingSync);
      }
    } catch (e) {
      debugPrint('Error checking pending changes: ${e.toString()}');
    }
  }
  
  // Check current connection status
  Future<void> _checkConnectionStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _processConnectivityResult(result);
    } catch (e) {
      debugPrint('Error checking connectivity: ${e.toString()}');
      _updateConnectionStatus(false);
    }
  }
  
  // Process connectivity result
  void _processConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.none:
        _updateConnectionStatus(false);
        break;
      case ConnectivityResult.mobile:
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
      case ConnectivityResult.vpn:
        _updateConnectionStatus(true);
        break;
      default:
        _updateConnectionStatus(false);
    }
  }
  
  // Update connection status and notify subscribers
  void _updateConnectionStatus(bool isConnected) {
    if (_hasConnection != isConnected) {
      _hasConnection = isConnected;
      _connectionStatusController.add(_hasConnection);
      
      if (_hasConnection) {
        // We're back online, check if we need to sync
        _checkPendingChanges();
        if (_syncStatus == SyncStatus.pendingSync || _syncStatus == SyncStatus.offline) {
          _syncPendingMessages();
        }
      } else {
        // We're offline
        _updateSyncStatus(SyncStatus.offline);
      }
    }
  }
  
  // Update sync status and notify subscribers
  void _updateSyncStatus(SyncStatus status) {
    if (_syncStatus != status) {
      _syncStatus = status;
      _syncStatusController.add(_syncStatus);
    }
  }
  
  // Sync any pending messages when back online
  Future<void> _syncPendingMessages() async {
    if (!_hasConnection) {
      _updateSyncStatus(SyncStatus.offline);
      return;
    }
    
    if (_syncStatus == SyncStatus.syncing) {
      return; // Already syncing
    }
    
    _updateSyncStatus(SyncStatus.syncing);
    _lastSyncError = null;
    
    try {
      int retryCount = 0;
      bool success = false;
      
      while (retryCount < _maxRetryAttempts && !success) {
        try {
          await _redBoxService.syncPendingMessages();
          success = true;
        } catch (e) {
          retryCount++;
          if (retryCount >= _maxRetryAttempts) {
            throw e;
          }
          // Wait before retrying
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
      
      await _saveLastSyncTime();
      _updateSyncStatus(SyncStatus.synced);
    } catch (e) {
      debugPrint('Error syncing pending messages: ${e.toString()}');
      _lastSyncError = e.toString();
      _updateSyncStatus(SyncStatus.error);
    }
  }
  
  // Force a sync of pending messages
  Future<void> forceSyncPendingMessages() async {
    if (_hasConnection) {
      await _syncPendingMessages();
    }
  }
  
  // Check if a sync is needed
  bool isSyncNeeded() {
    // Sync is needed if we have pending changes or haven't synced in a while
    return _syncStatus == SyncStatus.pendingSync || 
           _syncStatus == SyncStatus.error || 
           (_lastSyncTime != null && 
           DateTime.now().difference(_lastSyncTime!) > _syncInterval);
  }
  
  // Reset sync error state and retry
  Future<void> retrySyncAfterError() async {
    if (_syncStatus == SyncStatus.error && _hasConnection) {
      _lastSyncError = null;
      await _syncPendingMessages();
    }
  }
  
  // Clean up resources
  void dispose() {
    _connectionStatusController.close();
    _syncStatusController.close();
  }
} 