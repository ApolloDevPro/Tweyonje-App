import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SchemaVerifier {
  static final SupabaseClient _client = Supabase.instance.client;

  /// List of all expected tables
  static const List<String> expectedTables = [
    'zones',
    'profiles',
    'waste_categories',
    'waste_requests',
    'waste_request_photos',
    'recurring_schedules',
    'collection_shifts',
    'collection_assignments',
    'live_locations',
    'payments',
    'invoices',
    'reward_wallets',
    'reward_tiers',
    'reward_redemptions',
    'rating_reviews',
    'notifications',
    'notification_preferences',
    'chat_conversations',
    'chat_messages',
    'support_tickets',
    'ticket_messages',
    'illegal_dumping_reports',
    'report_photos',
    'recycling_offers',
    'recycling_transactions',
    'collection_routes',
    'admin_settings',
    'audit_logs',
    'fcm_devices',
  ];

  /// Verify all tables exist and are accessible
  static Future<Map<String, dynamic>> verifyAllTables() async {
    final results = <String, dynamic>{
      'total_tables': expectedTables.length,
      'existing_tables': <String>[],
      'missing_tables': <String>[],
      'accessible_tables': <String>[],
      'inaccessible_tables': <String, String>{},
    };

    for (final table in expectedTables) {
      try {
        // Try to query the table (limit 0 to just check structure)
        await _client.from(table).select('*').limit(1);
        results['existing_tables'].add(table);
        results['accessible_tables'].add(table);
      } catch (e) {
        final errorMsg = e.toString();
        if (errorMsg.contains('does not exist') || errorMsg.contains('relation') || errorMsg.contains('42P01')) {
          results['missing_tables'].add(table);
        } else {
          results['accessible_tables'].add(table);
          results['inaccessible_tables'][table] = errorMsg;
        }
      }
    }

    results['all_tables_exist'] = (results['missing_tables'] as List).isEmpty;
    results['all_tables_accessible'] = (results['inaccessible_tables'] as Map).isEmpty;

    return results;
  }

  /// Verify a specific table
  static Future<Map<String, dynamic>> verifyTable(String tableName) async {
    try {
      final response = await _client.from(tableName).select('*').limit(5);
      return {
        'exists': true,
        'accessible': true,
        'sample_data': response,
        'row_count_sample': response.length,
      };
    } catch (e) {
      final errorMsg = e.toString();
      final exists = !errorMsg.contains('does not exist') && !errorMsg.contains('42P01');
      return {
        'exists': exists,
        'accessible': false,
        'error': errorMsg,
      };
    }
  }

  /// Verify table has expected columns (by trying to select specific columns)
  static Future<Map<String, dynamic>> verifyTableColumns(
    String tableName,
    List<String> expectedColumns,
  ) async {
    try {
      final response = await _client
          .from(tableName)
          .select(expectedColumns.join(','))
          .limit(1);
      return {
        'table': tableName,
        'columns_verified': true,
        'found_columns': response.isNotEmpty ? response.first.keys.toList() : [],
        'missing_columns': <String>[],
      };
    } catch (e) {
      return {
        'table': tableName,
        'columns_verified': false,
        'error': e.toString(),
      };
    }
  }

  /// Verify seed data exists
  static Future<Map<String, dynamic>> verifySeedData() async {
    final results = <String, dynamic>{};

    try {
      // Check zones
      final zones = await _client.from('zones').select('id');
      results['zones_count'] = zones.length;

      // Check waste categories
      final categories = await _client.from('waste_categories').select('id');
      results['categories_count'] = categories.length;

      // Check reward tiers
      final tiers = await _client.from('reward_tiers').select('id');
      results['tiers_count'] = tiers.length;

      // Check admin settings
      final settings = await _client.from('admin_settings').select('id');
      results['settings_count'] = settings.length;

      results['seed_data_complete'] =
          zones.length >= 7 &&
          categories.length >= 10 &&
          tiers.length >= 4 &&
          settings.length >= 5;

    } catch (e) {
      results['error'] = e.toString();
      results['seed_data_complete'] = false;
    }

    return results;
  }

  /// Generate verification report
  static Future<String> generateReport() async {
    final buffer = StringBuffer();
    buffer.writeln('=== SUPABASE SCHEMA VERIFICATION REPORT ===');
    buffer.writeln('Date: ${DateTime.now()}');
    buffer.writeln('');

    // Verify tables
    buffer.writeln('--- TABLE VERIFICATION ---');
    final tableResults = await verifyAllTables();
    buffer.writeln('Total expected tables: ${tableResults['total_tables']}');
    buffer.writeln('Tables found: ${(tableResults['existing_tables'] as List).length}');
    buffer.writeln('Tables missing: ${(tableResults['missing_tables'] as List).length}');

    if ((tableResults['missing_tables'] as List).isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('MISSING TABLES:');
      for (final table in tableResults['missing_tables']) {
        buffer.writeln('  - $table');
      }
    }

    if ((tableResults['inaccessible_tables'] as Map).isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('INACCESSIBLE TABLES (RLS might be blocking):');
      (tableResults['inaccessible_tables'] as Map).forEach((table, error) {
        buffer.writeln('  - $table: $error');
      });
    }

    buffer.writeln('');

    // Verify seed data
    buffer.writeln('--- SEED DATA VERIFICATION ---');
    final seedResults = await verifySeedData();
    buffer.writeln('Zones: ${seedResults['zones_count'] ?? 0}');
    buffer.writeln('Waste Categories: ${seedResults['categories_count'] ?? 0}');
    buffer.writeln('Reward Tiers: ${seedResults['tiers_count'] ?? 0}');
    buffer.writeln('Admin Settings: ${seedResults['settings_count'] ?? 0}');
    buffer.writeln('Seed data complete: ${seedResults['seed_data_complete']}');

    buffer.writeln('');
    buffer.writeln('=== END REPORT ===');

    return buffer.toString();
  }
}
