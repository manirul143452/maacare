import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants.dart';

class InsForgeRealtimeClient {
  InsForgeRealtimeClient._();
  static final InsForgeRealtimeClient instance = InsForgeRealtimeClient._();

  WebSocketChannel? _channel;
  final Map<String, List<Function(dynamic)>> _listeners = {};
  Timer? _heartbeat;

  void connect() {
    if (_channel != null) return;
    
    final wsUrl = Uri.parse('${AppConstants.insForgeUrl.replaceFirst('https', 'wss')}/realtime/v1/websocket?apikey=${AppConstants.insForgeAnonKey}&v=1.0.0');
    _channel = WebSocketChannel.connect(wsUrl);
    
    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['event'] == 'phx_reply' || data['event'] == 'heartbeat') return; 
      
      final topic = data['topic'] as String?;
      final payload = data['payload'];

      if (topic != null && _listeners.containsKey(topic)) {
        for (var callback in _listeners[topic]!) {
          callback(payload);
        }
      }
    });
    
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
  }

  void subscribe(String channelPattern, Function(dynamic) onData) {
    if (_channel == null) connect();
    final topic = 'realtime:$channelPattern';

    if (!_listeners.containsKey(topic)) {
      _listeners[topic] = [];
      _channel!.sink.add(jsonEncode({
        "topic": topic,
        "event": "phx_join",
        "payload": {},
        "ref": "join_${DateTime.now().millisecondsSinceEpoch}"
      }));
    }
    
    _listeners[topic]!.add(onData);
  }

  void disconnect() {
    _heartbeat?.cancel();
    _channel?.sink.close();
    _channel = null;
    _listeners.clear();
  }
}
