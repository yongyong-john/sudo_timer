import 'package:flutter/material.dart';

import 'application/alarm_controller.dart';
import 'platform/alarm_presentation_feedback.dart';
import 'presentation/alarm_home_page.dart';

class SugoAlarmApp extends StatelessWidget {
  const SugoAlarmApp({
    super.key,
    required this.controller,
    AlarmPresentationFeedback? presentationFeedback,
  }) : _presentationFeedback =
            presentationFeedback ?? const PlatformAlarmPresentationFeedback();

  final AlarmController controller;
  final AlarmPresentationFeedback _presentationFeedback;

  @override
  Widget build(BuildContext context) {
    const Color canvas = Color(0xFFF4EEE6);
    const Color accent = Color(0xFFB5542F);
    const Color ink = Color(0xFF2D2A26);

    return MaterialApp(
      title: 'Sugo Alarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: canvas,
        cardTheme: const CardTheme(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: ink,
              displayColor: ink,
            ),
      ),
      home: AlarmHomePage(
        controller: controller,
        presentationFeedback: _presentationFeedback,
      ),
    );
  }
}
