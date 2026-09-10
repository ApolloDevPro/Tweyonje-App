import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/services/sync_service.dart';

/// Shows connection status and pending sync actions
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final connectivity = ref.watch(_connectivityProvider);

    return syncStatus.when(
      data: (status) {
        if (status.state == SyncState.synced && 
            connectivity.valueOrNull == false) {
          return _buildBanner(
            context,
            icon: Icons.cloud_off,
            text: 'You are offline',
            color: Colors.grey[700]!,
          );
        }

        if (status.pendingCount > 0) {
          return _buildBanner(
            context,
            icon: status.state == SyncState.syncing
                ? Icons.cloud_upload
                : Icons.cloud_queue,
            text: status.state == SyncState.syncing
                ? 'Syncing ${status.pendingCount} action(s)...'
                : '${status.pendingCount} action(s) pending',
            color: status.state == SyncState.error
                ? Colors.orange
                : Colors.blue,
            showProgress: status.state == SyncState.syncing,
          );
        }

        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    bool showProgress = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (showProgress)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// Provider for connectivity status
final _connectivityProvider = StreamProvider<bool>((ref) {
  final stream = Connectivity().onConnectivityChanged;
  return stream.map((results) => results.isNotEmpty && results.any((result) => result != ConnectivityResult.none));
});

/// Floating action button to manually trigger sync
class SyncFAB extends ConsumerWidget {
  const SyncFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingActionsCountProvider);

    return pendingCount.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: () async {
            final syncService = ref.read(syncServiceProvider);
            await syncService.syncNow();
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing...'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          icon: const Icon(Icons.sync),
          label: Text('Sync $count action(s)'),
          backgroundColor: Colors.blue,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Dialog to show pending actions
class PendingActionsDialog extends ConsumerWidget {
  const PendingActionsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);
    final actions = syncService.getPendingActions();

    return AlertDialog(
      title: const Text('Pending Actions'),
      content: SizedBox(
        width: double.maxFinite,
        child: actions.isEmpty
            ? const Center(
                child: Text('No pending actions'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return ListTile(
                    leading: _getActionIcon(action.type),
                    title: Text(_getActionTitle(action.type)),
                    subtitle: Text(
                      'Created: ${_formatDate(action.createdAt)}\n'
                      'Retries: ${action.retryCount}',
                    ),
                    trailing: action.retryCount >= 3
                        ? const Icon(Icons.error, color: Colors.red)
                        : null,
                  );
                },
              ),
      ),
      actions: [
        if (actions.isNotEmpty)
          TextButton(
            onPressed: () async {
              await syncService.clearQueue();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (actions.isNotEmpty)
          ElevatedButton(
            onPressed: () async {
              await syncService.syncNow();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Sync Now'),
          ),
      ],
    );
  }

  Icon _getActionIcon(String type) {
    switch (type) {
      case 'create_request':
        return const Icon(Icons.add_circle, color: Colors.green);
      case 'cancel_request':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'update_location':
        return const Icon(Icons.location_on, color: Colors.blue);
      case 'upload_photo':
        return const Icon(Icons.photo_camera, color: Colors.purple);
      default:
        return const Icon(Icons.sync, color: Colors.grey);
    }
  }

  String _getActionTitle(String type) {
    switch (type) {
      case 'create_request':
        return 'Create Waste Request';
      case 'cancel_request':
        return 'Cancel Request';
      case 'update_location':
        return 'Update Location';
      case 'upload_photo':
        return 'Upload Photo';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
