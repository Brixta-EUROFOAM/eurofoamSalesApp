import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

typedef SocketMessageHandler = void Function(Map<String, dynamic>);

class SocketClient {
  final String url;
  WebSocketChannel? _channel;

  SocketMessageHandler? onMessage;
  VoidCallback? onDisconnect;
  VoidCallback? onConnect;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  SocketClient(this.url);

  void connect() {
    debugPrint("🔌 [SocketClient] ATTEMPTING CONNECT TO: $url");

    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _channel = channel;

      channel.stream.listen(
        (data) {
          // FIRST MESSAGE = confirmed connection
          if (!_isConnected) {
            _isConnected = true;
            debugPrint("✅ [SocketClient] CONNECTED (stream active)");
            onConnect?.call();
          }

          debugPrint("📩 [SocketClient] RECEIVED DATA: $data");
          try {
            final decoded = jsonDecode(data);
            onMessage?.call(decoded);
          } catch (e) {
            debugPrint("🚨 [SocketClient] JSON Parse Error: $e");
          }
        },
        onError: (error) {
          debugPrint("🚨 [SocketClient] STREAM ERROR: $error");
          _handleDisconnect();
        },
        onDone: () {
          debugPrint("🔌 [SocketClient] CONNECTION CLOSED BY SERVER");
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("🚨 [SocketClient] CRITICAL CONNECTION EXCEPTION: $e");
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (_isConnected) {
      debugPrint("⚠️ [SocketClient] Disconnected cleanup triggered.");
    }
    _isConnected = false;
    onDisconnect?.call();
    _channel = null;
  }

  void send(Map<String, dynamic> msg) {
    if (_isConnected && _channel != null) {
      final jsonMsg = jsonEncode(msg);
      debugPrint("📤 [SocketClient] SENDING: $jsonMsg");
      _channel?.sink.add(jsonMsg);
    } else {
      debugPrint("⚠️ [SocketClient] CANNOT SEND - Disconnected.");
    }
  }

  void close() {
    debugPrint("🛑 [SocketClient] Manual Close called.");
    _channel?.sink.close();
    _handleDisconnect();
  }
}
