import '../models/alarm_settings.dart';
import '../models/scheduled_alarm.dart';

class NextAlarmCalculator {
  const NextAlarmCalculator({
    this.maxSearchHours = 96,
  });

  final int maxSearchHours;

  List<ScheduledAlarm> calculateNextAlarms({
    required AlarmSettings settings,
    required DateTime now,
    int limit = 2,
  }) {
    final DateTime localNow = now.toLocal();
    if (limit <= 0 || settings.enabledBaseTypes.isEmpty) {
      return const <ScheduledAlarm>[];
    }

    final DateTime anchor =
        DateTime(localNow.year, localNow.month, localNow.day, localNow.hour);
    final List<ScheduledAlarm> candidates = <ScheduledAlarm>[];

    for (int hourOffset = 0;
        hourOffset < maxSearchHours && candidates.length < (limit * 4);
        hourOffset++) {
      for (final AlarmQuarterType baseType in settings.enabledBaseTypes) {
        final DateTime baseTime = DateTime(
          anchor.year,
          anchor.month,
          anchor.day,
          anchor.hour + hourOffset,
          baseType.baseMinute,
        );

        for (final int offsetMinutes in settings.offsetsForType(baseType)) {
          final DateTime fireTime =
              baseTime.add(Duration(minutes: offsetMinutes));
          if (!fireTime.isAfter(localNow)) {
            continue;
          }
          if (_isWithinSleepWindow(settings, fireTime)) {
            continue;
          }
          candidates.add(
            ScheduledAlarm(
              id: _buildId(baseType, baseTime, offsetMinutes),
              baseType: baseType,
              baseTime: baseTime,
              offsetMinutes: offsetMinutes,
              finalFireTime: fireTime,
              platformRequestId:
                  _buildPlatformRequestId(baseType, baseTime, offsetMinutes),
              status: ScheduledAlarmStatus.scheduled,
            ),
          );
        }
      }
    }

    candidates.sort((ScheduledAlarm left, ScheduledAlarm right) {
      final int byTime = left.finalFireTime.compareTo(right.finalFireTime);
      if (byTime != 0) {
        return byTime;
      }
      final int byBase = left.baseTime.compareTo(right.baseTime);
      if (byBase != 0) {
        return byBase;
      }
      return left.offsetMinutes.compareTo(right.offsetMinutes);
    });

    return candidates.take(limit).toList();
  }

  bool _isWithinSleepWindow(AlarmSettings settings, DateTime fireTime) {
    final int start = settings.sleepStartTime.minutesSinceMidnight;
    final int end = settings.sleepEndTime.minutesSinceMidnight;
    final int time = (fireTime.hour * 60) + fireTime.minute;

    if (start == end) {
      return false;
    }
    if (start < end) {
      return time >= start && time < end;
    }
    return time >= start || time < end;
  }

  String _buildId(
    AlarmQuarterType baseType,
    DateTime baseTime,
    int offsetMinutes,
  ) {
    return '${baseType.name}-${baseTime.toIso8601String()}-$offsetMinutes';
  }

  int _buildPlatformRequestId(
    AlarmQuarterType baseType,
    DateTime baseTime,
    int offsetMinutes,
  ) {
    final int minuteEpoch = baseTime.millisecondsSinceEpoch ~/ 60000;
    return (minuteEpoch ^
            (offsetMinutes << 7) ^
            (baseType == AlarmQuarterType.quarter15 ? 15 : 45)) &
        0x7fffffff;
  }
}
