import 'local_alarm_time.dart';
import 'scheduled_alarm.dart';

class AlarmSettings {
  const AlarmSettings({
    required this.sleepStartTime,
    required this.sleepEndTime,
    required this.enableQuarter15,
    required this.enableQuarter45,
    required this.offsetsFor15,
    required this.offsetsFor45,
    required this.soundAsset,
    required this.windowsTrayModeEnabled,
  });

  factory AlarmSettings.defaults() {
    return const AlarmSettings(
      sleepStartTime: LocalAlarmTime(hour: 23, minute: 0),
      sleepEndTime: LocalAlarmTime(hour: 7, minute: 0),
      enableQuarter15: true,
      enableQuarter45: true,
      offsetsFor15: <int>[0],
      offsetsFor45: <int>[0],
      soundAsset: '',
      windowsTrayModeEnabled: true,
    );
  }

  factory AlarmSettings.fromJson(Map<String, dynamic> json) {
    return AlarmSettings(
      sleepStartTime: LocalAlarmTime.fromJson(
        (json['sleepStartTime'] as Map<dynamic, dynamic>? ??
                <String, dynamic>{})
            .cast<String, dynamic>(),
      ),
      sleepEndTime: LocalAlarmTime.fromJson(
        (json['sleepEndTime'] as Map<dynamic, dynamic>? ?? <String, dynamic>{})
            .cast<String, dynamic>(),
      ),
      enableQuarter15: json['enableQuarter15'] as bool? ?? true,
      enableQuarter45: json['enableQuarter45'] as bool? ?? true,
      offsetsFor15: _parseOffsets(json['offsetsFor15'] as List<dynamic>?),
      offsetsFor45: _parseOffsets(json['offsetsFor45'] as List<dynamic>?),
      soundAsset: json['soundAsset'] as String? ?? '',
      windowsTrayModeEnabled: json['windowsTrayModeEnabled'] as bool? ?? true,
    );
  }

  static List<int> _parseOffsets(List<dynamic>? source) {
    final List<int> offsets = (source ?? const <dynamic>[0])
        .map((dynamic value) => value as int)
        .toSet()
        .toList()
      ..sort();
    return offsets.isEmpty ? <int>[0] : offsets;
  }

  final LocalAlarmTime sleepStartTime;
  final LocalAlarmTime sleepEndTime;
  final bool enableQuarter15;
  final bool enableQuarter45;
  final List<int> offsetsFor15;
  final List<int> offsetsFor45;
  final String soundAsset;
  final bool windowsTrayModeEnabled;

  List<AlarmQuarterType> get enabledBaseTypes {
    return AlarmQuarterType.values.where((AlarmQuarterType type) {
      switch (type) {
        case AlarmQuarterType.quarter15:
          return enableQuarter15;
        case AlarmQuarterType.quarter45:
          return enableQuarter45;
      }
    }).toList();
  }

  List<int> offsetsForType(AlarmQuarterType type) {
    switch (type) {
      case AlarmQuarterType.quarter15:
        return offsetsFor15.isEmpty ? const <int>[0] : offsetsFor15;
      case AlarmQuarterType.quarter45:
        return offsetsFor45.isEmpty ? const <int>[0] : offsetsFor45;
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sleepStartTime': sleepStartTime.toJson(),
      'sleepEndTime': sleepEndTime.toJson(),
      'enableQuarter15': enableQuarter15,
      'enableQuarter45': enableQuarter45,
      'offsetsFor15': offsetsFor15,
      'offsetsFor45': offsetsFor45,
      'soundAsset': soundAsset,
      'windowsTrayModeEnabled': windowsTrayModeEnabled,
    };
  }

  AlarmSettings copyWith({
    LocalAlarmTime? sleepStartTime,
    LocalAlarmTime? sleepEndTime,
    bool? enableQuarter15,
    bool? enableQuarter45,
    List<int>? offsetsFor15,
    List<int>? offsetsFor45,
    String? soundAsset,
    bool? windowsTrayModeEnabled,
  }) {
    return AlarmSettings(
      sleepStartTime: sleepStartTime ?? this.sleepStartTime,
      sleepEndTime: sleepEndTime ?? this.sleepEndTime,
      enableQuarter15: enableQuarter15 ?? this.enableQuarter15,
      enableQuarter45: enableQuarter45 ?? this.enableQuarter45,
      offsetsFor15: offsetsFor15 ?? this.offsetsFor15,
      offsetsFor45: offsetsFor45 ?? this.offsetsFor45,
      soundAsset: soundAsset ?? this.soundAsset,
      windowsTrayModeEnabled:
          windowsTrayModeEnabled ?? this.windowsTrayModeEnabled,
    );
  }
}
