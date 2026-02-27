import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  DeviceIdService._();

  static final DeviceIdService instance = DeviceIdService._();

  static const _storage = FlutterSecureStorage();
  static const _key = 'device_id';

  final _uuid = const Uuid();

  Future<String> getDeviceId() async {
    final existingDeviceId = await _storage.read(key: _key);

    if (existingDeviceId != null && existingDeviceId.isNotEmpty) {
      return existingDeviceId;
    }

    final newDeviceId = _uuid.v4();

    await _storage.write(
      key: _key,
      value: newDeviceId,
    );

    return newDeviceId;
  }

  Future<void> clearDeviceId() async {
    await _storage.delete(key: _key);
  }
}