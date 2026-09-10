import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../models/models.dart';
import '../services/logger.dart';

class OfflineStorage {
  static const String _wasteRequestsBoxName = 'waste_requests';
  static const String _syncQueueBoxName = 'sync_queue';
  static const String _userProfileBoxName = 'user_profile';
  static const String _cachedDataBoxName = 'cached_data';

  late Box<Map> _wasteRequestsBox;
  late Box<String> _syncQueueBox;
  late Box<Map> _userProfileBox;
  late Box<String> _cachedDataBox;

  Future<void> init() async {
    if (kIsWeb) {
      // path_provider is not available on the web. Hive uses IndexedDB
      // when initialized with a database name instead of a file path.
      Hive.init('tweyonje_offline');
    } else {
      await Hive.initFlutter();
    }

    // Register adapters if needed
    // Hive.registerAdapter(WasteRequestAdapter());
    
    _wasteRequestsBox = await Hive.openBox<Map>(_wasteRequestsBoxName);
    _syncQueueBox = await Hive.openBox<String>(_syncQueueBoxName);
    _userProfileBox = await Hive.openBox<Map>(_userProfileBoxName);
    _cachedDataBox = await Hive.openBox<String>(_cachedDataBoxName);
    
    Logger.info('Offline storage initialized');
  }

  // Waste Requests
  Future<void> saveWasteRequest(WasteRequest request) async {
    await _wasteRequestsBox.put(request.id, request.toJson());
    Logger.debug('Saved waste request offline: ${request.id}');
  }

  Future<WasteRequest?> getWasteRequest(String id) async {
    final data = _wasteRequestsBox.get(id);
    if (data != null) {
      return WasteRequest.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<List<WasteRequest>> getAllWasteRequests() async {
    final requests = <WasteRequest>[];
    for (final key in _wasteRequestsBox.keys) {
      final data = _wasteRequestsBox.get(key);
      if (data != null) {
        requests.add(WasteRequest.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    return requests;
  }

  Future<void> deleteWasteRequest(String id) async {
    await _wasteRequestsBox.delete(id);
    Logger.debug('Deleted waste request: $id');
  }

  // Sync Queue
  Future<void> addToSyncQueue(Map<String, dynamic> operation) async {
    final operationJson = jsonEncode(operation);
    await _syncQueueBox.add(operationJson);
    Logger.debug('Added operation to sync queue: ${operation['type']}');
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final operations = <Map<String, dynamic>>[];
    for (final operationJson in _syncQueueBox.values) {
      try {
        final operation = jsonDecode(operationJson) as Map<String, dynamic>;
        operations.add(operation);
      } catch (e) {
        Logger.error('Failed to parse sync queue operation', error: e);
      }
    }
    return operations;
  }

  Future<void> removeFromSyncQueue(String operationId) async {
    // Find and remove the operation by ID
    final operations = await getSyncQueue();
    for (int i = 0; i < operations.length; i++) {
      if (operations[i]['id'] == operationId) {
        await _syncQueueBox.deleteAt(i);
        Logger.debug('Removed operation from sync queue: $operationId');
        break;
      }
    }
  }

  Future<void> clearSyncQueue() async {
    await _syncQueueBox.clear();
    Logger.info('Cleared sync queue');
  }

  // User Profile
  Future<void> saveUserProfile(User user) async {
    await _userProfileBox.put('current', user.toJson());
    Logger.debug('Saved user profile offline');
  }

  Future<User?> getUserProfile() async {
    final data = _userProfileBox.get('current');
    if (data != null) {
      return User.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  // Cached Data
  Future<void> cacheData(String key, dynamic data) async {
    final dataJson = jsonEncode(data);
    await _cachedDataBox.put(key, dataJson);
    Logger.debug('Cached data: $key');
  }

  Future<T?> getCachedData<T>(String key) async {
    final dataJson = _cachedDataBox.get(key);
    if (dataJson != null) {
      try {
        final data = jsonDecode(dataJson);
        return data as T;
      } catch (e) {
        Logger.error('Failed to parse cached data: $key', error: e);
      }
    }
    return null;
  }

  Future<void> clearCachedData(String key) async {
    await _cachedDataBox.delete(key);
    Logger.debug('Cleared cached data: $key');
  }

  Future<void> clearAllCachedData() async {
    await _cachedDataBox.clear();
    Logger.info('Cleared all cached data');
  }

  // Storage management
  Future<int> getStorageSize() async {
    return _wasteRequestsBox.length + 
           _syncQueueBox.length + 
           _userProfileBox.length + 
           _cachedDataBox.length;
  }

  Future<void> clearAllData() async {
    await _wasteRequestsBox.clear();
    await _syncQueueBox.clear();
    await _userProfileBox.clear();
    await _cachedDataBox.clear();
    Logger.info('Cleared all offline storage data');
  }

  Future<void> close() async {
    await _wasteRequestsBox.close();
    await _syncQueueBox.close();
    await _userProfileBox.close();
    await _cachedDataBox.close();
    Logger.info('Closed offline storage');
  }
}

class SyncOperation {
  final String id;
  final String type; // 'create', 'update', 'delete'
  final String endpoint;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  SyncOperation({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'endpoint': endpoint,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'],
      type: json['type'],
      endpoint: json['endpoint'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retry_count'] ?? 0,
    );
  }

  SyncOperation withRetry() {
    return SyncOperation(
      id: id,
      type: type,
      endpoint: endpoint,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount + 1,
    );
  }
}

final offlineStorageProvider = Provider<OfflineStorage>((ref) {
  return OfflineStorage();
});