import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm_session.dart';
import 'alarm_session_repository.dart';

class SharedPreferencesAlarmSessionRepository
    implements AlarmSessionRepository {
  SharedPreferencesAlarmSessionRepository(this._preferences);

  static const String _sessionKey = 'alarm_session';

  final SharedPreferences _preferences;

  @override
  Future<AlarmSession> load() async {
    final String? raw = _preferences.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return AlarmSession.initial();
    }

    final Map<String, dynamic> json =
        (jsonDecode(raw) as Map<dynamic, dynamic>).cast<String, dynamic>();
    return AlarmSession.fromJson(json);
  }

  @override
  Future<void> save(AlarmSession session) async {
    await _preferences.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_sessionKey);
  }
}
