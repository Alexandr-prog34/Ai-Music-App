enum WsClientType {
  ping('ping');

  final String value;

  const WsClientType(this.value);

  factory WsClientType.fromJson(String value) {
    return WsClientType.values.firstWhere(
      (e) {
        return e.value == value;
      },
    );
  }

  String toJson() {
    return value;
  }
}

class WsClientMessage {
  final WsClientType type;

  WsClientMessage({
    required this.type,
  });

  factory WsClientMessage.fromJson(Map<String, dynamic> json) {
    return WsClientMessage(
      type: WsClientType.fromJson(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toJson(),
    };
  }
}