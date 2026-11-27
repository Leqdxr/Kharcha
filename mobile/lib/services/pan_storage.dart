import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The user's PAN number. It stays on this phone and is never sent to the API.
class PanStorage {
  static const _key = 'pan';
  static const _storage = FlutterSecureStorage();

  static Future<String?> get() => _storage.read(key: _key);

  static Future<void> save(String pan) => _storage.write(key: _key, value: pan);

  static Future<void> clear() => _storage.delete(key: _key);
}
