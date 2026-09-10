# Offline Sync Implementation Guide

The Tweyonje app includes a robust offline-first architecture that queues actions when the device is offline and automatically syncs them when connectivity is restored.

## Architecture Overview

```
┌─────────────┐
│   User      │
│   Action    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Connectivity Check                  │
│  (connectivity_plus)                 │
└─────┬─────────────────────┬─────────┘
      │                     │
   Online                Offline
      │                     │
      ▼                     ▼
┌───────────┐         ┌────────────────┐
│  Execute  │         │  Queue Action  │
│  API Call │         │  in Hive       │
└───────────┘         └────────────────┘
                            │
                            ▼
                      ┌──────────────────┐
                      │  Wait for         │
                      │  Connectivity     │
                      └────────┬──────────┘
                               │
                               ▼
                      ┌──────────────────┐
                      │  Auto Sync        │
                      │  (retry 3x)       │
                      └──────────────────┘
```

## Core Components

### 1. SyncService

Location: `lib/core/services/sync_service.dart`

Manages the offline queue and synchronization lifecycle.

**Key Features:**
- Stores pending actions in Hive (persistent local storage)
- Monitors connectivity changes
- Auto-syncs when connection is restored
- Retries failed actions up to 3 times
- Periodic sync every 5 minutes
- Broadcasts sync status via streams

### 2. PendingAction Model

Represents a queued action:

```dart
class PendingAction {
  final String id;              // Unique UUID
  final String type;            // Action type (e.g., 'create_request')
  final String endpoint;        // API endpoint
  final String method;          // HTTP method (GET, POST, PUT, DELETE)
  final Map<String, dynamic> data;  // Request payload
  final DateTime createdAt;     // Timestamp
  final int retryCount;         // Number of retry attempts
  final String? localReference; // Local ID for optimistic updates
}
```

### 3. OfflineAwareApi Extension

Location: `lib/core/services/offline_aware_api.dart`

Extension methods on `ApiClient` for offline-aware requests:

```dart
// POST with offline support
await apiClient.postWithOfflineSupport(
  endpoint: '/api/v1/waste-requests/',
  data: requestData,
  syncService: syncService,
  actionType: 'create_request',
  localReference: localId,
);

// PUT/PATCH with offline support
await apiClient.updateWithOfflineSupport(
  endpoint: '/api/v1/waste-requests/$id/',
  data: updateData,
  syncService: syncService,
  actionType: 'update_request',
  method: 'PATCH',
);
```

### 4. UI Components

Location: `lib/widgets/offline_indicator.dart`

**OfflineIndicator** - Shows connection status banner
**SyncFAB** - Floating action button to manually trigger sync
**PendingActionsDialog** - View and manage queued actions

## Usage Examples

### Initialize SyncService

In `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  final syncService = container.read(syncServiceProvider);
  await syncService.init();
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: TweyonjeApp(),
    ),
  );
}
```

### Create Waste Request Offline

```dart
class CreateRequestScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);
    final apiClient = ref.watch(apiClientProvider);
    
    return ElevatedButton(
      onPressed: () async {
        try {
          final helper = OfflineWasteRequestHelper(
            syncService: syncService,
            apiClient: apiClient,
          );
          
          final result = await helper.createRequest(
            category: selectedCategory,
            pickupAddress: address,
            latitude: location.latitude,
            longitude: location.longitude,
            isEmergency: false,
          );
          
          if (result['_queued'] == true) {
            // Action was queued offline
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Request queued. Will sync when online.'),
              ),
            );
          } else {
            // Action executed immediately
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Request created successfully!'),
              ),
            );
          }
        } catch (e) {
          // Handle error
        }
      },
      child: Text('Create Request'),
    );
  }
}
```

### Show Offline Indicator

Add to your main scaffold:

```dart
Scaffold(
  body: Column(
    children: [
      const OfflineIndicator(), // Shows "Offline" or "X actions pending"
      Expanded(
        child: YourContent(),
      ),
    ],
  ),
  floatingActionButton: const SyncFAB(), // Shows when actions are pending
)
```

