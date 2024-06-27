import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'web_storage.dart';

class StorageCustom {
  static final _secureStorage = FlutterSecureStorage();
  static final _webStorage = WebStorage();

  static Future<void> write(String key, String value) async {
    if (kIsWeb) {
      _webStorage.write(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  static Future<String?> read(String key) async {
    if (kIsWeb) {
      return _webStorage.read(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  static Future<void> delete(String key) async {
    if (kIsWeb) {
      _webStorage.delete(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }
}
