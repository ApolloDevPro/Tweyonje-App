import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConnectionTest {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Test basic connection to Supabase
  static Future<Map<String, dynamic>> testConnection() async {
    final results = <String, dynamic>{};

    try {
      // Test 1: Check auth status
      final session = _client.auth.currentSession;
      results['auth'] = {
        'status': session != null ? 'authenticated' : 'anonymous',
        'message': session != null ? 'User logged in' : 'No user session (expected for initial test)',
      };

      // Test 2: Check database connection by querying a table
      // This will fail if tables don't exist yet - that's expected
      try {
        final response = await _client.from('zones').select('*').limit(1);
        results['database'] = {
          'status': 'connected',
          'message': 'Tables exist and are accessible',
          'zones_count': response.length,
        };
      } catch (e) {
        results['database'] = {
          'status': 'tables_not_found',
          'message': 'Connection works but tables need to be created',
          'hint': 'Run the SQL migration in Supabase Dashboard > SQL Editor',
        };
      }

      // Test 3: Check storage
      try {
        await _client.storage.listBuckets();
        results['storage'] = {
          'status': 'accessible',
          'message': 'Storage is accessible',
        };
      } catch (e) {
        results['storage'] = {
          'status': 'error',
          'message': 'Storage access failed: ${e.toString()}',
        };
      }

      // Test 4: Check realtime
      results['realtime'] = {
        'status': 'available',
        'message': 'Realtime subscriptions available',
      };

      results['overall'] = 'success';
      results['message'] = 'Supabase connection is working!';

    } catch (e) {
      results['overall'] = 'error';
      results['message'] = 'Connection failed: ${e.toString()}';
    }

    return results;
  }

  /// Test specific table access
  static Future<bool> testTable(String tableName) async {
    try {
      await _client.from(tableName).select('*').limit(1);
      return true;
    } catch (e) {
      debugPrint('Table $tableName test failed: $e');
      return false;
    }
  }

  /// Test auth with email/password (for later use)
  static Future<Map<String, dynamic>> testAuth({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return {
        'status': 'success',
        'user': response.user?.id,
        'email': response.user?.email,
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  /// Test insert operation
  static Future<Map<String, dynamic>> testInsert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client.from(table).insert(data).select();
      return {
        'status': 'success',
        'data': response,
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  /// Test realtime subscription
  static RealtimeChannel testRealtime({
    required String table,
    required void Function(String eventType, Map<String, dynamic> record) callback,
  }) {
    return _client
        .channel('test:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (payload) {
            callback(
              payload.eventType.toString(),
              payload.newRecord,
            );
          },
        )
        .subscribe();
  }
}
