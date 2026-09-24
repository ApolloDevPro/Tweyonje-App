import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../../models/models.dart';
import '../database/app_database.dart';
import '../services/logger.dart';
import '../utils/geo.dart';

/// Offline storage backed by the shared local SQLite database.
///
/// Replaces the previous Hive boxes with tables owned by [AppDatabase]. The
/// public API is unchanged so callers keep working without modification.
class OfflineStorage {
  static const String _wasteRequestsTable = 'waste_requests';
  static const String _syncQueueTable = 'sync_queue';
  static const String _userProfileTable = 'user_profile';
  static const String _cachedDataKeyPrefix = 'cached_data:';
  static const String _userProfileKey = 'current';

  Future<void> init() async {
    // Opening the shared database also (re)creates the schema if needed.
    await AppDatabase.instance.database;
    Logger.info('Offline storage initialized');
  }

  // Waste Requests
  Future<void> saveWasteRequest(WasteRequest request) async {
    final db = await AppDatabase.instance.database;
    final lat = request.latitude;
    final lon = request.longitude;
    await db.insert(
      _wasteRequestsTable,
      {
        'id': request.id,
        'data': jsonEncode(request.toJson()),
        'created_at': request.createdAt ?? DateTime.now().toIso8601String(),
        'geohash': (lat != null && lon != null)
            ? GeoUtils.encode(lat, lon,
                precision: AppDatabase.storedGeohashPrecision)
            : null,
        'lat': lat,
        'lon': lon,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Logger.debug('Saved waste request offline: ${request.id}');
  }

  Future<WasteRequest?> getWasteRequest(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      _wasteRequestsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _decodeWasteRequest(rows.first['data']);
  }

  Future<List<WasteRequest>> getAllWasteRequests() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(_wasteRequestsTable);
    final requests = <WasteRequest>[];
    for (final row in rows) {
      final request = _decodeWasteRequest(row['data']);
      if (request != null) requests.add(request);
    }
    return requests;
  }

  /// Waste requests within [radiusMeters] of the given point, nearest first.
  ///
  /// Spatial filtering uses a geohash prefix scan over the request's cell and
  /// its 8 neighbors; exact filtering/sorting uses the Haversine distance.
  Future<List<WasteRequest>> getWasteRequestsNear({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    int? limit,
  }) async {
    final db = await AppDatabase.instance.database;
    final center = GeoUtils.encode(
      latitude,
      longitude,
      precision: GeoUtils.precisionForRadius(radiusMeters, latitude: latitude),
    );
    final cells = GeoUtils.neighborhood(center);

    final where = List.filled(cells.length, 'geohash LIKE ?').join(' OR ');
    final args = cells.map((cell) => '$cell%').toList();

    final rows = await db.query(
      _wasteRequestsTable,
      where: where,
      whereArgs: args,
    );

    final results = <({double distance, WasteRequest request})>[];
    for (final row in rows) {
      final request = _decodeWasteRequest(row['data']);
      if (request == null ||
          request.latitude == null ||
          request.longitude == null) {
        continue;
      }
      final distance = GeoUtils.distanceMeters(
        latitude,
        longitude,
        request.latitude!,
        request.longitude!,
      );
      if (distance <= radiusMeters) {
        results.add((distance: distance, request: request));
      }
    }

    results.sort((a, b) => a.distance.compareTo(b.distance));
    final requests = results.map((e) => e.request).toList();
    if (limit != null && requests.length > limit) {
      return requests.sublist(0, limit);
    }
    return requests;
  }

  Future<void> deleteWasteRequest(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      _wasteRequestsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    Logger.debug('Deleted waste request: $id');
  }

  // Sync Queue
  Future<void> addToSyncQueue(Map<String, dynamic> operation) async {
    final db = await AppDatabase.instance.database;
    await db.insert(_syncQueueTable, {
      'operation_id': operation['id']?.toString(),
      'data': jsonEncode(operation),
      'created_at': DateTime.now().toIso8601String(),
    });
    Logger.debug('Added operation to sync queue: ${operation['type']}');
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(_syncQueueTable, orderBy: 'created_at ASC');
    final operations = <Map<String, dynamic>>[];
    for (final row in rows) {
      try {
        final operation =
            jsonDecode(row['data'] as String) as Map<String, dynamic>;
        operations.add(operation);
      } catch (e) {
        Logger.error('Failed to parse sync queue operation', error: e);
      }
    }
    return operations;
  }

  Future<void> removeFromSyncQueue(String operationId) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      _syncQueueTable,
      where: 'operation_id = ?',
      whereArgs: [operationId],
    );
    Logger.debug('Removed operation from sync queue: $operationId');
  }

  Future<void> clearSyncQueue() async {
    final db = await AppDatabase.instance.database;
    await db.delete(_syncQueueTable);
    Logger.info('Cleared sync queue');
  }

  // User Profile
  Future<void> saveUserProfile(User user) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      _userProfileTable,
      {
        'key': _userProfileKey,
        'data': jsonEncode(user.toJson()),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Logger.debug('Saved user profile offline');
  }

  Future<User?> getUserProfile() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      _userProfileTable,
      where: 'key = ?',
      whereArgs: [_userProfileKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      return User.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(rows.first['data'] as String) as Map,
        ),
      );
    } catch (e) {
      Logger.error('Failed to parse user profile', error: e);
      return null;
    }
  }

  // Cached Data
  Future<void> cacheData(String key, dynamic data) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'cached_data',
      {
        'key': '$_cachedDataKeyPrefix$key',
        'value': jsonEncode(data),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Logger.debug('Cached data: $key');
  }

  Future<T?> getCachedData<T>(String key) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'cached_data',
      where: 'key = ?',
      whereArgs: ['$_cachedDataKeyPrefix$key'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final data = jsonDecode(rows.first['value'] as String);
      return data as T;
    } catch (e) {
      Logger.error('Failed to parse cached data: $key', error: e);
      return null;
    }
  }

  Future<void> clearCachedData(String key) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'cached_data',
      where: 'key = ?',
      whereArgs: ['$_cachedDataKeyPrefix$key'],
    );
    Logger.debug('Cleared cached data: $key');
  }

  Future<void> clearAllCachedData() async {
    final db = await AppDatabase.instance.database;
    await db.delete('cached_data');
    Logger.info('Cleared all cached data');
  }

  // Storage management
  Future<int> getStorageSize() async {
    final db = await AppDatabase.instance.database;
    final counts = await Future.wait([
      _countRows(db, _wasteRequestsTable),
      _countRows(db, _syncQueueTable),
      _countRows(db, _userProfileTable),
      _countRows(db, 'cached_data'),
    ]);
    return counts.reduce((a, b) => a + b);
  }

  Future<void> clearAllData() async {
    final db = await AppDatabase.instance.database;
    await db.delete(_wasteRequestsTable);
    await db.delete(_syncQueueTable);
    await db.delete(_userProfileTable);
    await db.delete('cached_data');
    Logger.info('Cleared all offline storage data');
  }

  Future<void> close() async {
    await AppDatabase.instance.close();
    Logger.info('Closed offline storage');
  }

  WasteRequest? _decodeWasteRequest(Object? data) {
    if (data == null) return null;
    try {
      return WasteRequest.fromJson(
        Map<String, dynamic>.from(jsonDecode(data as String) as Map),
      );
    } catch (e) {
      Logger.error('Failed to parse waste request', error: e);
      return null;
    }
  }

  Future<int> _countRows(Database db, String table) async {
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM $table');
    return (result.first['count'] as int?) ?? 0;
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