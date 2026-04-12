import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _userName = '';
  String _userPhone = '';
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool? _exactAlarmPermission;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadNotificationSettings();
    _checkExactAlarmPermission();
  }

  Future<void> _checkExactAlarmPermission() async {
    try {
      final hasPermission = await NotificationService().hasExactAlarmPermission();
      if (mounted) {
        setState(() {
          _exactAlarmPermission = hasPermission;
        });
      }
    } catch (e) {
      // Игнорируем ошибки проверки разрешений
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Получаем данные из метаданных пользователя
        final metadata = user.userMetadata;
        final phone = metadata?['phone'] as String? ?? '';
        final name = metadata?['display_name'] as String? ?? 
                     metadata?['name'] as String? ?? 
                     'Пользователь';
        
        if (mounted) {
          setState(() {
            _userName = name;
            _userPhone = phone;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notifications_enabled') ?? true;
      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled;
        });
      }
    } catch (e) {
      // Игнорируем ошибки загрузки настроек
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);

      if (!value) {
        // Если отключаем уведомления, отменяем все запланированные
        await NotificationService().cancelAllNotifications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Все напоминания отменены'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Напоминания включены'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        // Откатываем изменение
        setState(() {
          _notificationsEnabled = !value;
        });
      }
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    try {
      final granted = await NotificationService().requestExactAlarmPermission();
      if (mounted) {
        setState(() {
          _exactAlarmPermission = granted;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                granted == true
                    ? 'Разрешение на точные будильники предоставлено'
                    : granted == false
                        ? 'Разрешение на точные будильники отклонено'
                        : 'Проверьте разрешения в настройках приложения',
              ),
              backgroundColor: granted == true
                  ? Colors.green
                  : granted == false
                      ? Colors.orange
                      : Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      // Навигация обрабатывается автоматически через EntryWrapper
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 48,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userName.isEmpty ? 'Пользователь' : _userName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_userPhone.isNotEmpty)
                        Text(
                          _userPhone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Выйти'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Уведомления',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _notificationsEnabled
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                            color: _notificationsEnabled ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: const Text('Напоминания о задачах'),
                        subtitle: Text(
                          _notificationsEnabled
                              ? 'Вы будете получать уведомления'
                              : 'Уведомления отключены',
                        ),
                        activeColor: const Color(0xFF6366F1),
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _exactAlarmPermission == true
                                ? Colors.green.withValues(alpha: 0.1)
                                : _exactAlarmPermission == false
                                    ? Colors.orange.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _exactAlarmPermission == true
                                ? Icons.alarm_on
                                : _exactAlarmPermission == false
                                    ? Icons.alarm_off
                                    : Icons.alarm,
                            color: _exactAlarmPermission == true
                                ? Colors.green
                                : _exactAlarmPermission == false
                                    ? Colors.orange
                                    : Colors.grey,
                          ),
                        ),
                        title: const Text('Точные будильники'),
                        subtitle: Text(
                          _exactAlarmPermission == true
                              ? 'Разрешение предоставлено'
                              : _exactAlarmPermission == false
                                  ? 'Требуется разрешение'
                                  : 'Нажмите для проверки',
                        ),
                        trailing: _exactAlarmPermission == true
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: _exactAlarmPermission != true
                            ? _requestExactAlarmPermission
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'О приложении',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info, color: Color(0xFF6366F1)),
                        ),
                        title: const Text('Версия'),
                        subtitle: const Text('1.0.0'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
