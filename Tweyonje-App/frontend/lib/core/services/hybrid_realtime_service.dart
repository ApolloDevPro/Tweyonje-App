import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger.dart';

/// Hybrid real-time service
/// - Uses Supabase Realtime for live updates
/// - Falls back to WebSocket if needed
class HybridRealtimeService {
  final SupabaseClient _supabase;
  final Map<String, RealtimeChannel> _subscriptions = {};
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};

  HybridRealtimeService(this._supabase);

  /// Subscribe to table changes via Supabase Realtime
  Stream<Map<String, dynamic>> subscribeToTable(String table) {
    if (_controllers.containsKey(table)) {
      return _controllers[table]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[table] = controller;

    try {
      Logger.info('Subscribing to Supabase Realtime: $table');

      final channel = _supabase
          .channel('public:$table')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (payload) {
              final data = {
                'event': payload.eventType.toString().split('.').last,
                'table': table,
                'new': payload.newRecord,
                'old': payload.oldRecord,
                'timestamp': DateTime.now().toIso8601String(),
              };

              Logger.logRealtimeEvent(table, data);
              controller.add(data);
            },
          )
          .subscribe();

      _subscriptions[table] = channel;
      Logger.info('Subscribed to Supabase Realtime: $table');
    } catch (e) {
      Logger.error('Failed to subscribe to Supabase Realtime', error: e);
    }

    return controller.stream;
  }

  /// Subscribe to specific row changes
  Stream<Map<String, dynamic>> subscribeToRow(
    String table,
    String rowId,
  ) {
    final key = '$table:$rowId';
    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[key] = controller;

    try {
      Logger.info('Subscribing to Supabase Realtime row: $table:$rowId');

      final channel = _supabase
          .channel('row:$table:$rowId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: rowId,
            ),
            callback: (payload) {
              final data = {
                'event': payload.eventType.toString().split('.').last,
                'table': table,
                'row_id': rowId,
                'new': payload.newRecord,
                'old': payload.oldRecord,
                'timestamp': DateTime.now().toIso8601String(),
              };

              Logger.logRealtimeEvent(table, data);
              controller.add(data);
            },
          )
          .subscribe();

      _subscriptions[key] = channel;
      Logger.info('Subscribed to Supabase Realtime row: $table:$rowId');
    } catch (e) {
      Logger.error('Failed to subscribe to Supabase Realtime row', error: e);
    }

    return controller.stream;
  }

  /// Subscribe to presence (who's online)
  Stream<Map<String, dynamic>> subscribeToPresence(String channelName) {
    final key = 'presence:$channelName';
    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[key] = controller;

    try {
      Logger.info('Subscribing to Supabase Presence: $channelName');

      final channel = _supabase.channel(channelName);

      channel
          .onPresenceSync((payload) {
            controller.add({
              'event': 'sync',
              'channel': channelName,
              'state': payload.presences,
              'timestamp': DateTime.now().toIso8601String(),
            });
          })
          .onPresenceJoin((payload) {
            controller.add({
              'event': 'join',
              'channel': channelName,
              'newPresences': payload.newPresences,
              'timestamp': DateTime.now().toIso8601String(),
            });
          })
          .onPresenceLeave((payload) {
            controller.add({
              'event': 'leave',
              'channel': channelName,
              'leftPresences': payload.leftPresences,
              'timestamp': DateTime.now().toIso8601String(),
            });
          })
          .subscribe();

      _subscriptions[key] = channel;
      Logger.info('Subscribed to Supabase Presence: $channelName');
    } catch (e) {
      Logger.error('Failed to subscribe to Supabase Presence', error: e);
    }

    return controller.stream;
  }

  /// Track user presence
  Future<void> trackPresence(String channelName, Map<String, dynamic> state) async {
    try {
      final channel = _subscriptions['presence:$channelName'];
      if (channel != null) {
        await channel.track(state);
        Logger.info('Presence tracked: $channelName');
      }
    } catch (e) {
      Logger.error('Failed to track presence', error: e);
    }
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(String key) async {
    try {
      final channel = _subscriptions.remove(key);
      if (channel != null) {
        await _supabase.removeChannel(channel);
        Logger.info('Unsubscribed from: $key');
      }

      final controller = _controllers.remove(key);
      if (controller != null) {
        await controller.close();
      }
    } catch (e) {
      Logger.error('Failed to unsubscribe', error: e);
    }
  }

  /// Unsubscribe from all channels
  Future<void> unsubscribeAll() async {
    for (final key in _subscriptions.keys.toList()) {
      await unsubscribe(key);
    }
  }

  /// Get subscription status
  Map<String, bool> getSubscriptionStatus() {
    return _subscriptions.map((key, channel) => MapEntry(
          key,
          channel.topic.isNotEmpty,
        ));
  }

  /// Dispose all subscriptions
  void dispose() {
    unsubscribeAll();
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}

final hybridRealtimeServiceProvider = Provider<HybridRealtimeService>((ref) {
  final supabase = Supabase.instance.client;
  return HybridRealtimeService(supabase);
});
