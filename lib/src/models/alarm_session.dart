import 'scheduled_alarm.dart';

enum AlarmLifecycleStatus {
  idle,
  armed,
  ringing,
  consumed,
  stopped;

  static AlarmLifecycleStatus fromName(String value) {
    return AlarmLifecycleStatus.values.firstWhere(
      (AlarmLifecycleStatus status) => status.name == value,
      orElse: () => AlarmLifecycleStatus.idle,
    );
  }
}

class AlarmSession {
  const AlarmSession({
    required this.status,
    required this.scheduledAlarms,
    this.lastStartedAt,
  });

  factory AlarmSession.initial() {
    return const AlarmSession(
      status: AlarmLifecycleStatus.idle,
      scheduledAlarms: <ScheduledAlarm>[],
    );
  }

  factory AlarmSession.fromJson(Map<String, dynamic> json) {
    return AlarmSession(
      status: AlarmLifecycleStatus.fromName(
        json['status'] as String? ?? AlarmLifecycleStatus.idle.name,
      ),
      scheduledAlarms: (json['scheduledAlarms'] as List<dynamic>? ??
              <dynamic>[])
          .map(
            (dynamic item) =>
                ScheduledAlarm.fromJson((item as Map<dynamic, dynamic>).cast()),
          )
          .toList(),
      lastStartedAt: json['lastStartedAt'] == null
          ? null
          : DateTime.parse(json['lastStartedAt'] as String).toLocal(),
    );
  }

  final AlarmLifecycleStatus status;
  final List<ScheduledAlarm> scheduledAlarms;
  final DateTime? lastStartedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status.name,
      'scheduledAlarms': scheduledAlarms
          .map((ScheduledAlarm alarm) => alarm.toJson())
          .toList(),
      'lastStartedAt': lastStartedAt?.toIso8601String(),
    };
  }

  AlarmSession copyWith({
    AlarmLifecycleStatus? status,
    List<ScheduledAlarm>? scheduledAlarms,
    DateTime? lastStartedAt,
  }) {
    return AlarmSession(
      status: status ?? this.status,
      scheduledAlarms: scheduledAlarms ?? this.scheduledAlarms,
      lastStartedAt: lastStartedAt ?? this.lastStartedAt,
    );
  }
}
