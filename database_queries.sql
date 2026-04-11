-- ============================================
-- Полезные SQL запросы для Task Tracker
-- ============================================
-- Используйте эти запросы в Supabase SQL Editor
-- для управления и анализа данных
-- ============================================

-- ============================================
-- ЗАПРОСЫ ДЛЯ ПРОСМОТРА ДАННЫХ
-- ============================================

-- Просмотр всех задач
SELECT * FROM tasks ORDER BY created_at DESC;

-- Просмотр задач конкретного пользователя
SELECT * FROM tasks 
WHERE user_id = 'YOUR_USER_ID' 
ORDER BY created_at DESC;

-- Просмотр задач по статусу
SELECT * FROM tasks 
WHERE status = 'pending' 
ORDER BY due_at ASC NULLS LAST;

-- Просмотр задач с высоким приоритетом
SELECT * FROM tasks 
WHERE priority = 'high' 
  AND status NOT IN ('archived')
ORDER BY due_at ASC NULLS LAST;

-- Просмотр просроченных задач
SELECT 
  id,
  title,
  status,
  priority,
  due_at,
  EXTRACT(EPOCH FROM (NOW() - due_at))/3600 as hours_overdue
FROM tasks
WHERE due_at < NOW()
  AND status NOT IN ('archived', 'postponed')
ORDER BY due_at ASC;

-- Просмотр задач с ближайшими дедлайнами (следующие 7 дней)
SELECT 
  id,
  title,
  status,
  priority,
  due_at,
  EXTRACT(EPOCH FROM (due_at - NOW()))/3600 as hours_until_due
FROM tasks
WHERE due_at > NOW()
  AND due_at < NOW() + INTERVAL '7 days'
  AND status NOT IN ('archived', 'postponed')
ORDER BY due_at ASC;

-- Просмотр задач с напоминаниями
SELECT 
  t.id,
  t.title,
  t.status,
  COUNT(tr.id) as reminder_count
FROM tasks t
LEFT JOIN task_reminders tr ON t.id = tr.task_id
GROUP BY t.id
HAVING COUNT(tr.id) > 0
ORDER BY t.created_at DESC;

-- Просмотр истории изменений статусов задачи
SELECT 
  tsh.changed_at,
  tsh.from_status,
  tsh.to_status,
  tsh.changed_by,
  t.title as task_title
FROM task_status_history tsh
JOIN tasks t ON tsh.task_id = t.id
WHERE tsh.task_id = 'TASK_ID'
ORDER BY tsh.changed_at DESC;

-- ============================================
-- СТАТИСТИКА И АНАЛИТИКА
-- ============================================

-- Статистика по задачам пользователя
SELECT 
  COUNT(*) as total_tasks,
  COUNT(*) FILTER (WHERE status = 'pending') as pending,
  COUNT(*) FILTER (WHERE status = 'accepted') as accepted,
  COUNT(*) FILTER (WHERE status = 'postponed') as postponed,
  COUNT(*) FILTER (WHERE status = 'archived') as archived,
  COUNT(*) FILTER (WHERE due_at < NOW() AND status NOT IN ('archived', 'postponed')) as overdue,
  COUNT(*) FILTER (WHERE priority = 'high') as high_priority
FROM tasks
WHERE user_id = 'YOUR_USER_ID';

-- Использование функции для статистики
SELECT * FROM get_user_task_stats('YOUR_USER_ID');

-- Статистика по приоритетам
SELECT 
  priority,
  COUNT(*) as count,
  COUNT(*) FILTER (WHERE status = 'pending') as pending,
  COUNT(*) FILTER (WHERE status = 'accepted') as accepted,
  COUNT(*) FILTER (WHERE status = 'archived') as archived
FROM tasks
WHERE user_id = 'YOUR_USER_ID'
GROUP BY priority
ORDER BY 
  CASE priority
    WHEN 'high' THEN 1
    WHEN 'medium' THEN 2
    WHEN 'low' THEN 3
  END;

-- Статистика по статусам
SELECT 
  status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM tasks
WHERE user_id = 'YOUR_USER_ID'
GROUP BY status
ORDER BY count DESC;

-- Задачи, созданные за последние 7 дней
SELECT 
  DATE(created_at) as date,
  COUNT(*) as tasks_created
FROM tasks
WHERE user_id = 'YOUR_USER_ID'
  AND created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Задачи, завершенные за последние 30 дней
