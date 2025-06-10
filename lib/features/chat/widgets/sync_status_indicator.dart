import 'package:flutter/material.dart';
import '../../../services/connectivity_service.dart';

class SyncStatusIndicator extends StatefulWidget {
  final double size;
  final bool showLabel;
  
  const SyncStatusIndicator({
    Key? key, 
    this.size = 16.0, 
    this.showLabel = true,
  }) : super(key: key);

  @override
  _SyncStatusIndicatorState createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  final _connectivityService = ConnectivityService();
  SyncStatus _currentStatus = SyncStatus.synced;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentStatus = _connectivityService.syncStatus;
    _listenToSyncChanges();
  }

  void _listenToSyncChanges() {
    _connectivityService.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
          if (status == SyncStatus.error) {
            _errorMessage = _connectivityService.lastSyncError;
          } else {
            _errorMessage = null;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _getTooltipMessage(),
      child: InkWell(
        onTap: _onTap,
        borderRadius: BorderRadius.circular(widget.size),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              if (widget.showLabel) ...[
                const SizedBox(width: 4),
                Text(_getStatusText(), style: TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (_currentStatus) {
      case SyncStatus.synced:
        return Icon(Icons.check_circle, size: widget.size, color: Colors.green);
      case SyncStatus.syncing:
        return SizedBox(
          width: widget.size, 
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: 2, 
            color: Theme.of(context).primaryColor, 
            backgroundColor: Colors.grey.shade200,
          ),
        );
      case SyncStatus.pendingSync:
        return Icon(Icons.sync, size: widget.size, color: Colors.amber);
      case SyncStatus.error:
        return Icon(Icons.error_outline, size: widget.size, color: Colors.red);
      case SyncStatus.offline:
        return Icon(Icons.cloud_off, size: widget.size, color: Colors.grey);
    }
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case SyncStatus.synced:
        return "Synced";
      case SyncStatus.syncing:
        return "Syncing...";
      case SyncStatus.pendingSync:
        return "Pending";
      case SyncStatus.error:
        return "Error";
      case SyncStatus.offline:
        return "Offline";
    }
  }

  String _getTooltipMessage() {
    switch (_currentStatus) {
      case SyncStatus.synced:
        final lastSyncTime = _connectivityService.lastSyncTime;
        if (lastSyncTime != null) {
          final timeString = _formatDateTime(lastSyncTime);
          return "All messages synced at $timeString";
        }
        return "All messages synced";
      case SyncStatus.syncing:
        return "Syncing messages with server...";
      case SyncStatus.pendingSync:
        return "Messages waiting to be synced";
      case SyncStatus.error:
        return _errorMessage ?? "Error during sync";
      case SyncStatus.offline:
        return "You are offline. Messages will sync when connected.";
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (dateToCheck == today) {
      return "Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return "Yesterday at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    }
  }

  void _onTap() {
    switch (_currentStatus) {
      case SyncStatus.pendingSync:
        _connectivityService.forceSyncPendingMessages();
        break;
      case SyncStatus.error:
        _connectivityService.retrySyncAfterError();
        break;
      case SyncStatus.offline:
        // Show a message that we're offline
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You're offline. Messages will sync when you're back online."),
            duration: Duration(seconds: 3),
          ),
        );
        break;
      default:
        break;
    }
  }
} 