import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_client.dart';

/// Represents an action queued for execution when online
class PendingAction {
  final String id;
  final String type; // 'create_request', 'update_request', 'upload_photo', etc.
  final String endpoint;
  final String method; // GET, POST, PUT, DELETE
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? localReference; // Local ID for optimistic updates

  PendingAction({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.method,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.localReference,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'endpoint': endpoint,
        'method': method,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'localReference': localReference,
      };

  factory PendingAction.fromJson(Map<String, dynamic> json) => PendingAction(
        id: json['id'] as String,
        type: json['type'] as String,
        endpoint: json['endpoint'] as String,
        method: json['method'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: (json['retryCount'] as int?) ?? 0,
        localReference: json['localReference'] as String?,
      );

  PendingAction copyWith({
    int? retryCount,
    Map<String, dynamic>? data,
  }) =>
      PendingAction(
        id: id,
        type: type,
        endpoint: endpoint,
        method: method,
        data: data ?? this.data,
        createdAt: createdAt,
        retryCount: retryCount ?? this.retryCount,
        localReference: localReference,
      );
}

/// Service that manages offline action queueing and synchronization
class SyncService {
  static const String _boxName = 'pending_actions';
  static const int _maxRetries = 3;

  late Box<String> _box;
  final ApiClient _apiClient;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  SyncService(this._apiClient, this._connectivity);

  /// Initialize the sync service and start monitoring connectivity
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);

    // Start listening to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = results.any((result) => result != ConnectivityResult.none);
      if (isConnected) {
        _triggerSync();
      }
    });

    // Periodic sync every 5 minutes when online
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _triggerSync();
    });

    // Initial sync on startup if online
    final connectivityResults = await _connectivity.checkConnectivity();
    final isConnected = connectivityResults.any((result) => result != ConnectivityResult.none);
    if (isConnected) {
      _triggerSync();
    }
  }

  /// Queue an action for later execution when online
  Future<String> queueAction(PendingAction action) async {
    await _box.put(action.id, jsonEncode(action.toJson()));
    _emitStatus(SyncStatus.queued(1));
    
    // Try immediate sync if online
    _triggerSync();
    
    return action.id;
  }

  /// Get count of pending actions
  int get pendingCount => _box.length;

  /// Check if there are pending actions
  bool get hasPendingActions => _box.isNotEmpty;

  /// Get all pending actions
  List<PendingAction> getPendingActions() {
    return _box.values
        .map((json) => PendingAction.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Trigger a sync cycle
  Future<void> _triggerSync() async {
    if (_isSyncing || _box.isEmpty) return;

    _isSyncing = true;
    _emitStatus(SyncStatus.syncing(pendingCount));

    try {
      final actions = getPendingActions();
      int failCount = 0;

      for (final action in actions) {
        try {
          await _executeAction(action);
          await _box.delete(action.id);
        } catch (e) {
          // Check if should retry
          if (action.retryCount >= _maxRetries) {
            // Max retries exceeded - delete the action
            await _box.delete(action.id);
            failCount++;
          } else {
            // Increment retry count and keep in queue
            final updated = action.copyWith(retryCount: action.retryCount + 1);
            await _box.put(action.id, jsonEncode(updated.toJson()));
            failCount++;
          }
        }
      }

      if (failCount == 0 && pendingCount == 0) {
        _emitStatus(SyncStatus.synced());
      } else if (failCount > 0) {
        _emitStatus(SyncStatus.error(pendingCount, 'Some actions failed'));
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute a single pending action
  Future<void> _executeAction(PendingAction action) async {
    switch (action.method.toUpperCase()) {
      case 'GET':
        await _apiClient.get(action.endpoint);
        break;
      case 'POST':
        await _apiClient.post(
          action.endpoint,
          data: action.data,
        );
        break;
      case 'PUT':
        await _apiClient.put(
          action.endpoint,
          data: action.data,
        );
        break;
      case 'PATCH':
        await _apiClient.patch(
          action.endpoint,
          data: action.data,
        );
        break;
      case 'DELETE':
        await _apiClient.delete(action.endpoint);
        break;
      default:
        throw UnsupportedError('HTTP method ${action.method} not supported');
    }
  }

  /// Manually trigger sync
  Future<void> syncNow() async {
    await _triggerSync();
  }

  /// Clear all pending actions (use with caution)
  Future<void> clearQueue() async {
    await _box.clear();
    _emitStatus(SyncStatus.synced());
  }

  void _emitStatus(SyncStatus status) {
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(status);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    await _syncStatusController.close();
    await _box.close();
  }
}

/// Represents the current sync status
class SyncStatus {
  final SyncState state;
  final int pendingCount;
  final String? message;

  const SyncStatus._(this.state, this.pendingCount, [this.message]);

  factory SyncStatus.queued(int count) => SyncStatus._(SyncState.queued, count);
  factory SyncStatus.syncing(int count) => SyncStatus._(SyncState.syncing, count);
  factory SyncStatus.synced() => const SyncStatus._(SyncState.synced, 0);
  factory SyncStatus.error(int count, String message) => 
      SyncStatus._(SyncState.error, count, message);
}

enum SyncState {
  queued,
  syncing,
  synced,
  error,
}

/// Riverpod provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SyncService(apiClient, Connectivity());
});

/// Provider to watch pending action count
final pendingActionsCountProvider = StreamProvider<int>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  
  // Return a stream that emits the pending count whenever sync status changes
  return syncService.syncStatus.map((_) => syncService.pendingCount);
});

/// Provider to watch sync status
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStatus;
});