SELECT 
  DATE(archived_at) as date,
  COUNT(*) as tasks_completed
FROM tasks
WHERE user_id = 'YOUR_USER_ID'
  AND archived_at IS NOT NULL
  AND archived_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(archived_at)
ORDER BY date DESC;

-- Среднее время выполнения задач
SELECT 
  AVG(EXTRACT(EPOCH FROM (archived_at - created_at))/3600) as avg_hours_to_complete,
  MIN(EXTRACT(EPOCH FROM (archived_at - created_at))/3600) as min_hours,
  MAX(EXTRACT(EPOCH FROM (archived_at - created_at))/3600) as max_hours
FROM tasks
WHERE user_id = 'YOUR_USER_ID'
  AND archived_at IS NOT NULL;

-- ============================================
-- ПОИСК И ФИЛЬТРАЦИЯ
-- ============================================

-- Поиск задач по названию
SELECT * FROM tasks
WHERE user_id = 'YOUR_USER_ID'
  AND title ILIKE '%поиск%'
ORDER BY created_at DESC;

-- Поиск задач по названию или описанию
SELECT * FROM tasks
WHERE user_id = 'YOUR_USER_ID'
  AND (
    title ILIKE '%поиск%' OR
    description ILIKE '%поиск%'
  )
ORDER BY created_at DESC;

-- Использование функции поиска с релевантностью
SELECT * FROM search_tasks('YOUR_USER_ID', 'поиск', 20);

-- Задачи без срока выполнения
SELECT * FROM tasks
WHERE user_id = 'YOUR_USER_ID'
  AND due_at IS NULL
  AND status NOT IN ('archived')
ORDER BY created_at DESC;

-- Задачи, назначенные другим пользователям
SELECT * FROM tasks
WHERE user_id = 'YOUR_USER_ID'
  AND assigned_to_user_id IS NOT NULL
ORDER BY created_at DESC;

-- Отложенные задачи
SELECT 
  id,
  title,
  status,
  postponed_until,
  EXTRACT(EPOCH FROM (postponed_until - NOW()))/3600 as hours_until_resume
FROM tasks
WHERE user_id = 'YOUR_USER_ID'
  AND status = 'postponed'
  AND postponed_until IS NOT NULL
ORDER BY postponed_until ASC;

-- ============================================
-- ОБНОВЛЕНИЕ ДАННЫХ
-- ============================================

-- Изменить статус задачи
UPDATE tasks
SET status = 'accepted'
WHERE id = 'TASK_ID';

-- Изменить приоритет задачи
UPDATE tasks
SET priority = 'high'
WHERE id = 'TASK_ID';

-- Установить срок выполнения
UPDATE tasks
SET due_at = '2026-04-15 10:00:00+00'
WHERE id = 'TASK_ID';

-- Назначить задачу пользователю
UPDATE tasks
SET 
  assigned_to_user_id = 'USER_ID',
  assigned_to_user_name = 'Имя Пользователя'
WHERE id = 'TASK_ID';

-- Отложить задачу
UPDATE tasks
SET 
  status = 'postponed',
  postponed_until = '2026-04-20 09:00:00+00'
WHERE id = 'TASK_ID';

-- Архивировать задачу
UPDATE tasks
SET status = 'archived'
WHERE id = 'TASK_ID';

-- Массовое архивирование завершенных задач
UPDATE tasks
SET status = 'archived'
WHERE user_id = 'YOUR_USER_ID'
  AND status = 'accepted'
  AND due_at < NOW() - INTERVAL '30 days';

-- ============================================
-- УДАЛЕНИЕ ДАННЫХ
-- ============================================

-- Удалить конкретную задачу
DELETE FROM tasks
WHERE id = 'TASK_ID';

-- Удалить все архивированные задачи старше 90 дней
DELETE FROM tasks
WHERE user_id = 'YOUR_USER_ID'
  AND status = 'archived'
  AND archived_at < NOW() - INTERVAL '90 days';

-- Удалить все напоминания для задачи
DELETE FROM task_reminders
WHERE task_id = 'TASK_ID';

-- Удалить отключенные напоминания
DELETE FROM task_reminders
WHERE user_id = 'YOUR_USER_ID'
  AND enabled = false;

-- ============================================
-- ОБСЛУЖИВАНИЕ БАЗЫ ДАННЫХ
-- ============================================

