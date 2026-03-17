import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm_settings.dart';
import 'settings_repository.dart';

class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._preferences);

  static const String _settingsKey = 'alarm_settings';

  final SharedPreferences _preferences;

  @override
  Future<AlarmSettings> load() async {
    final String? raw = _preferences.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return AlarmSettings.defaults();
    }

    final Map<String, dynamic> json =
        (jsonDecode(raw) as Map<dynamic, dynamic>).cast<String, dynamic>();
    return AlarmSettings.fromJson(json);
  }

  @override
  Future<void> save(AlarmSettings settings) async {
    await _preferences.setString(_settingsKey, jsonEncode(settings.toJson()));
  }
}
