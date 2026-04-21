import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import '../core/constants.dart';
import 'web_notification_service.dart'
    if (dart.library.io) 'web_notification_service_stub.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal({
    FlutterLocalNotificationsPlugin? plugin,
    bool? isWebOverride,
    bool? isAndroidOverride,
    bool? isIOSOverride,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _isWebOverride = isWebOverride,
       _isAndroidOverride = isAndroidOverride,
       _isIOSOverride = isIOSOverride;

  @visibleForTesting
  NotificationService.test({
    FlutterLocalNotificationsPlugin? plugin,
    bool? isWebOverride,
    bool? isAndroidOverride,
    bool? isIOSOverride,
  }) : this._internal(
         plugin: plugin,
         isWebOverride: isWebOverride,
         isAndroidOverride: isAndroidOverride,
         isIOSOverride: isIOSOverride,
       );

  static const String _alarmChannelId = 'task_tracker_alarm_v1';
  static const String _alarmChannelName = 'Task reminders';
  static const String _alarmChannelDescription =
      'Task Tracker reminder notifications with sound';
  static const String _androidNotificationIcon = 'ic_notification_task';
  static const String _androidPackageName = 'com.tasktracker.task_tracker';

  final FlutterLocalNotificationsPlugin _plugin;
  final bool? _isWebOverride;
  final bool? _isAndroidOverride;
  final bool? _isIOSOverride;
  bool _isInitialized = false;

  void _log(String stage, String message) {
    debugPrint('[NotificationService][$stage] $message');
  }

  void _logError(String stage, Object error, [StackTrace? stackTrace]) {
    debugPrint('[NotificationService][$stage][ERROR] $error');
    if (stackTrace != null) {
      debugPrint('$stackTrace');
    }
  }

  bool get _isXiaomi {
    if (_isWeb || !_isAndroid) return false;
    final os = Platform.operatingSystemVersion.toLowerCase();
    return os.contains('miui') ||
        os.contains('xiaomi') ||
        os.contains('redmi') ||
        os.contains('poco');
  }

  bool get _isWeb => _isWebOverride ?? kIsWeb;
  bool get _isAndroid => _isAndroidOverride ?? (!_isWeb && Platform.isAndroid);
  bool get _isIOS => _isIOSOverride ?? (!_isWeb && Platform.isIOS);

  @visibleForTesting
  String get alarmChannelId => _alarmChannelId;

  @visibleForTesting
  AndroidNotificationChannel buildAlarmChannel() {
    return const AndroidNotificationChannel(
      _alarmChannelId,
      _alarmChannelName,
      description: _alarmChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      _log('init', 'skip, already initialized');
      return;
    }
    _log('init', 'start');

    // Веб не поддерживает timezone
    if (!_isWeb) {
      _log('init-timezone', 'initialize time zones');
      tz_data.initializeTimeZones();
      await _configureLocalTimezone();
    }

    if (_isWeb) {
      // Веб: используем Web Notifications API
      _log('init-platform', 'web initialization');
      await _initializeWeb();
    } else if (_isAndroid) {
      // Android: используем локальные уведомления
      _log('init-platform', 'android initialization');
      await _initializeAndroid();
    } else if (_isIOS) {
      // iOS: используем локальные уведомления
      _log('init-platform', 'ios initialization');
      await _initializeIOS();
    }

    _isInitialized = true;
    _log('init', 'completed');
  }

  Future<void> _initializeWeb() async {
    // Для веба используем нативный Web Notifications API
    if (_isWeb) {
      _log('web-init', 'initialize WebNotificationService');
      final webService = WebNotificationService();
      await webService.initialize();
      _log('web-init', 'completed');
    }
  }

  Future<void> _initializeAndroid() async {
    _log('android-init', 'start');
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification_task',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    _log('android-init', 'plugin initialized');

    await _createAndroidNotificationChannels();

    // Запрашиваем разрешение на уведомления для Android 13+
    await _requestNotificationPermission();

    // Запрашиваем разрешение на точные будильники для Android 12+
    await _requestExactAlarmPermission();
    _log('android-init', 'completed');
  }

  Future<void> _createAndroidNotificationChannels() async {
    _log('android-channel', 'create/update channel $_alarmChannelId');
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      _log('android-channel', 'android plugin unavailable, skip');
      return;
    }
    await androidPlugin.createNotificationChannel(buildAlarmChannel());
    _log('android-channel', 'channel ready');
  }

  Future<void> _requestNotificationPermission() async {
    if (_isAndroid) {
      _log('permission-notification', 'request start');
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _log('permission-notification', 'request completed');
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    if (_isAndroid) {
      try {
        _log('permission-exact-alarm', 'check start');
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidPlugin != null) {
          final canScheduleExactAlarms = await androidPlugin
              .canScheduleExactNotifications();
          _log(
            'permission-exact-alarm',
            'canScheduleExactNotifications=$canScheduleExactAlarms',
          );

          if (canScheduleExactAlarms == false) {
            _log('permission-exact-alarm', 'request exact alarm permission');
            final granted = await androidPlugin.requestExactAlarmsPermission();
            _log('permission-exact-alarm', 'request result: $granted');
          }
        } else {
          _log('permission-exact-alarm', 'android plugin unavailable');
        }
      } catch (e) {
        _logError('permission-exact-alarm', e);
      }
    }
  }

  Future<void> _initializeIOS() async {
    _log('ios-init', 'start');
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
    _log('ios-init', 'completed');
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(timezoneInfo.identifier);
      tz.setLocalLocation(location);
      _log('init-timezone', 'local timezone set to ${timezoneInfo.identifier}');
    } catch (e) {
      _logError('init-timezone', e);
      _log('init-timezone', 'fallback to ${tz.local.name}');
    }
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
      _log('schedule', 'service not initialized, init before schedule');
      await initialize();
    }
    _log(
      'schedule',
      'start id=$id at=$scheduledDate isUtc=${scheduledDate.isUtc}',
    );

    // Проверяем, включены ли уведомления
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      _log('schedule', 'notifications disabled, skip');
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
      _log('schedule', 'date in past ($checkDate), now=$now, skip');
      return;
    }

    try {
      if (_isWeb) {
        // Веб: используем браузерные уведомления (Windows notifications)
        await _scheduleWebNotification(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          payload: payload,
        );
      } else if (_isAndroid || _isIOS) {
        // Мобильные: используем локальные уведомления с будильником
        await _scheduleMobileNotification(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          payload: payload,
        );
      }
      _log('schedule', 'completed id=$id');
    } catch (e) {
      _logError('schedule', e);
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
    _log('schedule-web', 'start id=$id at=$scheduledDate');
    final webService = WebNotificationService();
    await webService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
    _log('schedule-web', 'completed id=$id');
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

    _log('schedule-mobile', 'timezone=${now.timeZoneName}');
    _log(
      'schedule-mobile',
      'converted date: original=$scheduledDate -> tz=$tzScheduledDate',
    );

    if (_isAndroid) {
      // Android: используем будильник (exactAllowWhileIdle)
      const androidDetails = AndroidNotificationDetails(
        _alarmChannelId,
        _alarmChannelName,
        channelDescription: _alarmChannelDescription,
        icon: _androidNotificationIcon,
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
        channelShowBadge: true,
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
      _log('schedule-android', 'zonedSchedule completed id=$id');
    } else if (_isIOS) {
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
      _log('schedule-ios', 'zonedSchedule completed id=$id');
    }
  }

  @visibleForTesting
  NotificationDetails buildAndroidNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _alarmChannelId,
      _alarmChannelName,
      channelDescription: _alarmChannelDescription,
      icon: _androidNotificationIcon,
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
      channelShowBadge: true,
    );
    return const NotificationDetails(android: androidDetails);
  }

  Future<void> cancelNotification(int id) async {
    _log('cancel', 'start id=$id');
    await _plugin.cancel(id);
    _log('cancel', 'completed id=$id');
  }

  Future<void> cancelAllNotifications() async {
    _log('cancel-all', 'start');
    await _plugin.cancelAll();
    _log('cancel-all', 'completed');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    _log('pending', 'load pending notifications');
    final pending = await _plugin.pendingNotificationRequests();
    _log('pending', 'loaded count=${pending.length}');
    return pending;
  }

  Future<void> markNotificationsScheduled() async {
    _log('prefs', 'mark notifications scheduled=true');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyNotificationsScheduled, true);
  }

  Future<bool> areNotificationsScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyNotificationsScheduled) ?? false;
  }

  Future<void> clearNotificationsScheduledFlag() async {
    _log('prefs', 'clear notifications scheduled flag');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyNotificationsScheduled);
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? true;
    _log('prefs', 'notifications_enabled=$enabled');
    return enabled;
  }

  // Получить информацию о платформе
  String getPlatformInfo() {
    if (_isWeb) {
      return 'Web (Windows Notifications)';
    } else if (_isAndroid) {
      return 'Android (Alarm)';
    } else if (_isIOS) {
      return 'iOS (Local Notification)';
    }
    return 'Unknown';
  }

  // Проверить, есть ли разрешение на точные будильники (Android)
  Future<bool?> hasExactAlarmPermission() async {
    if (_isWeb) return null;
    if (_isAndroid) {
      try {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin != null) {
          return await androidPlugin.canScheduleExactNotifications();
        }
      } catch (e) {
        _logError('permission-exact-alarm-check', e);
      }
    }
    return null;
  }

  // Запросить разрешение на точные будильники (Android)
  Future<bool?> requestExactAlarmPermission() async {
    if (_isWeb) return null;
    if (_isAndroid) {
      try {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestExactAlarmsPermission();
          _log('permission-exact-alarm-request', 'result=$granted');
          return granted;
        }
      } catch (e) {
        _logError('permission-exact-alarm-request', e);
      }
    }
    return null;
  }

  // Показать диалог с инструкцией по включению точных будильников
  Future<void> showExactAlarmPermissionDialog(BuildContext context) async {
    if (!_isWeb && _isAndroid) {
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
    if (!_isWeb && _isAndroid) {
      final attempts = <AndroidIntent>[
        const AndroidIntent(
          action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
          data: 'package:$_androidPackageName',
        ),
        const AndroidIntent(
          action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        ),
        const AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:$_androidPackageName',
        ),
      ];

      for (final intent in attempts) {
        try {
          _log(
            'battery-settings',
            'try action=${intent.action} component=${intent.componentName}',
          );
          await intent.launch();
          _log('battery-settings', 'opened');
          return;
        } catch (e) {
          _logError('battery-settings', e);
        }
      }
      _log('battery-settings', 'all intents failed');
    }
  }

  Future<void> openXiaomiAutostartSettings() async {
    if (!_isWeb && _isAndroid) {
      _log(
        'xiaomi-autostart',
        'device info: isXiaomi=$_isXiaomi os=${Platform.operatingSystemVersion}',
      );
      final attempts = <AndroidIntent>[
        const AndroidIntent(
          action: 'miui.intent.action.APP_PERM_EDITOR',
          componentName:
              'com.miui.securitycenter/com.miui.permcenter.permissions.PermissionsEditorActivity',
          arguments: <String, dynamic>{'extra_pkgname': _androidPackageName},
        ),
        const AndroidIntent(
          action: 'miui.intent.action.APP_PERM_EDITOR',
          componentName:
              'com.miui.securitycenter/com.miui.permcenter.permissions.AppPermissionsEditorActivity',
          arguments: <String, dynamic>{'extra_pkgname': _androidPackageName},
        ),
        const AndroidIntent(
          componentName:
              'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
        ),
        const AndroidIntent(
          componentName:
              'com.miui.securitycenter/com.miui.appmanager.ApplicationsDetailsActivity',
          arguments: <String, dynamic>{'package_name': _androidPackageName},
        ),
        const AndroidIntent(
          componentName:
              'com.miui.powerkeeper/com.miui.powerkeeper.ui.HiddenAppsConfigActivity',
          arguments: <String, dynamic>{
            'package_name': _androidPackageName,
            'package_label': 'Task Tracker',
          },
        ),
        const AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:$_androidPackageName',
        ),
      ];

      for (final intent in attempts) {
        try {
          _log('xiaomi-autostart', 'try open ${intent.componentName}');
          await intent.launch();
          _log('xiaomi-autostart', 'opened');
          return;
        } catch (e) {
          _logError('xiaomi-autostart', e);
        }
      }
      _log('xiaomi-autostart', 'all intents failed');
    }
  }

  // Показать диалог с инструкцией по отключению оптимизации батареи
  Future<void> showBatteryOptimizationDialog(BuildContext context) async {
    if (!_isWeb && _isAndroid) {
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
            '3. Найдите "Task Tracker" и выберите "Не оптимизировать"\n\n'
            'Для Xiaomi/Redmi/Poco дополнительно включите "Автозапуск" '
            'в приложении Безопасность.',
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
                await Future.delayed(const Duration(milliseconds: 300));
                await openXiaomiAutostartSettings();
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
    if (!_isWeb && _isAndroid) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Настройка уведомлений'),
          content: const Text(
            'Для надёжной работы напоминаний нужно выполнить два шага:\n\n'
            '1️⃣ Включить "Точные будильники"\n'
            '2️⃣ Отключить оптимизацию батареи\n\n'
            'Для Xiaomi/Redmi/Poco также включите "Автозапуск".\n\n'
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
                await Future.delayed(const Duration(milliseconds: 300));
                await openXiaomiAutostartSettings();
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