### Watch Sync Status

```dart
class SyncStatusWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    
    return syncStatus.when(
      data: (status) {
        switch (status.state) {
          case SyncState.queued:
            return Text('${status.pendingCount} actions queued');
          case SyncState.syncing:
            return Text('Syncing ${status.pendingCount} actions...');
          case SyncState.synced:
            return Text('All synced ✓');
          case SyncState.error:
            return Text('Sync error: ${status.message}');
        }
      },
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

### Manual Sync Trigger

```dart
ElevatedButton(
  onPressed: () async {
    final syncService = ref.read(syncServiceProvider);
    await syncService.syncNow();
  },
  child: Text('Sync Now'),
)
```

### View Pending Actions

```dart
IconButton(
  icon: Icon(Icons.sync),
  onPressed: () {
    showDialog(
      context: context,
      builder: (_) => const PendingActionsDialog(),
    );
  },
)
```

## Optimistic Updates

For better UX, show local data immediately and sync in the background:

```dart
// 1. Generate local ID
final localId = const Uuid().v4();

// 2. Add to local state immediately
ref.read(wasteRequestsProvider.notifier).addLocal(
  WasteRequest(
    id: localId,
    status: 'PENDING',
    isPending: true, // Flag as local/pending
  ),
);

// 3. Queue for sync
await helper.createRequest(
  category: category,
  pickupAddress: address,
  localReference: localId,
);

// 4. When synced, replace local ID with server ID
syncService.syncStatus.listen((status) {
  if (status.state == SyncState.synced) {
    // Fetch from server and update local state
    ref.read(wasteRequestsProvider.notifier).refresh();
  }
});
```

## Retry Logic

- **Max Retries**: 3 attempts
- **Retry Delay**: Immediate on next sync cycle
- **Failure Handling**: After 3 failed attempts, action is deleted from queue

## Testing Offline Behavior

### Simulate Offline Mode

**Android Emulator:**
1. Settings → Network & internet → Internet → Turn off Wi-Fi
2. Or in terminal: `adb shell svc wifi disable`

**iOS Simulator:**
1. Settings → Wi-Fi → Turn off
2. Or in Xcode: Debug → Simulate Location → Custom Location (disconnect network)

**Flutter DevTools:**
1. Open DevTools
2. Network tab → Throttle network

### Test Cases

1. **Create request offline** → Turn off network → Create request → Should show "queued" message
2. **Restore connection** → Turn on network → Should auto-sync within 5 seconds
3. **Force sync** → Tap "Sync Now" button → Should sync immediately
4. **View queue** → Tap sync icon → Should show pending actions dialog
5. **Failed sync** → Return 500 error → Should retry up to 3 times
6. **Clear queue** → In pending actions dialog → Clear All

## Performance Considerations

- **Storage**: Hive is lightweight (~ 2MB for 1000 actions)
- **Sync Frequency**: Every 5 minutes or on connectivity change
- **Batch Processing**: Actions sync sequentially (not in parallel to preserve order)
- **Memory**: Pending actions are loaded from disk only during sync

## Security

- **Token Expiry**: If JWT expires while offline, sync will fail. User must re-authenticate.
- **Sensitive Data**: Don't queue actions containing passwords or payment details
- **Encryption**: Use `flutter_secure_storage` for tokens, not Hive

## Troubleshooting

**Actions not syncing?**
- Check connectivity with `ref.watch(_connectivityProvider)`
- Check SyncService is initialized in `main.dart`
- Check pending count: `ref.watch(pendingActionsCountProvider)`

**Actions failing after 3 retries?**
- Check backend API logs for 4xx/5xx errors
- Verify JWT token is still valid
- Check request payload format

**High memory usage?**
- Limit Hive box size to 1000 actions max
- Clear old completed actions periodically

## Future Enhancements

- [ ] Conflict resolution (optimistic locking)
- [ ] Action prioritization (emergency requests first)
- [ ] Background sync with WorkManager
- [ ] Compress large payloads before queueing
- [ ] Delta sync (only send changed fields)
