import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'red_box_service.dart';

class ConnectivityService {
  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  
  factory ConnectivityService() => _instance;
  
  ConnectivityService._internal();
  
  final _connectivity = Connectivity();
  final _redBoxService = RedBoxService();
  
  // Stream controller to broadcast connection status changes
  final _connectionStatusController = StreamController<bool>.broadcast();
  
  // Current connection status
  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;
  
  // Stream of connection status (true = connected, false = disconnected)
  Stream<bool> get connectionStream => _connectionStatusController.stream;
  
  // Initialize service and start monitoring connectivity
  Future<void> initialize() async {
    // Check initial connection status
    _checkConnectionStatus();
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      _processConnectivityResult(result);
    });
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
        // We're back online, sync pending messages
        _syncPendingMessages();
      }
    }
  }
  
  // Sync any pending messages when back online
  Future<void> _syncPendingMessages() async {
    try {
      await _redBoxService.syncPendingMessages();
    } catch (e) {
      debugPrint('Error syncing pending messages: ${e.toString()}');
    }
  }
  
  // Force a sync of pending messages
  Future<void> forceSyncPendingMessages() async {
    if (_hasConnection) {
      await _syncPendingMessages();
    }
  }
  
  // Clean up resources
  void dispose() {
    _connectionStatusController.close();
  }
} 