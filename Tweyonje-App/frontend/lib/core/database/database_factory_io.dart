import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Configures the SQLite factory for desktop platforms.
///
/// The native `sqflite` plugin only ships for Android/iOS/macOS. On Windows
/// and Linux the app falls back to the FFI-backed implementation, which is
/// bundled with the native `sqlite3` library via `sqlite3_flutter_libs`.
Future<void> configureDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}