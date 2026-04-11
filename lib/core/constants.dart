class AppConstants {
  static const String appName = 'Планировщик задач';

  // Supabase credentials
  // ВАЖНО: Получите Anon Key из Supabase Studio (https://studio.bike53.ru)
  // Settings → API → anon key
  static const String supabaseUrl = 'https://api.bike53.ru';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'; // Замените на ваш Anon Key из Studio

  // Task statuses
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusPostponed = 'postponed';
  static const String statusArchived = 'archived';

  static const List<String> allStatuses = [
    statusPending,
    statusAccepted,
    statusPostponed,
    statusArchived,
  ];

  // Task priorities
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';

  static const List<String> allPriorities = [
    priorityLow,
    priorityMedium,
    priorityHigh,
  ];

  // Reminder types
  static const String reminderTypeNotification = 'notification';
  static const String reminderTypeAlarm = 'alarm';

  // Shared preferences keys
  static const String keyUserName = 'user_name';
  static const String keyUserId = 'user_id';
  static const String keyNotificationsScheduled = 'notifications_scheduled';
}

String getStatusDisplayName(String status) {
  switch (status) {
    case AppConstants.statusPending:
      return 'В ожидании';
    case AppConstants.statusAccepted:
      return 'В работе';
    case AppConstants.statusPostponed:
      return 'Отложено';
    case AppConstants.statusArchived:
      return 'В архиве';
    default:
      return status;
  }
}

String getPriorityDisplayName(String priority) {
  switch (priority) {
    case AppConstants.priorityLow:
      return 'Низкий';
    case AppConstants.priorityMedium:
      return 'Средний';
    case AppConstants.priorityHigh:
      return 'Высокий';
    default:
      return priority;
  }
}
