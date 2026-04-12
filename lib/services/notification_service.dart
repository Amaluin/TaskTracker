import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import '../core/constants.dart';
import 'web_notification_service.dart' if (dart.library.io) 'web_notification_service_stub.dart';

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
    // Для веба используем нативный Web Notifications API
    if (kIsWeb) {
      final webService = WebNotificationService();
      await webService.initialize();
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

    // Запрашиваем разрешение на уведомления для Android 13+
    await _requestNotificationPermission();

    // Запрашиваем разрешение на точные будильники для Android 12+
    await _requestExactAlarmPermission();
  }

  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          final canScheduleExactAlarms = await androidPlugin.canScheduleExactNotifications();

          if (canScheduleExactAlarms == false) {
            print('⚠️ Разрешение на точные будильники не предоставлено, запрашиваем...');
            final granted = await androidPlugin.requestExactAlarmsPermission();
            if (granted == true) {
              print('✅ Разрешение на точные будильники получено');
            } else {
              print('⚠️ Пользователь не предоставил разрешение на точные будильники');
            }
          } else {
            print('✅ Разрешение на точные будильники уже есть');
          }
        }
      } catch (e) {
        print('❌ Ошибка при запросе разрешения на точные будильники: $e');
      }
    }
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
    if (!_isInitialized) {
      print('⚠️ Notification service not initialized, attempting to initialize...');
      await initialize();
    }

    // Проверяем, включены ли уведомления
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      print('🔕 Notifications are disabled, skipping scheduling');
      return;
    }

    // Проверяем, что дата в будущем
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime checkDate;
    if (scheduledDate.isUtc) {
      checkDate = tz.TZDateTime.from(scheduledDate, tz.local);
    } else {
      checkDate = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
      );
    }
    
    if (checkDate.isBefore(now)) {
      print('⚠️ Scheduled date is in the past: $checkDate (now: $now), skipping');
      return;
    }

    try {
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
      print('✅ Notification scheduled successfully for $scheduledDate');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
      // Не пробрасываем ошибку, чтобы не ломать основной функционал
    }
  }

  Future<void> _scheduleWebNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Используем нативный Web Notifications API
    final webService = WebNotificationService();
    await webService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
  }

  Future<void> _scheduleMobileNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Получаем часовой пояс устройства
    final now = tz.TZDateTime.now(tz.local);
    
    // Конвертируем запланированное время в правильный часовой пояс
    // Если scheduledDate это local time без timezone info, нужно его правильно интерпретировать
    tz.TZDateTime tzScheduledDate;
    if (scheduledDate.isUtc) {
      tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    } else {
      // Это локальное время - создаём TZDateTime с теми же компонентами
      tzScheduledDate = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
        scheduledDate.second,
        scheduledDate.millisecond,
        scheduledDate.microsecond,
      );
    }

    print('🕐 Timezone: ${now.timeZoneName}');
    print('📅 Scheduled (original): $scheduledDate (isUtc: ${scheduledDate.isUtc})');
    print('📅 Scheduled (tz): $tzScheduledDate');

    if (Platform.isAndroid) {
      // Android: используем будильник (exactAllowWhileIdle)
      const androidDetails = AndroidNotificationDetails(
        'task_tracker_channel',
        'Task Tracker',
        channelDescription: 'Напоминания о задачах',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true, // Показывать как будильник
        category: AndroidNotificationCategory.alarm,
      );

      const details = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
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
        tzScheduledDate,
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

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
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

  // Проверить, есть ли разрешение на точные будильники (Android)
  Future<bool?> hasExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          return await androidPlugin.canScheduleExactNotifications();
        }
      } catch (e) {
        print('❌ Error checking exact alarm permission: $e');
      }
    }
    return null;
  }

  // Запросить разрешение на точные будильники (Android)
  Future<bool?> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestExactAlarmsPermission();
          print('✅ Exact alarm permission result: $granted');
          return granted;
        }
      } catch (e) {
        print('❌ Error requesting exact alarm permission: $e');
      }
    }
    return null;
  }

  // Показать диалог с инструкцией по включению точных будильников
  Future<void> showExactAlarmPermissionDialog(BuildContext context) async {
    if (!kIsWeb && Platform.isAndroid) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Важно: разрешение на будильники'),
          content: const Text(
            'Для работы напоминаний в свёрнутом приложении необходимо '
            'включить разрешение "Точные будильники".\n\n'
            'Без этого напоминания могут не срабатывать, когда приложение '
            'закрыто или телефон в режиме сна.\n\n'
            'Нажмите "Включить" и переключите тумблер в положение ВКЛ.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Позже'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await requestExactAlarmPermission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Включить'),
            ),
          ],
        ),
      );
    }
  }

  // Открыть настройки оптимизации батареи для Android
  Future<void> openBatteryOptimizationSettings() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
          package: 'android',
        );
        await intent.launch();
      } catch (e) {
        print('❌ Ошибка при открытии настроек батареи: $e');
        // Fallback — открываем общие настройки приложения
        try {
          final intent = AndroidIntent(
            action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
            data: 'package:com.example.task_tracker',
          );
          await intent.launch();
        } catch (e2) {
          print('❌ Ошибка при открытии настроек приложения: $e2');
        }
      }
    }
  }

  // Показать диалог с инструкцией по отключению оптимизации батареи
  Future<void> showBatteryOptimizationDialog(BuildContext context) async {
    if (!kIsWeb && Platform.isAndroid) {
      return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          title: const Text('Важно: оптимизация батареи'),
          content: const Text(
            'Система может останавливать приложение для экономии батареи. '
            'Из-за этого напоминания могут не срабатывать.\n\n'
            'Пожалуйста, отключите оптимизацию батареи для этого приложения:\n\n'
            '1. Нажмите "Отключить"\n'
            '2. Выберите "Все приложения" или "Не оптимизировать"\n'
            '3. Найдите "Task Tracker" и выберите "Не оптимизировать"',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Позже'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await openBatteryOptimizationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Отключить'),
            ),
          ],
        ),
      );
    }
  }

  // Показать полный диалог с проверкой всех разрешений
  Future<void> showAllPermissionsDialog(BuildContext context) async {
    if (!kIsWeb && Platform.isAndroid) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Настройка уведомлений'),
          content: const Text(
            'Для надёжной работы напоминаний нужно выполнить два шага:\n\n'
            '1️⃣ Включить "Точные будильники"\n'
            '2️⃣ Отключить оптимизацию батареи\n\n'
            'Без этого напоминания могут не срабатывать, когда приложение закрыто.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Позже'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                // Сначала точные будильники
                await requestExactAlarmPermission();
                // Потом оптимизация батареи
                await Future.delayed(const Duration(milliseconds: 500));
                await openBatteryOptimizationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Настроить'),
            ),
          ],
        ),
      );
    }
  }
}
