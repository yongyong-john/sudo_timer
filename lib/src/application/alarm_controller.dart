import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../data/alarm_session_repository.dart';
import '../data/settings_repository.dart';
import '../models/alarm_session.dart';
import '../models/alarm_settings.dart';
import '../models/scheduled_alarm.dart';
import '../platform/alarm_scheduler.dart';
import '../services/next_alarm_calculator.dart';

class AlarmController extends ChangeNotifier with WidgetsBindingObserver {
  AlarmController({
    required SettingsRepository settingsRepository,
    required AlarmSessionRepository sessionRepository,
    required AlarmScheduler scheduler,
    required NextAlarmCalculator calculator,
    DateTime Function()? clock,
  })  : _settingsRepository = settingsRepository,
        _sessionRepository = sessionRepository,
        _scheduler = scheduler,
        _calculator = calculator,
        _clock = clock ?? DateTime.now;

  final SettingsRepository _settingsRepository;
  final AlarmSessionRepository _sessionRepository;
  final AlarmScheduler _scheduler;
  final NextAlarmCalculator _calculator;
  final DateTime Function() _clock;

  final Map<String, Timer> _foregroundTimers = <String, Timer>{};

  AlarmSettings _settings = AlarmSettings.defaults();
  AlarmSession _session = AlarmSession.initial();
  AlarmSchedulerCapabilities _capabilities =
      AlarmSchedulerCapabilities.unknown();
  ScheduledAlarm? _activeAlarm;
  bool _isInitializing = true;
  bool _isBusy = false;
  String? _lastMessage;

  AlarmSettings get settings => _settings;

  AlarmSession get session => _session;

  AlarmSchedulerCapabilities get capabilities => _capabilities;

  ScheduledAlarm? get activeAlarm => _activeAlarm;

  bool get isInitializing => _isInitializing;

  bool get isBusy => _isBusy;

  String? get lastMessage => _lastMessage;

  List<ScheduledAlarm> get nextAlarms => _session.scheduledAlarms;

  bool get canStart => !_isBusy;

  bool get canStop {
    return _session.scheduledAlarms.isNotEmpty ||
        _activeAlarm != null ||
        _session.status == AlarmLifecycleStatus.armed ||
        _session.status == AlarmLifecycleStatus.ringing;
  }

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _settings = await _settingsRepository.load();
    _session = await _sessionRepository.load();
    _capabilities = await _scheduler.initialize(
      onNotificationResponse: _handleNotificationResponse,
    );
    await _reconcileSession();
    _scheduleForegroundTimers();
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> startAlarms() async {
    await _runBusy(() async {
      _log('start requested');
      await _scheduler.cancelAll();
      _cancelForegroundTimers();

      final DateTime now = _clock().toLocal();
      final List<ScheduledAlarm> alarms = _calculator.calculateNextAlarms(
        settings: _settings,
        now: now,
      );
      _log(
          'calculated next alarms: ${alarms.map((ScheduledAlarm alarm) => alarm.finalFireTime.toIso8601String()).join(', ')}');

      _activeAlarm = null;

      if (alarms.isEmpty) {
        _session = AlarmSession(
          status: AlarmLifecycleStatus.idle,
          scheduledAlarms: const <ScheduledAlarm>[],
          lastStartedAt: now,
        );
        await _sessionRepository.save(_session);
        _lastMessage = '예약 가능한 다음 알림이 없습니다.';
        notifyListeners();
        return;
      }

      await _scheduler.scheduleAlarms(alarms);
      _session = AlarmSession(
        status: AlarmLifecycleStatus.armed,
        scheduledAlarms: alarms,
        lastStartedAt: now,
      );
      await _sessionRepository.save(_session);
      _scheduleForegroundTimers();
      _lastMessage = null;
      notifyListeners();
    });
  }

  Future<void> stopAlarms() async {
    await _runBusy(() async {
      _log('stop requested');
      await _scheduler.cancelAll();
      _cancelForegroundTimers();
      _activeAlarm = null;
      _session = const AlarmSession(
        status: AlarmLifecycleStatus.stopped,
        scheduledAlarms: <ScheduledAlarm>[],
      );
      await _sessionRepository.save(_session);
      _lastMessage = '예약된 알림을 모두 취소했습니다.';
      notifyListeners();
    });
  }

  Future<void> acknowledgeActiveAlarm() async {
    if (_activeAlarm == null) {
      return;
    }
    _log('alarm acknowledged: ${_activeAlarm!.id}');
    _activeAlarm = null;
    _session = _session.copyWith(
      status: _session.scheduledAlarms.isNotEmpty
          ? AlarmLifecycleStatus.armed
          : AlarmLifecycleStatus.consumed,
    );
    await _sessionRepository.save(_session);
    notifyListeners();
  }

