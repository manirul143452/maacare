import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants.dart';

class InsForgeRealtimeClient {
  InsForgeRealtimeClient._();
  static final InsForgeRealtimeClient instance = InsForgeRealtimeClient._();

  WebSocketChannel? _channel;
  final Map<String, List<Function(dynamic)>> _listeners = {};
  Timer? _heartbeat;
  bool _isConnecting = false;
  int _reconnectDelay = 1000;

  void connect() {
    if (_channel != null || _isConnecting) return;
    _isConnecting = true;
    
    // Connect to the standard realtime websocket path: /realtime/v1/websocket
    final wsUrl = Uri.parse('${AppConstants.backendUrl.replaceFirst('https', 'wss')}/realtime/v1/websocket?apikey=${AppConstants.backendAnonKey}&v=1.0.0');
    try {
      _channel = WebSocketChannel.connect(wsUrl);
      
      _channel!.ready.catchError((e) {
        debugPrint('Realtime WS Ready Error: $e');
        _handleReconnect();
      });

      // Also catch any errors on the sink to prevent cascading Unhandled Promise Rejections
      _channel!.sink.done.catchError((e) {
        debugPrint('Realtime WS Sink Done Error: $e');
      });

      _channel!.stream.listen(
        (message) {
          _reconnectDelay = 1000; // Reset delay on success
          _isConnecting = false;
          
          final data = jsonDecode(message);
          if (data['event'] == 'phx_reply' || data['event'] == 'heartbeat') return; 
          
          final topic = data['topic'] as String?;
          final payload = data['payload'];

          if (topic != null && _listeners.containsKey(topic)) {
            for (var callback in _listeners[topic]!) {
              callback(payload);
            }
          }
        },
        onError: (e) {
          debugPrint('Realtime WS Error: $e');
          _handleReconnect();
        },
        onDone: () {
          debugPrint('Realtime WS Closed');
          _handleReconnect();
        },
      );
      
      _heartbeat = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_channel != null) {
          _channel!.sink.add(jsonEncode({
            "topic": "phoenix",
            "event": "heartbeat",
            "payload": {},
            "ref": timer.tick.toString()
          }));
        } else {
          timer.cancel();
        }
      });

      // Rejoin active topics
      for (final topic in _listeners.keys) {
         _channel!.sink.add(jsonEncode({
          "topic": topic,
          "event": "phx_join",
          "payload": {},
          "ref": "rejoin_${DateTime.now().millisecondsSinceEpoch}"
        }));
      }
    } catch (e) {
      debugPrint('Realtime Connection Exception: $e');
      _handleReconnect();
    }
  }

  void _handleReconnect() {
    _isConnecting = false;
    _channel?.sink.close();
    _channel = null;
    _heartbeat?.cancel();
    
    Future.delayed(Duration(milliseconds: _reconnectDelay), () {
      if (_listeners.isNotEmpty) {
        _reconnectDelay = (_reconnectDelay * 2).clamp(1000, 30000); 
        connect();
      }
    });
  }

  void subscribe(String channelPattern, Function(dynamic) onData) {
    final topic = 'realtime:$channelPattern';
    
    _listeners.putIfAbsent(topic, () => []);
    
    // Check if channel is already joined
    if (_channel != null && _listeners[topic]!.isEmpty) { 
      _channel!.sink.add(jsonEncode({
        "topic": topic,
        "event": "phx_join",
        "payload": {},
        "ref": "join_${DateTime.now().millisecondsSinceEpoch}"
      }));
    }
    
    _listeners[topic]!.add(onData);
    if (_channel == null && !_isConnecting) connect();
  }

  void unsubscribe(String channelPattern) {
    final topic = 'realtime:$channelPattern';
    if (_listeners.containsKey(topic)) {
      _listeners.remove(topic);
      if (_channel != null) {
        _channel!.sink.add(jsonEncode({
          "topic": topic,
          "event": "phx_leave",
          "payload": {},
          "ref": "leave_${DateTime.now().millisecondsSinceEpoch}"
        }));
      }
    }
  }

  void disconnect() {
    _heartbeat?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
  
  void clearListeners() {
    _listeners.clear();
    disconnect();
  }
}
