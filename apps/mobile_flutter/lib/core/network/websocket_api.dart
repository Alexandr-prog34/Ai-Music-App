import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../shared/domain/ws_client_message.dart';
import '../../shared/domain/ws_message.dart';

class WebSocketApi {

  final String url;

  WebSocketChannel? _channel;

  StreamController<WsMessage>? _controller;

  Timer? _pingTimer;

  WebSocketApi(this.url);

  Stream<WsMessage> connect() {

    _controller ??= StreamController.broadcast();

    _connectInternal();

    return _controller!.stream;
  }

  void _connectInternal() {

    _channel = WebSocketChannel.connect(
      Uri.parse(url),
    );

    _startPing();

    _channel!.stream.listen(

      (event) {

        final json = jsonDecode(event);

        final message = WsMessage.fromJson(json);

        _controller?.add(message);

      },

      onDone: _reconnect,

      onError: (_) => _reconnect(),

    );
  }

  void _reconnect() {

    Future.delayed(
      const Duration(seconds: 2),
      () {

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

    _channel?.sink.add(

      jsonEncode(

        WsClientMessage(
          type: WsClientType.ping,
        ).toJson(),

      ),

    );
  }

  void disconnect() {

    _pingTimer?.cancel();

    _channel?.sink.close();

    _channel = null;
  }
}