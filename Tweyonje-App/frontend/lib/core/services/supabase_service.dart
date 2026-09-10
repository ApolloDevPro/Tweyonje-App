import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  late final SupabaseClient _client;

  SupabaseService._() {
    _client = Supabase.instance.client;
  }

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseClient get client => _client;

  // Auth helpers
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  // Sign in with email/password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email/password
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Database query helpers
  Future<List<Map<String, dynamic>>> select(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  }) async {
    var query = _client.from(table).select(select ?? '*');

    if (filters != null) {
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    if (offset != null) {
      query = query.range(offset, offset + (limit ?? 10) - 1);
    }

    return await query;
  }

  // Insert data
  Future<List<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    return await _client.from(table).insert(data).select();
  }

  // Update data
  Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    Map<String, dynamic>? filters,
  }) async {
    var query = _client.from(table).update(data);

    if (filters != null) {
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
    }

    return await query.select();
  }

  // Delete data
  Future<void> delete(
    String table, {
    Map<String, dynamic>? filters,
  }) async {
    var query = _client.from(table).delete();

    if (filters != null) {
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
    }

    await query;
  }

  // Real-time subscription
  RealtimeChannel subscribeToTable(
    String table,
    void Function(PostgresChangeEvent eventType, Map<String, dynamic> newRecord, Map<String, dynamic>? oldRecord) callback,
  ) {
    return _client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (payload) {
            callback(
              payload.eventType,
              payload.newRecord,
              payload.oldRecord,
            );
          },
        )
        .subscribe();
  }
}
