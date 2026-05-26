import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';

import '../../shared/domain/ws_client_message.dart';
import '../../shared/domain/ws_message.dart';

class WebSocketApi {

  final String url;

  IOWebSocketChannel? _channel;

  StreamController<WsMessage>? _controller;

  Timer? _pingTimer;

  bool _isConnecting = false;

  bool _disposed = false;

  WebSocketApi(String rawUrl)
      : url = rawUrl
            .replaceFirst('http://', 'ws://')
            .replaceFirst('https://', 'wss://');

  Stream<WsMessage> connect() {

    _controller ??=
        StreamController<WsMessage>.broadcast();

    _connectInternal();

    return _controller!.stream;
  }

  void _connectInternal() {

    if (_isConnecting || _disposed) {
      return;
    }

    _isConnecting = true;

    try {

      _channel = IOWebSocketChannel.connect(
        Uri.parse(url),
      );

      _startPing();

      _channel!.stream.listen(

        (event) {

          final json = jsonDecode(event);

          final message =
              WsMessage.fromJson(json);

          _controller?.add(message);
        },

        onDone: () {

          _isConnecting = false;

          _reconnect();
        },

        onError: (_) {

          _isConnecting = false;

          _reconnect();
        },
      );

      _isConnecting = false;

    } catch (_) {

      _isConnecting = false;

      _reconnect();
    }
  }

  void _reconnect() {

    if (_disposed) {
      return;
    }

    Future.delayed(

      const Duration(seconds: 2),

      () {

        if (_disposed) {
          return;
        }

        _connectInternal();

      },
    );
  }

  void _startPing() {

    _pingTimer?.cancel();

    _pingTimer = Timer.periodic(

      const Duration(seconds: 20),

      (_) {

        ping();

      },
    );
  }

  void ping() {

    if (_disposed) {
      return;
    }

    _channel?.sink.add(

      jsonEncode(

        WsClientMessage(
          type: WsClientType.ping,
        ).toJson(),

      ),
    );
  }

  void disconnect() {

    _disposed = true;

    _pingTimer?.cancel();

    _channel?.sink.close();

    _channel = null;

    _controller?.close();

    _controller = null;
  }
}