  Future<void> updateSettings(AlarmSettings settings) async {
    _settings = settings;
    await _settingsRepository.save(settings);
    _lastMessage = null;

    final bool shouldRearm = _session.scheduledAlarms.isNotEmpty ||
        _session.status == AlarmLifecycleStatus.armed ||
        _session.status == AlarmLifecycleStatus.ringing;

    if (shouldRearm) {
      await startAlarms();
      return;
    }

    notifyListeners();
  }

  Future<void> openExactAlarmSettings() async {
    await _scheduler.openExactAlarmSettings();
    _capabilities = await _scheduler.refreshCapabilities();
    notifyListeners();
  }

  Future<void> refreshPlatformState() async {
    _capabilities = await _scheduler.refreshCapabilities();
    await _reconcileSession();
    _scheduleForegroundTimers();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshPlatformState());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelForegroundTimers();
    _scheduler.dispose();
    super.dispose();
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_isBusy) {
      return;
    }
    _isBusy = true;
    notifyListeners();
    try {
      await action();
    } catch (error, stackTrace) {
      _lastMessage = '작업 중 오류가 발생했습니다: $error';
      _log('error: $error\n$stackTrace');
      notifyListeners();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _reconcileSession() async {
    final DateTime now = _clock().toLocal();
    final List<ScheduledAlarm> remaining = _session.scheduledAlarms
        .where((ScheduledAlarm alarm) => alarm.finalFireTime.isAfter(now))
        .toList();

    if (remaining.length == _session.scheduledAlarms.length) {
      return;
    }

    AlarmLifecycleStatus nextStatus;
    if (remaining.isNotEmpty) {
      nextStatus = AlarmLifecycleStatus.armed;
    } else if (_session.status == AlarmLifecycleStatus.stopped) {
      nextStatus = AlarmLifecycleStatus.stopped;
    } else if (_session.lastStartedAt != null) {
      nextStatus = AlarmLifecycleStatus.consumed;
    } else {
      nextStatus = AlarmLifecycleStatus.idle;
    }

    _session = _session.copyWith(
      status: nextStatus,
      scheduledAlarms: remaining,
    );
    await _sessionRepository.save(_session);
  }

  void _scheduleForegroundTimers() {
    _cancelForegroundTimers();
    for (final ScheduledAlarm alarm in _session.scheduledAlarms) {
      final Duration delay = alarm.finalFireTime.difference(_clock().toLocal());
      if (delay.isNegative) {
        continue;
      }
      _foregroundTimers[alarm.id] = Timer(delay, () {
        unawaited(_onAlarmDue(alarm.id));
      });
    }
  }

  void _cancelForegroundTimers() {
    for (final Timer timer in _foregroundTimers.values) {
      timer.cancel();
    }
    _foregroundTimers.clear();
  }

  Future<void> _onAlarmDue(String alarmId) async {
    final ScheduledAlarm? scheduled = _findScheduledAlarm(alarmId);
    if (scheduled == null) {
      return;
    }

    _log('alarm due: $alarmId');
    _foregroundTimers.remove(alarmId)?.cancel();

    final List<ScheduledAlarm> remaining = _session.scheduledAlarms
        .where((ScheduledAlarm alarm) => alarm.id != alarmId)
        .toList();
    _activeAlarm = scheduled.copyWith(status: ScheduledAlarmStatus.fired);
    _session = _session.copyWith(
      status: remaining.isEmpty
          ? AlarmLifecycleStatus.consumed
          : AlarmLifecycleStatus.ringing,
      scheduledAlarms: remaining,
    );
    await _sessionRepository.save(_session);
    notifyListeners();
  }

  Future<void> _handleNotificationResponse(AlarmNotificationEvent event) async {
    _log(
        'notification response: alarm=${event.alarmId}, action=${event.actionId}');
    final ScheduledAlarm? scheduled = _findScheduledAlarm(event.alarmId);
    if (scheduled != null) {
      _foregroundTimers.remove(event.alarmId)?.cancel();
    }

    final List<ScheduledAlarm> remaining = _session.scheduledAlarms
        .where((ScheduledAlarm alarm) => alarm.id != event.alarmId)
        .toList();

    if (event.actionId == 'stop') {
      _activeAlarm = null;
      _session = _session.copyWith(
        status: remaining.isEmpty
            ? AlarmLifecycleStatus.consumed
            : AlarmLifecycleStatus.armed,
        scheduledAlarms: remaining,
      );
    } else {
      _activeAlarm = (scheduled ?? _activeAlarm)?.copyWith(
        status: ScheduledAlarmStatus.fired,
      );
      _session = _session.copyWith(
        status: remaining.isEmpty
            ? AlarmLifecycleStatus.consumed
            : AlarmLifecycleStatus.ringing,
        scheduledAlarms: remaining,
      );
    }

    await _sessionRepository.save(_session);
    notifyListeners();
  }

  ScheduledAlarm? _findScheduledAlarm(String alarmId) {
    for (final ScheduledAlarm alarm in _session.scheduledAlarms) {
      if (alarm.id == alarmId) {
        return alarm;
      }
    }
    return null;
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[sugo_alarm] $message');
    }
  }
}
