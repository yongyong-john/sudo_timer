import 'package:flutter/material.dart';

class LocalAlarmTime {
  const LocalAlarmTime({
    required this.hour,
    required this.minute,
  });

  factory LocalAlarmTime.fromJson(Map<String, dynamic> json) {
    return LocalAlarmTime(
      hour: json['hour'] as int? ?? 0,
      minute: json['minute'] as int? ?? 0,
    );
  }

  factory LocalAlarmTime.fromTimeOfDay(TimeOfDay timeOfDay) {
    return LocalAlarmTime(hour: timeOfDay.hour, minute: timeOfDay.minute);
  }

  final int hour;
  final int minute;

  int get minutesSinceMidnight => (hour * 60) + minute;

  TimeOfDay toTimeOfDay() => TimeOfDay(hour: hour, minute: minute);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'hour': hour,
      'minute': minute,
    };
  }

  String formatLabel() {
    final String paddedHour = hour.toString().padLeft(2, '0');
    final String paddedMinute = minute.toString().padLeft(2, '0');
    return '$paddedHour:$paddedMinute';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is LocalAlarmTime &&
        other.hour == hour &&
        other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);
}
