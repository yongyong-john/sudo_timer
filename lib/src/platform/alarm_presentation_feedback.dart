import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class AlarmPresentationFeedback {
  Future<void> play();
}

class PlatformAlarmPresentationFeedback implements AlarmPresentationFeedback {
  const PlatformAlarmPresentationFeedback();

  static const MethodChannel _androidChannel =
      MethodChannel('sugo_alarm/foreground_feedback');

  @override
  Future<void> play() async {
    if (kIsWeb) {
      return;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        try {
          await _androidChannel.invokeMethod<void>('playForForegroundAlarm');
        } on PlatformException {
          await HapticFeedback.mediumImpact();
        }
        return;
      case TargetPlatform.iOS:
        await HapticFeedback.mediumImpact();
        return;
      case TargetPlatform.windows:
        await SystemSound.play(SystemSoundType.alert);
        return;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return;
    }
  }
}