-- Просмотр размера таблиц
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Просмотр количества записей в таблицах
SELECT 
  'tasks' as table_name,
  COUNT(*) as row_count
FROM tasks
UNION ALL
SELECT 
  'task_reminders' as table_name,
  COUNT(*) as row_count
FROM task_reminders
UNION ALL
SELECT 
  'task_status_history' as table_name,
  COUNT(*) as row_count
FROM task_status_history;

-- Просмотр индексов
SELECT 
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('tasks', 'task_reminders', 'task_status_history')
ORDER BY tablename, indexname;

-- Анализ производительности запросов (требует pg_stat_statements)
-- SELECT 
--   query,
--   calls,
--   total_time,
--   mean_time,
--   max_time
-- FROM pg_stat_statements
-- WHERE query LIKE '%tasks%'
-- ORDER BY total_time DESC
-- LIMIT 10;

-- ============================================
-- ТЕСТОВЫЕ ДАННЫЕ
-- ============================================

-- Создать тестовую задачу
INSERT INTO tasks (user_id, title, description, status, priority, due_at)
VALUES (
  'test-user-1',
  'Тестовая задача',
  'Это тестовая задача для проверки',
  'pending',
  'medium',
  NOW() + INTERVAL '3 days'
);

-- Создать несколько тестовых задач
INSERT INTO tasks (user_id, title, description, status, priority, due_at)
VALUES 
  ('test-user-1', 'Задача 1', 'Описание 1', 'pending', 'high', NOW() + INTERVAL '1 day'),
  ('test-user-1', 'Задача 2', 'Описание 2', 'accepted', 'medium', NOW() + INTERVAL '3 days'),
  ('test-user-1', 'Задача 3', 'Описание 3', 'pending', 'low', NOW() + INTERVAL '7 days'),
  ('test-user-1', 'Задача 4', 'Описание 4', 'postponed', 'medium', NOW() + INTERVAL '5 days'),
  ('test-user-1', 'Задача 5', 'Описание 5', 'archived', 'high', NOW() - INTERVAL '2 days');

-- Создать напоминание для задачи
INSERT INTO task_reminders (task_id, user_id, remind_at, type, enabled)
VALUES (
  'TASK_ID',
  'test-user-1',
  NOW() + INTERVAL '1 day',
  'notification',
  true
);

-- ============================================
-- ОЧИСТКА ТЕСТОВЫХ ДАННЫХ
-- ============================================

-- Удалить все тестовые задачи
DELETE FROM tasks
WHERE user_id = 'test-user-1';

-- Удалить все данные (ОСТОРОЖНО!)
-- TRUNCATE tasks, task_reminders, task_status_history CASCADE;

-- ============================================
-- РЕЗЕРВНОЕ КОПИРОВАНИЕ
-- ============================================

-- Экспорт задач пользователя в JSON (выполнить в psql)
-- \copy (SELECT row_to_json(t) FROM tasks t WHERE user_id = 'YOUR_USER_ID') TO '/tmp/tasks_backup.json'

-- Экспорт всех задач в CSV
-- \copy tasks TO '/tmp/tasks_backup.csv' WITH CSV HEADER

-- ============================================
-- ВОССТАНОВЛЕНИЕ
-- ============================================

-- Импорт задач из CSV
-- \copy tasks FROM '/tmp/tasks_backup.csv' WITH CSV HEADER

-- ============================================
-- ПОЛЕЗНЫЕ ПРЕДСТАВЛЕНИЯ
-- ============================================

-- Использование представления для задач с напоминаниями
SELECT * FROM tasks_with_reminder_count
WHERE user_id = 'YOUR_USER_ID'
ORDER BY reminder_count DESC;

-- Использование представления для просроченных задач
SELECT * FROM overdue_tasks
WHERE user_id = 'YOUR_USER_ID';

-- Использование представления для задач с ближайшими дедлайнами
SELECT * FROM upcoming_tasks
WHERE user_id = 'YOUR_USER_ID';

-- ============================================
-- ПРИМЕЧАНИЯ
-- ============================================

-- 1. Замените 'YOUR_USER_ID' на реальный ID пользователя
-- 2. Замените 'TASK_ID' на реальный ID задачи
-- 3. Даты указаны в формате ISO 8601 с timezone
-- 4. Все запросы можно выполнять в Supabase SQL Editor
-- 5. Для массовых операций рекомендуется делать резервную копию

-- ============================================
-- КОНЕЦ ФАЙЛА
-- ============================================
