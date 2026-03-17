import '../models/alarm_settings.dart';

abstract class SettingsRepository {
  Future<AlarmSettings> load();

  Future<void> save(AlarmSettings settings);
}
