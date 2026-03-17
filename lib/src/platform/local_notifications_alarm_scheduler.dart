import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/scheduled_alarm.dart';
import 'alarm_scheduler.dart';

class LocalNotificationsAlarmScheduler implements AlarmScheduler {
  LocalNotificationsAlarmScheduler({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _androidChannelId = 'sugo_alarm_exact';
  static const String _androidChannelName = 'Scheduled alarms';
  static const String _androidChannelDescription =
      'One-shot alarms for the next two valid quarter times.';
  static const String _iosCategoryId = 'sugo_alarm_actions';
  static const MethodChannel _androidExactAlarmChannel =
      MethodChannel('sugo_alarm/android_exact_alarm');

  final FlutterLocalNotificationsPlugin _plugin;

  AlarmNotificationCallback? _notificationCallback;
  AlarmSchedulerCapabilities _capabilities =
      AlarmSchedulerCapabilities.unknown();
  bool _darwinPermissionsGranted = true;

  bool get _usesPluginScheduling {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<AlarmSchedulerCapabilities> initialize({
    required AlarmNotificationCallback onNotificationResponse,
  }) async {
    _notificationCallback = onNotificationResponse;

    if (_usesPluginScheduling) {
      await _plugin.initialize(
        _buildInitializationSettings(),
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );
    }

    if (_isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestPermission();
    } else if (_isIOS) {
      _darwinPermissionsGranted = await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ??
          false;
    }

    _capabilities = await refreshCapabilities();

    if (_usesPluginScheduling) {
      final NotificationAppLaunchDetails? launchDetails =
          await _plugin.getNotificationAppLaunchDetails();
      final NotificationResponse? response =
          launchDetails?.notificationResponse;
      if (launchDetails?.didNotificationLaunchApp == true && response != null) {
        _handleNotificationResponse(
          NotificationResponse(
            id: response.id,
            actionId: response.actionId,
            input: response.input,
            payload: response.payload,
            notificationResponseType: response.notificationResponseType,
          ),
          launchedApplication: true,
        );
      }
    }

    return _capabilities;
  }

  @override
  Future<AlarmSchedulerCapabilities> refreshCapabilities() async {
    if (_isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool notificationsEnabled =
          await androidPlugin?.areNotificationsEnabled() ?? true;
      final bool exactGranted =
          await _invokeAndroidBoolean('canScheduleExactAlarms') ?? true;
      _capabilities = AlarmSchedulerCapabilities(
        platformName: 'Android',
        notificationsEnabled: notificationsEnabled,
        supportsScheduledNotifications: true,
        supportsForegroundPresentation: true,
        supportsNotificationActions: true,
        exactAlarmPermissionRequired: true,
        exactAlarmPermissionGranted: exactGranted,
        canOpenExactAlarmSettings: true,
        requiresRunningProcessForPrecision: false,
        notes: exactGranted
            ? '개별 exact alarm 예약 경로를 사용합니다.'
            : '정확한 시각 예약 권한이 없어 시스템 지연이 생길 수 있습니다.',
      );
      return _capabilities;
    }

    if (_isIOS) {
      _capabilities = AlarmSchedulerCapabilities(
        platformName: 'iOS',
        notificationsEnabled: _darwinPermissionsGranted,
        supportsScheduledNotifications: true,
        supportsForegroundPresentation: true,
        supportsNotificationActions: true,
        exactAlarmPermissionRequired: false,
        exactAlarmPermissionGranted: true,
        canOpenExactAlarmSettings: false,
        requiresRunningProcessForPrecision: false,
        notes: '항상 다음 2개만 예약해 iOS pending 64개 제한을 피합니다.',
      );
      return _capabilities;
    }

    if (defaultTargetPlatform == TargetPlatform.windows) {
      _capabilities = const AlarmSchedulerCapabilities(
        platformName: 'Windows',
        notificationsEnabled: true,
        supportsScheduledNotifications: false,
        supportsForegroundPresentation: true,
        supportsNotificationActions: false,
        exactAlarmPermissionRequired: false,
        exactAlarmPermissionGranted: true,
        canOpenExactAlarmSettings: false,
        requiresRunningProcessForPrecision: true,
        notes: '정확 시각 보장은 앱 프로세스가 살아 있을 때만 가능합니다. 트레이 상주 네이티브 연동은 아직 남아 있습니다.',
      );
      return _capabilities;
    }

    _capabilities = const AlarmSchedulerCapabilities(
      platformName: 'Unsupported',
      notificationsEnabled: true,
      supportsScheduledNotifications: false,
      supportsForegroundPresentation: true,
      supportsNotificationActions: false,
      exactAlarmPermissionRequired: false,
      exactAlarmPermissionGranted: true,
      canOpenExactAlarmSettings: false,
      requiresRunningProcessForPrecision: false,
      notes: '이 플랫폼은 현재 앱 내 foreground 표시만 제공합니다.',
    );
    return _capabilities;
  }

  @override
  Future<void> scheduleAlarms(List<ScheduledAlarm> alarms) async {
    if (!_usesPluginScheduling) {
      return;
    }

    for (final ScheduledAlarm alarm in alarms) {
      // ignore: deprecated_member_use
      await _plugin.schedule(
        alarm.platformRequestId,
        '시간 알림',
        _buildBody(alarm),
        alarm.finalFireTime,
        _buildNotificationDetails(),
        payload: jsonEncode(<String, dynamic>{
          'alarmId': alarm.id,
        }),
        androidAllowWhileIdle: true,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_usesPluginScheduling) {
      return;
    }
    await _plugin.cancelAll();
  }

  @override
  Future<void> openExactAlarmSettings() async {
    if (!_isAndroid) {
      return;
    }
    await _androidExactAlarmChannel
        .invokeMethod<void>('openExactAlarmSettings');
  }

  @override
  void dispose() {}

  Future<bool?> _invokeAndroidBoolean(String method) async {
    if (!_isAndroid) {
      return null;
    }
    try {
      return await _androidExactAlarmChannel.invokeMethod<bool>(method);
    } on PlatformException {
      return null;
    }
  }

  InitializationSettings _buildInitializationSettings() {
    return InitializationSettings(
      android: const AndroidInitializationSettings('ic_stat_alarm'),
      iOS: DarwinInitializationSettings(
        defaultPresentAlert: true,
        defaultPresentBadge: false,
        defaultPresentSound: true,
        notificationCategories: <DarwinNotificationCategory>[
          DarwinNotificationCategory(
            _iosCategoryId,
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(
                'open',
                '앱 열기',
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.foreground,
                },
              ),
              DarwinNotificationAction.plain(
                'stop',
                '확인/중지',
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.foreground,
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  NotificationDetails _buildNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'open',
            '앱 열기',
            showsUserInterface: true,
            cancelNotification: false,
          ),
          AndroidNotificationAction(
            'stop',
            '확인/중지',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        categoryIdentifier: _iosCategoryId,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  String _buildBody(ScheduledAlarm alarm) {
    final String sign = alarm.offsetMinutes > 0 ? '+' : '';
    return '${alarm.baseType.label} 기준 $sign${alarm.offsetMinutes}분 알림';
  }

  void _handleNotificationResponse(
    NotificationResponse response, {
    bool launchedApplication = false,
  }) {
    final String? payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    final Map<String, dynamic> json =
        (jsonDecode(payload) as Map<dynamic, dynamic>).cast<String, dynamic>();
    final String? alarmId = json['alarmId'] as String?;
    if (alarmId == null || alarmId.isEmpty) {
      return;
    }

    _notificationCallback?.call(
      AlarmNotificationEvent(
        alarmId: alarmId,
        actionId: response.actionId,
        launchedApplication: launchedApplication,
      ),
    );
  }
}
