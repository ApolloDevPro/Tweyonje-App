import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/app_database.dart';
import 'api_client.dart';
import 'logger.dart';

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

/// Service that manages offline action queueing and synchronization.
///
/// The queue is persisted in the shared SQLite database (`pending_actions`
/// table) and mirrored by an in-memory cache so the synchronous public getters
/// ([pendingCount], [hasPendingActions], [getPendingActions]) need no I/O.
class SyncService {
  static const String _table = 'pending_actions';
  static const int _maxRetries = 3;

  final ApiClient _apiClient;
  final Connectivity _connectivity;

  /// In-memory cache of queued actions, authoritative for the sync getters.
  final Map<String, PendingAction> _actions = {};

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  SyncService(this._apiClient, this._connectivity);

  /// Initialize the sync service and start monitoring connectivity
  Future<void> init() async {
    try {
      await _restoreFromDatabase();
    } catch (e) {
      Logger.error('Failed to restore pending actions', error: e);
    }

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

  /// Loads queued actions from SQLite into the in-memory cache.
  Future<void> _restoreFromDatabase() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(_table);
    _actions.clear();
    for (final row in rows) {
      try {
        final action = PendingAction.fromJson(
          Map<String, dynamic>.from(jsonDecode(row['data'] as String) as Map),
        );
        _actions[action.id] = action;
      } catch (e) {
        Logger.error('Failed to restore pending action', error: e);
      }
    }
  }

  /// Queue an action for later execution when online
  Future<String> queueAction(PendingAction action) async {
    _actions[action.id] = action;
    try {
      final db = await AppDatabase.instance.database;
      await db.insert(
        _table,
        {
          'id': action.id,
          'data': jsonEncode(action.toJson()),
          'created_at': action.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger.error('Failed to persist pending action', error: e);
    }
    _emitStatus(SyncStatus.queued(pendingCount));

    // Try immediate sync if online
    _triggerSync();

    return action.id;
  }

  /// Get count of pending actions
  int get pendingCount => _actions.length;

  /// Check if there are pending actions
  bool get hasPendingActions => _actions.isNotEmpty;

  /// Get all pending actions
  List<PendingAction> getPendingActions() {
    return _actions.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Trigger a sync cycle
  Future<void> _triggerSync() async {
    if (_isSyncing || _actions.isEmpty) return;

    _isSyncing = true;
    _emitStatus(SyncStatus.syncing(pendingCount));

    try {
      final actions = getPendingActions();
      int failCount = 0;

      for (final action in actions) {
        try {
          await _executeAction(action);
          _actions.remove(action.id);
          await _deleteFromDatabase(action.id);
        } catch (e) {
          // Check if should retry
          if (action.retryCount >= _maxRetries) {
            // Max retries exceeded - delete the action
            _actions.remove(action.id);
            await _deleteFromDatabase(action.id);
            failCount++;
          } else {
            // Increment retry count and keep in queue
            final updated = action.copyWith(retryCount: action.retryCount + 1);
            _actions[action.id] = updated;
            await _persistAction(updated);
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
    _actions.clear();
    try {
      final db = await AppDatabase.instance.database;
      await db.delete(_table);
    } catch (e) {
      Logger.error('Failed to clear pending actions', error: e);
    }
    _emitStatus(SyncStatus.synced());
  }

  Future<void> _persistAction(PendingAction action) async {
    try {
      final db = await AppDatabase.instance.database;
      await db.insert(
        _table,
        {
          'id': action.id,
          'data': jsonEncode(action.toJson()),
          'created_at': action.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger.error('Failed to persist pending action', error: e);
    }
  }

  Future<void> _deleteFromDatabase(String id) async {
    try {
      final db = await AppDatabase.instance.database;
      await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      Logger.error('Failed to remove pending action from database', error: e);
    }
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
    _actions.clear();
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