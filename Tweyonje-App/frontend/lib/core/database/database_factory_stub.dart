/// Fallback factory configuration. This stub is only used when running on a
/// platform that is neither a Dart VM with `dart:io` nor the web.
Future<void> configureDatabaseFactory() async {
  // No SQLite backend available. Callers are expected to handle failures.
}