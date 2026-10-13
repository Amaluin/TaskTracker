# TaskTracker

Кроссплатформенный трекер задач на Flutter с бэкендом Supabase. Работает на Android и в вебе, интерфейс полностью на русском.

## Возможности

- Регистрация и вход, ввод имени пользователя
- Создание задач, детальная карточка, смена статуса
- Назначение ответственного; кнопка «Принять задачу» переводит задачу в «В работе» и ставит напоминание за 1 час до срока
- Отложение задачи на выбранные дату и время (русский календарь, iOS-барабаны времени)
- Локальные уведомления и напоминания, восстановление напоминаний после перезапуска
- Адаптивный интерфейс:
  - мобильная версия: список карточек
  - веб (шире 900px): Kanban-доска с 4 колонками и Drag & Drop между статусами
- Статусы: В ожидании, В работе, Отложено, В архиве; история смены статусов
- Дизайн в стиле глассморфизм, основной цвет индиго `#6366F1`

Подробнее: [FEATURES.md](FEATURES.md), [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md).

## Стек

- Flutter (Dart SDK ^3.11.4)
- Supabase (`supabase_flutter`) — БД и авторизация
- Riverpod (`flutter_riverpod`) — состояние
- `flutter_local_notifications`, `timezone`, `flutter_timezone` — уведомления
- `intl`, `flutter_localizations` — локализация

## Структура

```
lib/
  core/          константы, адаптивные размеры
  data/
    models/      модели задач, пользователей, напоминаний, истории статусов
    repositories/ работа с Supabase
  providers/     Riverpod-провайдеры
  screens/       auth, tasks, reminders, settings
  services/      уведомления, восстановление напоминаний
  widgets/       карточки, Kanban-колонки, диалоги
  main.dart
```

## Запуск

```bash
flutter pub get
flutter run            # Android / эмулятор
flutter run -d chrome  # веб
```

Сборка:

```bash
flutter build apk --release
flutter build web
```

## База данных

SQL-файлы в корне репозитория:

| Файл | Назначение |
|------|-----------|
| `database_schema.sql` | базовая схема |
| `database_migration.sql` | миграция (ответственный, отложение) |
| `database_security.sql` | политики безопасности (RLS) |
| `database_queries.sql` | полезные запросы |

Порядок: схема, затем миграция, затем политики безопасности. Подробности в [DATABASE_SETUP.md](DATABASE_SETUP.md).

## Supabase self-hosted

Для собственного развёртывания Supabase есть `docker-compose.supabase.yml`, `kong.yml`, `nginx-supabase.conf`, `setup-supabase.sh`, `generate-jwt.sh`. См. [SUPABASE_README.md](SUPABASE_README.md) и [SUPABASE_NGINX_SETUP.md](SUPABASE_NGINX_SETUP.md).

## Конфигурация

Параметры подключения к Supabase задаются в `lib/core/constants.dart`. Не коммитьте реальные ключи и `.env`; шаблон — `.env.example`.
