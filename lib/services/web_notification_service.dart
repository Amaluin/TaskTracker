import 'dart:html' as html;
import 'dart:async';

class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  bool _isInitialized = false;
  bool _permissionGranted = false;
  final Map<int, Timer> _scheduledNotifications = {};

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Проверяем поддержку уведомлений
    if (!html.Notification.supported) {
      print('❌ Браузер не поддерживает уведомления');
      return;
    }

    // Запрашиваем разрешение
    final permission = html.Notification.permission;
    
    if (permission == 'granted') {
      _permissionGranted = true;
      print('✅ Разрешение на уведомления уже получено');
    } else if (permission == 'default') {
      // Запрашиваем разрешение
      final result = await html.Notification.requestPermission();
      _permissionGranted = (result == 'granted');
      
      if (_permissionGranted) {
        print('✅ Разрешение на уведомления получено');
      } else {
        print('❌ Разрешение на уведомления отклонено');
      }
    } else {
      print('❌ Разрешение на уведомления отклонено ранее');
    }

    _isInitialized = true;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_isInitialized) await initialize();

    if (!_permissionGranted) {
      print('❌ Нет разрешения на уведомления');
      return;
    }

    // Отменяем предыдущее уведомление с таким же ID
    cancelNotification(id);

    // Вычисляем задержку
    final delay = scheduledDate.difference(DateTime.now());

    if (delay.isNegative) {
      // Если время уже прошло, показываем сразу
      _showNotification(title, body);
    } else {
      // Планируем уведомление
      final timer = Timer(delay, () {
        _showNotification(title, body);
        _scheduledNotifications.remove(id);
      });

      _scheduledNotifications[id] = timer;
      print('📅 Уведомление запланировано на ${scheduledDate.toString()}');
    }
  }

  void _showNotification(String title, String body) {
    try {
      final notification = html.Notification(
        title,
        body: body,
        icon: '/favicon.png',
        tag: 'task-tracker',
      );

      // Автоматически закрыть через 10 секунд
      Timer(const Duration(seconds: 10), () {
        notification.close();
      });

      print('🔔 Уведомление показано: $title');
    } catch (e) {
      print('❌ Ошибка показа уведомления: $e');
    }
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    if (!_permissionGranted) {
      print('❌ Нет разрешения на уведомления');
      return;
    }

    _showNotification(title, body);
  }

  void cancelNotification(int id) {
    final timer = _scheduledNotifications[id];
    if (timer != null) {
      timer.cancel();
      _scheduledNotifications.remove(id);
      print('🗑️ Уведомление $id отменено');
    }
  }

  void cancelAllNotifications() {
    for (final timer in _scheduledNotifications.values) {
      timer.cancel();
    }
    _scheduledNotifications.clear();
    print('🗑️ Все уведомления отменены');
  }

  bool get hasPermission => _permissionGranted;
  
  int get scheduledCount => _scheduledNotifications.length;
}
