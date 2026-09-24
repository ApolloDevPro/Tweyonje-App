import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Configures the SQLite factory for the web, where the native sqflite plugin
/// is unavailable and the database lives in a WebAssembly SQLite instance
/// backed by IndexedDB.
///
/// The "no web worker" variant runs SQLite in the main thread so it only
/// needs `sqlite3.wasm` served from the app root (see `web/sqlite3.wasm`).
Future<void> configureDatabaseFactory() async {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}