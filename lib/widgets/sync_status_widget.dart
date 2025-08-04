import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sync_service.dart';

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final SyncService _syncService = SyncService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update status every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (_syncService.syncStatus) {
      case SyncStatus.idle:
        return Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.offline:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon() {
    switch (_syncService.syncStatus) {
      case SyncStatus.idle:
        return Icons.cloud_outlined;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.success:
        return Icons.cloud_done;
      case SyncStatus.error:
        return Icons.error;
      case SyncStatus.offline:
        return Icons.cloud_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        border: Border(bottom: BorderSide(color: _getStatusColor().withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_syncService.getStatusMessage(), style: TextStyle(color: _getStatusColor(), fontSize: 12)),
          ),
          if (_syncService.pendingRequests.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
              child: Text(
                '${_syncService.pendingRequests.length}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}