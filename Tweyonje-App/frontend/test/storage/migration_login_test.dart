import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:tweyonje/core/database/app_database.dart';
import 'package:tweyonje/core/services/biometric_service.dart';
import 'package:tweyonje/core/services/local_auth_service.dart';
import 'package:tweyonje/core/services/password_hasher.dart';
import 'package:tweyonje/core/storage/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  test('v1 DB with a legacy SHA-256 user upgrades and logs in', () async {
    final path = p.join(await databaseFactory.getDatabasesPath(), 'tweyonje.db');
    if (await File(path).exists()) {
      await File(path).delete();
    }

    // Simulate the pre-PBKDF2 (schema v1) database.
    final v1 = await databaseFactory.openDatabase(path, options: OpenDatabaseOptions(version: 1));
    await v1.execute('''
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
    await v1.execute('''
      CREATE TABLE auth_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        access TEXT NOT NULL,
        refresh TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await v1.execute('''
      CREATE TABLE waste_requests (
        id TEXT NOT NULL PRIMARY KEY,
        data TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    const salt = '11223344556677889900aabbccddeeff';
    const email = 'legacy@test.com';
    const password = 'old-password';
    final legacyHash = sha256.convert(utf8.encode('$salt.$password')).toString();

    await v1.insert('users', {
      'email': email,
      'password_hash': '$salt:$legacyHash',
      'full_name': 'Legacy User',
      'first_name': 'Legacy',
      'last_name': 'User',
      'role': 'RESIDENT',
      'created_at': DateTime.now().toIso8601String(),
    });
    await v1.close();

    // Opening AppDatabase triggers schema v2 (adds spatial columns) and the
    // legacy user row is still intact.
    await AppDatabase.instance.database;

    final db = await AppDatabase.instance.database;
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email]);
    expect(rows, hasLength(1));
    expect(rows.first['password_hash'], '$salt:$legacyHash');

    // Login with the legacy password succeeds end-to-end and transparently
    // upgrades the stored hash to PBKDF2.
    final service = LocalAuthService(
      StorageService(),
      BiometricService(),
      passwordHasher: PasswordHasher(iterations: 1000),
    );
    final session = await service.login(email: email, password: password);
    expect(session.user.email, email);
    expect(await service.isAuthenticatedAsync(), isTrue);

    final upgraded = await db.query('users', where: 'email = ?', whereArgs: [email]);
    expect(
      upgraded.first['password_hash'] as String,
      startsWith('pbkdf2\$'),
    );
  });
}