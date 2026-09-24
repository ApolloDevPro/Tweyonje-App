import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/geo.dart';
import 'database_factory_stub.dart'
    if (dart.library.io) 'database_factory_io.dart'
    if (dart.library.js_interop) 'database_factory_web.dart';

/// Shared SQLite data layer.
///
/// The whole app (offline storage, local auth, sync queue, cached data) reads
/// and writes through a single [AppDatabase] instance so there is exactly one
/// connection and one schema.
class AppDatabase {
  AppDatabase._();

  /// Singleton: every consumer reads/writes the same local database.
  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'tweyonje.db';
  static const int _schemaVersion = 2;

  /// Geohash precision stored for waste requests, used by the spatial
  /// "near me" query.
  static const int storedGeohashPrecision = GeoUtils.storedPrecision;

  Database? _db;
  Future<Database>? _opening;

  /// The lazily-opened shared SQLite database.
  ///
  /// Opening is performed once and cached. Failures (e.g. no available SQLite
  /// backend) propagate to callers, which are responsible for degrading
  /// gracefully.
  Future<Database> get database {
    final existing = _db;
    if (existing != null) return Future.value(existing);
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    await configureDatabaseFactory();
    final path = join(await databaseFactory.getDatabasesPath(), _databaseName);
    final db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    _db = db;
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        phone TEXT,
        full_name TEXT NOT NULL,
        first_name TEXT,
        last_name TEXT,
        role TEXT NOT NULL,
        preferred_language TEXT,
        phone_verified INTEGER NOT NULL DEFAULT 0,
        email_verified INTEGER NOT NULL DEFAULT 0,
        date_joined TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE auth_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        access TEXT NOT NULL,
        refresh TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE waste_requests (
        id TEXT NOT NULL PRIMARY KEY,
        data TEXT NOT NULL,
        created_at TEXT,
        geohash TEXT,
        lat REAL,
        lon REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_id TEXT,
        data TEXT NOT NULL,
        created_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE user_profile (
        key TEXT NOT NULL PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE cached_data (
        key TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_actions (
        id TEXT NOT NULL PRIMARY KEY,
        data TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    await db
        .execute('CREATE INDEX idx_auth_sessions_user ON auth_sessions (user_id)');
    await db.execute(
        'CREATE INDEX idx_auth_sessions_created ON auth_sessions (created_at)');
    await db.execute(
        'CREATE INDEX idx_sync_queue_created ON sync_queue (created_at)');
    await db.execute(
        'CREATE INDEX idx_pending_actions_created ON pending_actions (created_at)');
    await db.execute(
        'CREATE INDEX idx_waste_requests_geohash ON waste_requests (geohash)');
  }

  /// Migrates older schemas. v2 adds the spatial columns used by the
  /// "near me" waste request query and backfills them from stored JSON.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE waste_requests ADD COLUMN geohash TEXT');
      await db.execute('ALTER TABLE waste_requests ADD COLUMN lat REAL');
      await db.execute('ALTER TABLE waste_requests ADD COLUMN lon REAL');
      await db.execute(
          'CREATE INDEX idx_waste_requests_geohash ON waste_requests (geohash)');

      final rows = await db.query('waste_requests');
      for (final row in rows) {
        try {
          final json =
              jsonDecode(row['data'] as String) as Map<String, dynamic>;
          final rawLat = json['latitude'];
          final rawLon = json['longitude'];
          final lat = rawLat != null ? double.tryParse(rawLat.toString()) : null;
          final lon = rawLon != null ? double.tryParse(rawLon.toString()) : null;
          if (lat == null || lon == null) continue;
          await db.update(
            'waste_requests',
            {
              'lat': lat,
              'lon': lon,
              'geohash': GeoUtils.encode(lat, lon,
                  precision: storedGeohashPrecision),
            },
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        } catch (_) {
          // A single malformed row must not block the migration.
        }
      }
    }
  }

  /// Closes the shared connection. Further access will reopen the database.
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
      _opening = null;
    }
  }
}