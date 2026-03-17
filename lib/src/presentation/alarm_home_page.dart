import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../application/alarm_controller.dart';
import '../models/alarm_session.dart';
import '../models/alarm_settings.dart';
import '../models/local_alarm_time.dart';
import '../models/scheduled_alarm.dart';
import '../platform/alarm_presentation_feedback.dart';

class AlarmHomePage extends StatefulWidget {
  const AlarmHomePage({
    super.key,
    required this.controller,
    required this.presentationFeedback,
  });

  final AlarmController controller;
  final AlarmPresentationFeedback presentationFeedback;

  @override
  State<AlarmHomePage> createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<AlarmHomePage> {
  final DateFormat _dateFormat = DateFormat('M/d HH:mm');
  String? _presentedAlarmId;

  AlarmController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        _maybePresentAlarmDialog();

        if (_controller.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: const Text('Sugo Alarm'),
            actions: <Widget>[
              IconButton(
                tooltip: '새로고침',
                onPressed: _controller.refreshPlatformState,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFF7F0E7),
                  Color(0xFFEBDAC8),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: <Widget>[
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildNextAlarmCard(),
                  const SizedBox(height: 16),
                  _buildControlsCard(),
                  const SizedBox(height: 16),
                  _buildSleepCard(),
                  const SizedBox(height: 16),
                  _buildPlatformCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    final AlarmLifecycleStatus status = _controller.session.status;
    final Color tone = _statusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: tone.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: tone,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(_controller.capabilities.platformName),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '항상 다음 2회만 예약합니다.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.lastMessage ??
                  '취침 시간과 기준 시각에 맞는 가장 이른 2개의 알림만 유지합니다.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextAlarmCard() {
    final List<ScheduledAlarm> alarms = _controller.nextAlarms;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '다음 예정 시각',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            if (alarms.isEmpty)
              Text(
                '예약된 알림이 없습니다.',
                style: Theme.of(context).textTheme.bodyLarge,
              )
            else
              ...alarms.map(_buildAlarmTile).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmTile(ScheduledAlarm alarm) {
    final String offsetLabel = alarm.offsetMinutes == 0
        ? '기준 시각'
        : '${alarm.offsetMinutes > 0 ? '+' : ''}${alarm.offsetMinutes}분';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.schedule_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _dateFormat.format(alarm.finalFireTime),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text('${alarm.baseType.label} · $offsetLabel'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '제어',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _controller.canStart ? _controller.startAlarms : null,
                    icon: _controller.isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow_rounded),
                    label: const Text('알림 시작'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _controller.canStop ? _controller.stopAlarms : null,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('중지'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _controller.settings.enableQuarter15,
              title: const Text(':15 알림 사용'),
              onChanged: (bool value) {
                _controller.updateSettings(
                  _controller.settings.copyWith(enableQuarter15: value),
                );
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _controller.settings.enableQuarter45,
              title: const Text(':45 알림 사용'),
              onChanged: (bool value) {
                _controller.updateSettings(
                  _controller.settings.copyWith(enableQuarter45: value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard() {
    final AlarmSettings settings = _controller.settings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '취침 시간',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '최종 발화 시각이 이 구간에 들어가면 예약하지 않습니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('취침 시작'),
              subtitle: Text(settings.sleepStartTime.formatLabel()),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _pickSleepTime(
                initialValue: settings.sleepStartTime,
                onSelected: (LocalAlarmTime value) {
                  _controller.updateSettings(
                    settings.copyWith(sleepStartTime: value),
                  );
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('취침 종료'),
              subtitle: Text(settings.sleepEndTime.formatLabel()),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _pickSleepTime(
                initialValue: settings.sleepEndTime,
                onSelected: (LocalAlarmTime value) {
                  _controller.updateSettings(
                    settings.copyWith(sleepEndTime: value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformCard() {
    final capabilities = _controller.capabilities;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '플랫폼 상태',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            _buildCapabilityRow(
              '알림 권한',
              capabilities.notificationsEnabled ? '사용 가능' : '비활성',
            ),
            _buildCapabilityRow(
              '정확 시각 예약',
              capabilities.exactAlarmPermissionRequired
                  ? (capabilities.exactAlarmPermissionGranted ? '허용' : '권한 필요')
                  : '해당 없음',
            ),
            _buildCapabilityRow(
              '백그라운드 one-shot',
              capabilities.supportsScheduledNotifications ? '지원' : '미지원',
            ),
            if (capabilities.notes.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(capabilities.notes),
            ],
            if (capabilities.canOpenExactAlarmSettings &&
                !capabilities.exactAlarmPermissionGranted) ...<Widget>[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _controller.openExactAlarmSettings,
                child: const Text('정확 알람 권한 설정 열기'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSleepTime({
    required LocalAlarmTime initialValue,
    required ValueChanged<LocalAlarmTime> onSelected,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialValue.toTimeOfDay(),
    );
    if (picked == null) {
      return;
    }
    onSelected(LocalAlarmTime.fromTimeOfDay(picked));
  }

  void _maybePresentAlarmDialog() {
    final ScheduledAlarm? activeAlarm = _controller.activeAlarm;
    if (activeAlarm == null || activeAlarm.id == _presentedAlarmId) {
      return;
    }

    _presentedAlarmId = activeAlarm.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await widget.presentationFeedback.play();
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('알림 도달'),
            content: Text(
              '${_dateFormat.format(activeAlarm.finalFireTime)} 알림입니다.',
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  await _controller.acknowledgeActiveAlarm();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('확인/중지'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }
      _presentedAlarmId = null;
    });
  }

  String _statusLabel(AlarmLifecycleStatus status) {
    switch (status) {
      case AlarmLifecycleStatus.idle:
        return 'Idle';
      case AlarmLifecycleStatus.armed:
        return 'Armed';
      case AlarmLifecycleStatus.ringing:
        return 'Ringing';
      case AlarmLifecycleStatus.consumed:
        return 'Consumed';
      case AlarmLifecycleStatus.stopped:
        return 'Stopped';
    }
  }

  Color _statusColor(AlarmLifecycleStatus status) {
    switch (status) {
      case AlarmLifecycleStatus.idle:
        return const Color(0xFF7A746C);
      case AlarmLifecycleStatus.armed:
        return const Color(0xFF176E52);
      case AlarmLifecycleStatus.ringing:
        return const Color(0xFFB5542F);
      case AlarmLifecycleStatus.consumed:
        return const Color(0xFF5F4CC5);
      case AlarmLifecycleStatus.stopped:
        return const Color(0xFF8A2E2E);
    }
  }
}
