import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/services/notification_service.dart';

void main() {
  group('NotificationService Android config', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService.test(
        isWebOverride: false,
        isAndroidOverride: true,
        isIOSOverride: false,
      );
    });

    test('buildAlarmChannel configures sound notifications', () {
      final channel = service.buildAlarmChannel();

      expect(channel.id, equals(service.alarmChannelId));
      expect(channel.importance, equals(Importance.max));
      expect(channel.playSound, isTrue);
      expect(channel.enableVibration, isTrue);
      expect(channel.showBadge, isTrue);
    });

    test('buildAndroidNotificationDetails keeps alarm channel settings', () {
      final details = service.buildAndroidNotificationDetails();
      final android = details.android;

      expect(android, isNotNull);
      expect(android!.channelId, equals(service.alarmChannelId));
      expect(android.importance, equals(Importance.max));
      expect(android.priority, equals(Priority.high));
      expect(android.playSound, isTrue);
      expect(android.enableVibration, isTrue);
      expect(android.category, equals(AndroidNotificationCategory.reminder));
    });
  });
}
