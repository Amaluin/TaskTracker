# Исправление ошибки "User not identified" при добавлении напоминаний

## Проблема
При попытке добавить напоминание к задаче возникала ошибка:
```
Ошибка: Exception: User not identified
```

## Причина
Приложение использовало два разных подхода к авторизации:
1. **Локальная авторизация** через `SharedPreferences` (UUID генерируется локально в `name_entry_screen.dart`)
2. **Supabase авторизация** через `Supabase.instance.client.auth.currentUser`

Проблема заключалась в том, что:
- `ReminderRepository` пытался получить `userId` из `SharedPreferences`
- Но если пользователь авторизован через Supabase, его ID в базе данных отличается от локального UUID
- Это приводило к тому, что напоминания не могли быть созданы, так как `user_id` не совпадал

## Решение
Унифицировали получение ID пользователя - теперь везде используется **Supabase auth**:

### 1. Обновлен `ReminderRepository`
**Файл:** `lib/data/repositories/reminder_repository.dart`

**Было:**
```dart
Future<String?> _getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(AppConstants.keyUserId);
}
```

**Стало:**
```dart
Future<String?> _getUserId() async {
  // Получаем ID из Supabase auth
  final user = _client.auth.currentUser;
  if (user != null) {
    return user.id;
  }
  return null;
}
```

### 2. Обновлен `ReminderScreen`
**Файл:** `lib/screens/reminders/reminder_screen.dart`

**Изменения:**
- Убран импорт `shared_preferences`
- Добавлен импорт `supabase_flutter`
- Метод `_addReminder()` теперь получает userId из `Supabase.instance.client.auth.currentUser`
- Добавлена обработка ошибок с понятными сообщениями
- `initState` теперь использует `WidgetsBinding.instance.addPostFrameCallback` для загрузки напоминаний

### 3. Обновлен `TaskDetailScreen`
**Файл:** `lib/screens/tasks/task_detail_screen.dart`

**Изменения:**
- Убран импорт `shared_preferences`
- Добавлен импорт `supabase_flutter`
- Методы `_acceptTask()` и `_postponeTask()` теперь получают userId из Supabase auth
- Добавлены проверки авторизации с понятными сообщениями об ошибках

### 4. Улучшены сообщения об ошибках
**Файл:** `lib/data/repositories/reminder_repository.dart`

**Было:**
```dart
if (userId == null) throw Exception('User not identified');
```

**Стало:**
```dart
if (userId == null || userId.isEmpty) {
  throw Exception('Пользователь не авторизован. Пожалуйста, войдите в систему.');
}
```

## Результат
✅ Напоминания теперь создаются корректно  
✅ Используется единый источник авторизации (Supabase)  
✅ Понятные сообщения об ошибках на русском языке  
✅ Правильная обработка случаев, когда пользователь не авторизован  

## Файлы, которые были изменены
1. `lib/data/repositories/reminder_repository.dart`
2. `lib/screens/reminders/reminder_screen.dart`
3. `lib/screens/tasks/task_detail_screen.dart`

## Примечание
Локальная авторизация через `SharedPreferences` в `name_entry_screen.dart` остается для обратной совместимости, но для работы с базой данных (задачи, напоминания) теперь используется только Supabase auth.
