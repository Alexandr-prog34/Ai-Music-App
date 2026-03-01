import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../shared/domain/ws_message.dart';

class WebSocketApi {
  final String url;

  WebSocketChannel? _channel;

  WebSocketApi(this.url);

  Stream<WsMessage> connect() {
    _channel = WebSocketChannel.connect(
      Uri.parse(url),
    );

    return _channel!.stream.map((event) {
      final json = jsonDecode(event);
      return WsMessage.fromJson(json);
    });
  }

  void disconnect() {
    _channel?.sink.close();
  }
}