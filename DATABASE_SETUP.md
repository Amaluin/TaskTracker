# 🗄️ Настройка базы данных Supabase

Пошаговая инструкция по настройке базы данных для Task Tracker.

---

## 📋 Содержание

1. [Обзор](#обзор)
2. [Файлы SQL](#файлы-sql)
3. [Применение схемы](#применение-схемы)
4. [Проверка](#проверка)
5. [Тестовые данные](#тестовые-данные)
6. [Полезные запросы](#полезные-запросы)

---

## 🎯 Обзор

### Структура базы данных:

**3 основные таблицы:**
- `tasks` - Задачи
- `task_reminders` - Напоминания
- `task_status_history` - История изменений статусов

**Дополнительно:**
- 20+ индексов для производительности
- 5 функций и триггеров
- 3 представления (views)
- 2 API функции
- Row Level Security (RLS) политики

---

## 📁 Файлы SQL

### 1. `database_schema.sql` (ОСНОВНОЙ)
**Назначение:** Создание полной схемы базы данных

**Содержит:**
- Создание таблиц
- Индексы
- Функции и триггеры
- RLS политики
- Представления
- API функции

**Когда применять:** При первоначальной настройке или полном пересоздании БД

### 2. `database_migration.sql` (УСТАРЕЛ)
**Назначение:** Миграция для добавления новых полей

**Содержит:**
- Добавление полей `assigned_to_user_id`, `assigned_to_user_name`, `postponed_until`

**Примечание:** Эти поля уже включены в `database_schema.sql`, поэтому этот файл нужен только если вы обновляете существующую БД

### 3. `database_queries.sql` (СПРАВОЧНИК)
**Назначение:** Полезные SQL запросы для работы с данными

**Содержит:**
- Запросы для просмотра данных
- Статистика и аналитика
- Поиск и фильтрация
- Обновление данных
- Удаление данных
- Обслуживание БД
- Тестовые данные

---

## 🚀 Применение схемы

### Шаг 1: Откройте Supabase Studio

```
https://studio.bike53.ru
```

Войдите в админ панель Supabase.

### Шаг 2: Перейдите в SQL Editor

1. В левом меню найдите **SQL Editor**
2. Нажмите **New query**

### Шаг 3: Скопируйте и выполните скрипт

1. Откройте файл `database_schema.sql` на вашем компьютере
2. Скопируйте **весь** содержимое файла
3. Вставьте в SQL Editor
4. Нажмите **Run** (или Ctrl+Enter)

### Шаг 4: Дождитесь выполнения

Скрипт выполнится за 5-10 секунд. В конце вы увидите сообщение:

```
============================================
Схема базы данных успешно создана!
============================================
Таблицы: 3
Индексы: 20+
Функции: 5
Представления: 3
============================================
```

---

## ✅ Проверка

### 1. Проверьте таблицы

Перейдите в **Table Editor** и убедитесь, что созданы таблицы:
- ✅ tasks
- ✅ task_reminders
- ✅ task_status_history

### 2. Проверьте структуру таблицы tasks

Откройте таблицу `tasks` и проверьте наличие полей:

```
✅ id (UUID)
✅ user_id (TEXT)
✅ title (TEXT)
✅ description (TEXT)
✅ status (TEXT)
✅ priority (TEXT)
✅ due_at (TIMESTAMPTZ)
✅ created_at (TIMESTAMPTZ)
✅ updated_at (TIMESTAMPTZ)
✅ archived_at (TIMESTAMPTZ)
✅ assigned_to_user_id (TEXT)
✅ assigned_to_user_name (TEXT)
✅ postponed_until (TIMESTAMPTZ)
```

### 3. Проверьте RLS политики

1. Перейдите в **Authentication** → **Policies**
2. Убедитесь, что для каждой таблицы есть политика "Enable all operations"

### 4. Проверьте функции

Выполните в SQL Editor:

```sql
-- Проверка функции статистики
SELECT * FROM get_user_task_stats('test-user');

-- Проверка функции поиска
SELECT * FROM search_tasks('test-user', 'тест', 10);
```

### 5. Проверьте представления

```sql
-- Просмотр представлений
SELECT * FROM tasks_with_reminder_count LIMIT 5;
SELECT * FROM overdue_tasks LIMIT 5;
SELECT * FROM upcoming_tasks LIMIT 5;
```

---

## 🧪 Тестовые данные

### Создание тестовых задач

Выполните в SQL Editor:

```sql
-- Создать тестовые задачи
INSERT INTO tasks (user_id, title, description, status, priority, due_at)
VALUES 
  ('test-user-1', 'Купить продукты', 'Молоко, хлеб, яйца', 'pending', 'high', NOW() + INTERVAL '1 day'),
  ('test-user-1', 'Позвонить врачу', 'Записаться на прием', 'accepted', 'medium', NOW() + INTERVAL '3 days'),
  ('test-user-1', 'Оплатить счета', 'Коммунальные услуги', 'pending', 'high', NOW() + INTERVAL '2 days'),
  ('test-user-1', 'Прочитать книгу', 'Глава 5-10', 'postponed', 'low', NOW() + INTERVAL '7 days'),
  ('test-user-1', 'Сделать зарядку', 'Утренняя зарядка', 'archived', 'medium', NOW() - INTERVAL '1 day');
```

### Проверка созданных задач

```sql
SELECT * FROM tasks WHERE user_id = 'test-user-1' ORDER BY created_at DESC;
```

### Создание напоминания

```sql
-- Получить ID первой задачи
SELECT id FROM tasks WHERE user_id = 'test-user-1' LIMIT 1;

-- Создать напоминание (замените TASK_ID)
INSERT INTO task_reminders (task_id, user_id, remind_at, type, enabled)
VALUES (
  'TASK_ID',
  'test-user-1',
  NOW() + INTERVAL '12 hours',
  'notification',
  true
);
```

### Удаление тестовых данных

```sql
-- Удалить все тестовые задачи
DELETE FROM tasks WHERE user_id = 'test-user-1';
```

---

## 📊 Полезные запросы

### Статистика по задачам

```sql
-- Общая статистика
SELECT 
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE status = 'pending') as pending,
  COUNT(*) FILTER (WHERE status = 'accepted') as accepted,
  COUNT(*) FILTER (WHERE status = 'archived') as archived
FROM tasks
WHERE user_id = 'YOUR_USER_ID';
```

### Просроченные задачи

```sql
SELECT 
  title,
  due_at,
  EXTRACT(EPOCH FROM (NOW() - due_at))/3600 as hours_overdue
FROM tasks
WHERE user_id = 'YOUR_USER_ID'
  AND due_at < NOW()
  AND status NOT IN ('archived', 'postponed')
ORDER BY due_at ASC;
```

### Задачи с высоким приоритетом

```sql
SELECT * FROM tasks
WHERE user_id = 'YOUR_USER_ID'
  AND priority = 'high'
  AND status NOT IN ('archived')
ORDER BY due_at ASC NULLS LAST;
```

### Поиск задач

```sql
-- Простой поиск
SELECT * FROM tasks
WHERE user_id = 'YOUR_USER_ID'
  AND (title ILIKE '%поиск%' OR description ILIKE '%поиск%')
ORDER BY created_at DESC;

-- Поиск с релевантностью
SELECT * FROM search_tasks('YOUR_USER_ID', 'поиск', 20);
```

**Больше запросов:** См. файл `database_queries.sql`

---

## 🔧 Обслуживание

### Просмотр размера таблиц

```sql
SELECT 
  tablename,
  pg_size_pretty(pg_total_relation_size('public.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('tasks', 'task_reminders', 'task_status_history')
ORDER BY pg_total_relation_size('public.'||tablename) DESC;
```

### Количество записей

```sql
SELECT 
  'tasks' as table_name,
  COUNT(*) as row_count
FROM tasks
UNION ALL
SELECT 
  'task_reminders',
  COUNT(*)
FROM task_reminders
UNION ALL
SELECT 
  'task_status_history',
  COUNT(*)
FROM task_status_history;
```

### Очистка старых данных

```sql
-- Удалить архивированные задачи старше 90 дней
DELETE FROM tasks
WHERE status = 'archived'
  AND archived_at < NOW() - INTERVAL '90 days';

-- Удалить историю старше 180 дней
DELETE FROM task_status_history
WHERE changed_at < NOW() - INTERVAL '180 days';
```

---

## 🔐 Безопасность

### Row Level Security (RLS)

RLS включен для всех таблиц, но настроен на разрешение всех операций для `anon` и `authenticated` ролей.

**Причина:** Приложение не использует встроенную аутентификацию Supabase, а управляет пользователями на стороне клиента.

### Если нужна строгая безопасность:

Измените политики RLS:

```sql
-- Удалить текущие политики
DROP POLICY "Enable all operations for tasks" ON tasks;

-- Создать политику с проверкой user_id
CREATE POLICY "Users can only access their own tasks"
  ON tasks FOR ALL
  TO authenticated
  USING (user_id = auth.uid()::text)
  WITH CHECK (user_id = auth.uid()::text);
```

**Примечание:** Это потребует изменений в Flutter приложении для использования Supabase Auth.

---

## 🆘 Troubleshooting

### Ошибка: "relation already exists"

**Причина:** Таблицы уже созданы

**Решение:** 
1. Удалите существующие таблицы:
```sql
DROP TABLE IF EXISTS task_status_history CASCADE;
DROP TABLE IF EXISTS task_reminders CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
```

2. Выполните `database_schema.sql` снова

### Ошибка: "permission denied"

**Причина:** Недостаточно прав

**Решение:** Убедитесь, что вы вошли как владелец проекта в Supabase Studio

### Ошибка: "extension does not exist"

**Причина:** Расширение pg_trgm не установлено

**Решение:**
```sql
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
```

### Триггеры не работают

**Проверка:**
```sql
SELECT * FROM pg_trigger WHERE tgname LIKE '%task%';
```

**Пересоздание:**
```sql
-- Удалить и создать заново
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 📚 Дополнительные ресурсы

- [Документация Supabase](https://supabase.com/docs)
- [PostgreSQL документация](https://www.postgresql.org/docs/)
- [SQL Tutorial](https://www.postgresqltutorial.com/)

---

## ✅ Чеклист настройки БД

- [ ] Supabase запущен и доступен
- [ ] Открыт Supabase Studio
- [ ] Выполнен `database_schema.sql`
- [ ] Проверены таблицы в Table Editor
- [ ] Проверены RLS политики
- [ ] Созданы тестовые данные
- [ ] Протестированы запросы
- [ ] Получен Anon Key из Settings → API
- [ ] Обновлен `lib/core/constants.dart` в Flutter приложении

---

## 🎉 Готово!

База данных настроена и готова к работе!

**Следующий шаг:** Обновите Flutter приложение с Anon Key из Supabase Studio.

---

**Создано для Task Tracker Flutter App** 🚀
