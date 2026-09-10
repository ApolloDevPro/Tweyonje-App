import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../storage/storage_service.dart';
import '../constants/app_constants.dart';
import 'logger.dart';

enum WebSocketStatus {
  connecting,
  connected,
  disconnected,
  error,
}

enum SubscriptionType {
  collection,
  assignment,
  payment,
  support,
  recycling,
  zone,
}

class WebSocketMessage {
  final String type;
  final Map<String, dynamic>? data;

  WebSocketMessage({required this.type, this.data});

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] ?? '',
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (data != null) 'data': data,
    };
  }
}

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<WebSocketMessage> _messageController = StreamController.broadcast();
  final StreamController<WebSocketStatus> _statusController = StreamController.broadcast();
  
  final StorageService _storageService;
  WebSocketStatus _status = WebSocketStatus.disconnected;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  WebSocketService(this._storageService);

  Stream<WebSocketMessage> get messageStream => _messageController.stream;
  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  WebSocketStatus get status => _status;

  Future<void> connect() async {
    if (_status == WebSocketStatus.connecting || _status == WebSocketStatus.connected) {
      Logger.info('WebSocket already connected or connecting');
      return;
    }

    _updateStatus(WebSocketStatus.connecting);
    Logger.info('Connecting to WebSocket...');

    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        Logger.warning('No access token available for WebSocket connection');
        _updateStatus(WebSocketStatus.error);
        return;
      }

      final wsUrl = Uri.parse('${ApiConstants.wsBaseUrl}?token=$token');
      _channel = WebSocketChannel.connect(wsUrl);

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      _updateStatus(WebSocketStatus.connected);
      _reconnectAttempts = 0;
      Logger.info('WebSocket connected successfully');
    } catch (e) {
      Logger.error('WebSocket connection failed', error: e);
      _updateStatus(WebSocketStatus.error);
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      Logger.debug('WebSocket message received: $message');
      final data = message is String ? message : message.toString();
      
      if (data.startsWith('{')) {
        final jsonData = jsonDecode(data) as Map<String, dynamic>;
        final jsonMessage = WebSocketMessage.fromJson(jsonData);
        _messageController.add(jsonMessage);
      } else {
        // Handle non-JSON messages
        final jsonMessage = WebSocketMessage(
          type: 'raw',
          data: {'message': data},
        );
        _messageController.add(jsonMessage);
      }
    } catch (e) {
      Logger.error('Failed to parse WebSocket message', error: e);
    }
  }

  void _handleError(dynamic error) {
    Logger.error('WebSocket error', error: error);
    _updateStatus(WebSocketStatus.error);
    _scheduleReconnect();
  }

  void _handleDone() {
    Logger.info('WebSocket connection closed');
    _updateStatus(WebSocketStatus.disconnected);
    _scheduleReconnect();
  }

  void _updateStatus(WebSocketStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
    Logger.info('WebSocket status: ${newStatus.name}');
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      Logger.error('Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      Logger.info('Reconnection attempt $_reconnectAttempts/$_maxReconnectAttempts');
      connect();
    });
  }

  void subscribe(SubscriptionType type, String id) {
    if (_status != WebSocketStatus.connected) {
      Logger.warning('Cannot subscribe: WebSocket not connected');
      return;
    }

    final message = WebSocketMessage(
      type: 'subscribe',
      data: {
        'type': type.name,
        'id': id,
      },
    );

    _send(message);
    Logger.info('Subscribed to ${type.name} with id: $id');
  }

  void unsubscribe(SubscriptionType type, String id) {
    if (_status != WebSocketStatus.connected) {
      Logger.warning('Cannot unsubscribe: WebSocket not connected');
      return;
    }

    final message = WebSocketMessage(
      type: 'unsubscribe',
      data: {
        'type': type.name,
        'id': id,
      },
    );

    _send(message);
    Logger.info('Unsubscribed from ${type.name} with id: $id');
  }

  void _send(WebSocketMessage message) {
    try {
      final jsonMessage = jsonEncode(message.toJson());
      _channel?.sink.add(jsonMessage);
      Logger.debug('WebSocket message sent: ${message.type}');
    } catch (e) {
      Logger.error('Failed to send WebSocket message', error: e);
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _updateStatus(WebSocketStatus.disconnected);
    Logger.info('WebSocket disconnected');
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}

// Provider for WebSocket Service
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return WebSocketService(storageService);
});