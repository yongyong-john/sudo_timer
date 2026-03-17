import 'package:sugo_alarm/src/data/alarm_session_repository.dart';
import 'package:sugo_alarm/src/data/settings_repository.dart';
import 'package:sugo_alarm/src/models/alarm_session.dart';
import 'package:sugo_alarm/src/models/alarm_settings.dart';
import 'package:sugo_alarm/src/models/scheduled_alarm.dart';
import 'package:sugo_alarm/src/platform/alarm_presentation_feedback.dart';
import 'package:sugo_alarm/src/platform/alarm_scheduler.dart';

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository(this.value);

  AlarmSettings value;

  @override
  Future<AlarmSettings> load() async => value;

  @override
  Future<void> save(AlarmSettings settings) async {
    value = settings;
  }
}

class InMemoryAlarmSessionRepository implements AlarmSessionRepository {
  InMemoryAlarmSessionRepository(this.value);

  AlarmSession value;

  @override
  Future<void> clear() async {
    value = AlarmSession.initial();
  }

  @override
  Future<AlarmSession> load() async => value;

  @override
  Future<void> save(AlarmSession session) async {
    value = session;
  }
}

class FakeAlarmScheduler implements AlarmScheduler {
  FakeAlarmScheduler({
    AlarmSchedulerCapabilities? capabilities,
  }) : _capabilities = capabilities ?? AlarmSchedulerCapabilities.unknown();

  final AlarmSchedulerCapabilities _capabilities;
  List<ScheduledAlarm> scheduled = <ScheduledAlarm>[];
  int cancelAllCalls = 0;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls += 1;
    scheduled = <ScheduledAlarm>[];
  }

  @override
  void dispose() {}

  @override
  Future<AlarmSchedulerCapabilities> initialize({
    required AlarmNotificationCallback onNotificationResponse,
  }) async {
    return _capabilities;
  }

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<AlarmSchedulerCapabilities> refreshCapabilities() async {
    return _capabilities;
  }

  @override
  Future<void> scheduleAlarms(List<ScheduledAlarm> alarms) async {
    scheduled = alarms;
  }
}

class FakeAlarmPresentationFeedback implements AlarmPresentationFeedback {
  int playCalls = 0;

  @override
  Future<void> play() async {
    playCalls += 1;
  }
}
