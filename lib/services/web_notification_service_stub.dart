// Заглушка для не-веб платформ
class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  Future<void> initialize() async {}

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {}

  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {}

  void cancelNotification(int id) {}
  void cancelAllNotifications() {}
  
  bool get hasPermission => false;
  int get scheduledCount => 0;
}
