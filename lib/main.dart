import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/application/alarm_controller.dart';
import 'src/data/shared_preferences_alarm_session_repository.dart';
import 'src/data/shared_preferences_settings_repository.dart';
import 'src/platform/local_notifications_alarm_scheduler.dart';
import 'src/services/next_alarm_calculator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final AlarmController controller = AlarmController(
    settingsRepository: SharedPreferencesSettingsRepository(preferences),
    sessionRepository: SharedPreferencesAlarmSessionRepository(preferences),
    scheduler: LocalNotificationsAlarmScheduler(),
    calculator: const NextAlarmCalculator(),
  );
  await controller.initialize();

  runApp(SugoAlarmApp(controller: controller));
}
