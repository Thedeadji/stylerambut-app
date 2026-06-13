import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  SettingsStore._();

  static final SettingsStore instance = SettingsStore._();

  static const _beepKey = 'settings_beep_enabled';
  static const _vibrationKey = 'settings_vibration_enabled';
  static const _jedaHistoryKey = 'settings_jeda_history_enabled';

  bool beepEnabled = false;
  bool vibrationEnabled = true;
  bool jedaHistoryEnabled = false;

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    beepEnabled = prefs.getBool(_beepKey) ?? false;
    vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
    jedaHistoryEnabled = prefs.getBool(_jedaHistoryKey) ?? false;
    _loaded = true;
  }

  Future<void> setBeepEnabled(bool value) async {
    beepEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_beepKey, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, value);
  }

  Future<void> setJedaHistoryEnabled(bool value) async {
    jedaHistoryEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_jedaHistoryKey, value);
  }
}
