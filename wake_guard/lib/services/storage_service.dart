import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DisarmMethod { qr, nfc }

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  late SharedPreferences _prefs;

  static const String _qrKey = 'wake_guard_qr_code';
  static const String _nfcKey = 'wake_guard_nfc_identifier';
  static const String _timeKey = 'wake_guard_alarm_time';
  static const String _repeatKey = 'wake_guard_alarm_repeat';
  static const String _methodKey = 'wake_guard_alarm_method';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveQrCode(String value) async {
    await _prefs.setString(_qrKey, value);
  }

  String? getQrCode() => _prefs.getString(_qrKey);

  Future<void> saveNfcIdentifier(String value) async {
    await _prefs.setString(_nfcKey, value);
  }

  String? getNfcIdentifier() => _prefs.getString(_nfcKey);

  Future<void> saveAlarmTime(TimeOfDay time) async {
    final String encoded = '${time.hour}:${time.minute}';
    await _prefs.setString(_timeKey, encoded);
  }

  TimeOfDay? getAlarmTime() {
    final String? encoded = _prefs.getString(_timeKey);
    if (encoded == null) {
      return null;
    }
    final List<String> parts = encoded.split(':');
    if (parts.length != 2) {
      return null;
    }
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> saveRepeat(bool value) async {
    await _prefs.setBool(_repeatKey, value);
  }

  bool getRepeat() => _prefs.getBool(_repeatKey) ?? false;

  Future<void> saveMethod(DisarmMethod method) async {
    await _prefs.setString(_methodKey, method.name);
  }

  DisarmMethod getMethod() {
    final String? value = _prefs.getString(_methodKey);
    return DisarmMethod.values.firstWhere(
      (DisarmMethod method) => method.name == value,
      orElse: () => DisarmMethod.qr,
    );
  }
}
