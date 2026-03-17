enum AlarmQuarterType {
  quarter15(15, '정각 +15분'),
  quarter45(45, '정각 +45분');

  const AlarmQuarterType(this.baseMinute, this.label);

  final int baseMinute;
  final String label;

  static AlarmQuarterType fromName(String value) {
    return AlarmQuarterType.values.firstWhere(
      (AlarmQuarterType type) => type.name == value,
      orElse: () => AlarmQuarterType.quarter15,
    );
  }
}

enum ScheduledAlarmStatus {
  scheduled,
  fired,
  cancelled;

  static ScheduledAlarmStatus fromName(String value) {
    return ScheduledAlarmStatus.values.firstWhere(
      (ScheduledAlarmStatus status) => status.name == value,
      orElse: () => ScheduledAlarmStatus.scheduled,
    );
  }
}

class ScheduledAlarm {
  const ScheduledAlarm({
    required this.id,
    required this.baseType,
    required this.baseTime,
    required this.offsetMinutes,
    required this.finalFireTime,
    required this.platformRequestId,
    required this.status,
  });

  factory ScheduledAlarm.fromJson(Map<String, dynamic> json) {
    return ScheduledAlarm(
      id: json['id'] as String? ?? '',
      baseType:
          AlarmQuarterType.fromName(json['baseType'] as String? ?? 'quarter15'),
      baseTime: DateTime.parse(json['baseTime'] as String).toLocal(),
      offsetMinutes: json['offsetMinutes'] as int? ?? 0,
      finalFireTime: DateTime.parse(json['finalFireTime'] as String).toLocal(),
      platformRequestId: json['platformRequestId'] as int? ?? 0,
      status: ScheduledAlarmStatus.fromName(
        json['status'] as String? ?? ScheduledAlarmStatus.scheduled.name,
      ),
    );
  }

  final String id;
  final AlarmQuarterType baseType;
  final DateTime baseTime;
  final int offsetMinutes;
  final DateTime finalFireTime;
  final int platformRequestId;
  final ScheduledAlarmStatus status;

  bool get isFuture => finalFireTime.isAfter(DateTime.now());

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'baseType': baseType.name,
      'baseTime': baseTime.toIso8601String(),
      'offsetMinutes': offsetMinutes,
      'finalFireTime': finalFireTime.toIso8601String(),
      'platformRequestId': platformRequestId,
      'status': status.name,
    };
  }

  ScheduledAlarm copyWith({
    ScheduledAlarmStatus? status,
  }) {
    return ScheduledAlarm(
      id: id,
      baseType: baseType,
      baseTime: baseTime,
      offsetMinutes: offsetMinutes,
      finalFireTime: finalFireTime,
      platformRequestId: platformRequestId,
      status: status ?? this.status,
    );
  }
}
