import 'package:flutter_test/flutter_test.dart';
import 'package:sugo_alarm/src/models/alarm_settings.dart';
import 'package:sugo_alarm/src/models/local_alarm_time.dart';
import 'package:sugo_alarm/src/services/next_alarm_calculator.dart';

void main() {
  const NextAlarmCalculator calculator = NextAlarmCalculator();

  test('returns 10:15 and 10:45 for 10:12 outside sleep window', () {
    final List<DateTime> alarms = calculator
        .calculateNextAlarms(
          settings: AlarmSettings.defaults(),
          now: DateTime(2026, 3, 17, 10, 12),
        )
        .map((alarm) => alarm.finalFireTime)
        .toList();

    expect(
      alarms,
      <DateTime>[
        DateTime(2026, 3, 17, 10, 15),
        DateTime(2026, 3, 17, 10, 45),
      ],
    );
  });

  test('skips sleep window across midnight and lands on 07:15 and 07:45', () {
    final AlarmSettings settings = AlarmSettings.defaults().copyWith(
      sleepStartTime: const LocalAlarmTime(hour: 23, minute: 0),
      sleepEndTime: const LocalAlarmTime(hour: 7, minute: 0),
    );

    final List<DateTime> alarms = calculator
        .calculateNextAlarms(
          settings: settings,
          now: DateTime(2026, 3, 17, 22, 50),
        )
        .map((alarm) => alarm.finalFireTime)
        .toList();

    expect(
      alarms,
      <DateTime>[
        DateTime(2026, 3, 18, 7, 15),
        DateTime(2026, 3, 18, 7, 45),
      ],
    );
  });

  test('filters by final fire time after applying offsets', () {
    final AlarmSettings settings = AlarmSettings.defaults().copyWith(
      sleepStartTime: const LocalAlarmTime(hour: 23, minute: 0),
      sleepEndTime: const LocalAlarmTime(hour: 7, minute: 15),
      enableQuarter45: false,
      offsetsFor15: const <int>[-5, 0],
    );

    final List<DateTime> alarms = calculator
        .calculateNextAlarms(
          settings: settings,
          now: DateTime(2026, 3, 17, 6, 50),
        )
        .map((alarm) => alarm.finalFireTime)
        .toList();

    expect(
      alarms,
      <DateTime>[
        DateTime(2026, 3, 17, 7, 15),
        DateTime(2026, 3, 17, 8, 10),
      ],
    );
  });
}
