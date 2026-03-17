import '../models/alarm_session.dart';

abstract class AlarmSessionRepository {
  Future<AlarmSession> load();

  Future<void> save(AlarmSession session);

  Future<void> clear();
}
