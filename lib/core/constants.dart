import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Планировщик задач';

  // Supabase credentials
  // ВАЖНО: Получите Anon Key из Supabase Studio (https://studio.bike53.ru)
  // Settings → API → anon key
  static const String supabaseUrl = 'https://api.bike53.ru';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc1NDIyODAwLCJleHAiOjE5MzMxODkyMDB9.9Hsb4zE3uIMR3sXjAPVqdx82-ewpdw2eJTDxE1D_z0Q'; // Замените на ваш Anon Key из Studio

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

// Цвета для статусов
Color getStatusColor(String status) {
  switch (status) {
    case AppConstants.statusPending:
      return const Color(0xFFF59E0B); // Amber - янтарный
    case AppConstants.statusAccepted:
      return const Color(0xFF10B981); // Green - зеленый (в работе)
    case AppConstants.statusPostponed:
      return const Color(0xFF8B5CF6); // Purple - фиолетовый
    case AppConstants.statusArchived:
      return const Color(0xFF6B7280); // Gray - серый
    default:
      return const Color(0xFF9CA3AF);
  }
}

// Фоновые цвета для статусов (более светлые)
Color getStatusBackgroundColor(String status) {
  switch (status) {
    case AppConstants.statusPending:
      return const Color(0xFFFFFBEB); // Very Light Amber
    case AppConstants.statusAccepted:
      return const Color(0xFFECFDF5); // Very Light Green
    case AppConstants.statusPostponed:
      return const Color(0xFFF5F3FF); // Very Light Purple
    case AppConstants.statusArchived:
      return const Color(0xFFFAFAFA); // Very Light Gray
    default:
      return const Color(0xFFFDFDFD);
  }
}
