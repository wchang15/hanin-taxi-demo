import 'package:flutter_secure_storage/flutter_secure_storage.dart';

AndroidOptions _getAndroidOptions() => const AndroidOptions();

class StorageService {
  static final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());

  static Future<void> writeSecureData(String key, String val) async {
    await storage.write(key: key, value: val);
  }

  static Future<String?> readSecureData(String key) async {
    var readData = await storage.read(key: key);
    return readData;
  }

  static Future<void> deleteSecureData(String key) async {
    await storage.delete(key: key);
  }

  static Future<bool> containsKeyInSecureData(String key) async {
    var containsKey = await storage.containsKey(key: key);
    return containsKey;
  }

  static Future<void> deleteAllSecureData() async {
    await storage.deleteAll();
  }
}
