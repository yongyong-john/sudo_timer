import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sugo_alarm/src/app.dart';
import 'package:sugo_alarm/src/application/alarm_controller.dart';
import 'package:sugo_alarm/src/models/alarm_session.dart';
import 'package:sugo_alarm/src/models/alarm_settings.dart';
import 'package:sugo_alarm/src/services/next_alarm_calculator.dart';

import 'fakes/fakes.dart';

void main() {
  testWidgets('start button arms next two alarms and renders schedule',
      (WidgetTester tester) async {
    final InMemorySettingsRepository settingsRepository =
        InMemorySettingsRepository(AlarmSettings.defaults());
    final InMemoryAlarmSessionRepository sessionRepository =
        InMemoryAlarmSessionRepository(AlarmSession.initial());
    final FakeAlarmScheduler scheduler = FakeAlarmScheduler();
    final FakeAlarmPresentationFeedback feedback =
        FakeAlarmPresentationFeedback();
    final AlarmController controller = AlarmController(
      settingsRepository: settingsRepository,
      sessionRepository: sessionRepository,
      scheduler: scheduler,
      calculator: const NextAlarmCalculator(),
      clock: () => DateTime(2026, 3, 17, 10, 12),
    );
    await controller.initialize();

    await tester.pumpWidget(
      SugoAlarmApp(
        controller: controller,
        presentationFeedback: feedback,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('예약된 알림이 없습니다.'), findsOneWidget);

    await tester.tap(find.text('알림 시작'));
    await tester.pumpAndSettle();

    expect(find.text('3/17 10:15'), findsOneWidget);
    expect(find.text('3/17 10:45'), findsOneWidget);
    expect(scheduler.scheduled, hasLength(2));
    expect(feedback.playCalls, 0);

    controller.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('plays foreground feedback when alarm dialog is shown',
      (WidgetTester tester) async {
    final InMemorySettingsRepository settingsRepository =
        InMemorySettingsRepository(AlarmSettings.defaults());
    final InMemoryAlarmSessionRepository sessionRepository =
        InMemoryAlarmSessionRepository(AlarmSession.initial());
    final FakeAlarmScheduler scheduler = FakeAlarmScheduler();
    final FakeAlarmPresentationFeedback feedback =
        FakeAlarmPresentationFeedback();
    final AlarmController controller = AlarmController(
      settingsRepository: settingsRepository,
      sessionRepository: sessionRepository,
      scheduler: scheduler,
      calculator: const NextAlarmCalculator(),
      clock: () => DateTime(2026, 3, 17, 10, 12),
    );
    await controller.initialize();

    await tester.pumpWidget(
      SugoAlarmApp(
        controller: controller,
        presentationFeedback: feedback,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('알림 시작'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(minutes: 3));
    await tester.pumpAndSettle();

    expect(find.text('알림 도달'), findsOneWidget);
    expect(feedback.playCalls, 1);

    await tester.tap(find.text('확인/중지'));
    await tester.pumpAndSettle();

    controller.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
