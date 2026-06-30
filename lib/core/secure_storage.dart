import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  
  static const String _keyPhone = 'user_phone';
  static const String _keyPin = 'user_pin';
  static const String _keyBiometrics = 'use_biometrics';

  // Phone number methods
  static Future<void> savePhone(String phone) async {
    await _storage.write(key: _keyPhone, value: phone);
  }

  static Future<String?> getPhone() async {
    return await _storage.read(key: _keyPhone);
  }

  static Future<void> deletePhone() async {
    await _storage.delete(key: _keyPhone);
  }

  // PIN methods
  static Future<void> savePin(String pin) async {
    await _storage.write(key: _keyPin, value: pin);
  }

  static Future<String?> getPin() async {
    return await _storage.read(key: _keyPin);
  }

  static Future<void> deletePin() async {
    await _storage.delete(key: _keyPin);
  }

  // Biometrics methods
  static Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometrics, value: enabled ? 'true' : 'false');
  }

  static Future<bool> isBiometricsEnabled() async {
    final val = await _storage.read(key: _keyBiometrics);
    return val == 'true';
  }

  // Clear all
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
