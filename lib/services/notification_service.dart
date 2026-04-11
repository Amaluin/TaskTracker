import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import '../core/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Веб не поддерживает timezone
    if (!kIsWeb) {
      tz_data.initializeTimeZones();
    }

    if (kIsWeb) {
      // Веб: используем Web Notifications API
      await _initializeWeb();
    } else if (Platform.isAndroid) {
      // Android: используем локальные уведомления
      await _initializeAndroid();
    } else if (Platform.isIOS) {
      // iOS: используем локальные уведомления
      await _initializeIOS();
    }

    _isInitialized = true;
  }

  Future<void> _initializeWeb() async {
    // Для веба используем браузерные уведомления
    // Проверяем поддержку
    if (kIsWeb) {
      // Web notifications будут работать через flutter_local_notifications
      const initSettings = InitializationSettings(
        linux: LinuxInitializationSettings(
          defaultActionName: 'Open notification',
        ),
      );
      
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
    }
  }

  Future<void> _initializeAndroid() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  Future<void> _initializeIOS() async {
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(iOS: iosSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  static void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap actions
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    if (kIsWeb) {
      // Веб: используем браузерные уведомления (Windows notifications)
      await _scheduleWebNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
      );
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Мобильные: используем локальные уведомления с будильником
      await _scheduleMobileNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
      );
    }
  }

  Future<void> _scheduleWebNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Для веба используем простые уведомления без timezone
    // Браузер сам покажет системное уведомление Windows
    final details = const NotificationDetails(
      linux: LinuxNotificationDetails(),
    );

    // Вычисляем задержку до времени уведомления
    final delay = scheduledDate.difference(DateTime.now());
    
    if (delay.isNegative) {
      // Если время уже прошло, показываем сразу
      await _plugin.show(id, title, body, details, payload: payload);
    } else {
      // Планируем уведомление через задержку
      // Для веба используем простой таймер через show с задержкой
      await Future.delayed(delay, () async {
        await _plugin.show(id, title, body, details, payload: payload);
      });
    }
  }

  Future<void> _scheduleMobileNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (Platform.isAndroid) {
      // Android: используем будильник (exactAllowWhileIdle)
      final androidDetails = AndroidNotificationDetails(
        'task_tracker_channel',
        'Task Tracker',
        channelDescription: 'Напоминания о задачах',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification'),
        fullScreenIntent: true, // Показывать как будильник
        category: AndroidNotificationCategory.alarm,
      );

      final details = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else if (Platform.isIOS) {
      // iOS: используем локальные уведомления с звуком
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const details = NotificationDetails(iOS: iosDetails);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }

  Future<void> markNotificationsScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyNotificationsScheduled, true);
  }

  Future<bool> areNotificationsScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyNotificationsScheduled) ?? false;
  }

  Future<void> clearNotificationsScheduledFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyNotificationsScheduled);
  }

  // Получить информацию о платформе
  String getPlatformInfo() {
    if (kIsWeb) {
      return 'Web (Windows Notifications)';
    } else if (Platform.isAndroid) {
      return 'Android (Alarm)';
    } else if (Platform.isIOS) {
      return 'iOS (Local Notification)';
    }
    return 'Unknown';
  }
}
