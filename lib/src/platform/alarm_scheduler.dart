import 'dart:async';

import '../models/scheduled_alarm.dart';

typedef AlarmNotificationCallback = FutureOr<void> Function(
  AlarmNotificationEvent event,
);

class AlarmNotificationEvent {
  const AlarmNotificationEvent({
    required this.alarmId,
    this.actionId,
    this.launchedApplication = false,
  });

  final String alarmId;
  final String? actionId;
  final bool launchedApplication;
}

class AlarmSchedulerCapabilities {
  const AlarmSchedulerCapabilities({
    required this.platformName,
    required this.notificationsEnabled,
    required this.supportsScheduledNotifications,
    required this.supportsForegroundPresentation,
    required this.supportsNotificationActions,
    required this.exactAlarmPermissionRequired,
    required this.exactAlarmPermissionGranted,
    required this.canOpenExactAlarmSettings,
    required this.requiresRunningProcessForPrecision,
    required this.notes,
  });

  factory AlarmSchedulerCapabilities.unknown() {
    return const AlarmSchedulerCapabilities(
      platformName: 'Unknown',
      notificationsEnabled: true,
      supportsScheduledNotifications: false,
      supportsForegroundPresentation: true,
      supportsNotificationActions: false,
      exactAlarmPermissionRequired: false,
      exactAlarmPermissionGranted: true,
      canOpenExactAlarmSettings: false,
      requiresRunningProcessForPrecision: false,
      notes: '',
    );
  }

  final String platformName;
  final bool notificationsEnabled;
  final bool supportsScheduledNotifications;
  final bool supportsForegroundPresentation;
  final bool supportsNotificationActions;
  final bool exactAlarmPermissionRequired;
  final bool exactAlarmPermissionGranted;
  final bool canOpenExactAlarmSettings;
  final bool requiresRunningProcessForPrecision;
  final String notes;

  bool get canScheduleReliably {
    return notificationsEnabled &&
        supportsScheduledNotifications &&
        (!exactAlarmPermissionRequired || exactAlarmPermissionGranted);
  }
}

abstract class AlarmScheduler {
  Future<AlarmSchedulerCapabilities> initialize({
    required AlarmNotificationCallback onNotificationResponse,
  });

  Future<AlarmSchedulerCapabilities> refreshCapabilities();

  Future<void> scheduleAlarms(List<ScheduledAlarm> alarms);

  Future<void> cancelAll();

  Future<void> openExactAlarmSettings();

  void dispose();
}
