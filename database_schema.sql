-- ============================================
-- Supabase Database Schema for Task Tracker
-- ============================================
-- Версия: 2.0
-- Дата: 2026-04-11
-- Описание: Полная схема базы данных для приложения Task Tracker
-- 
-- Инструкция по применению:
-- 1. Откройте Supabase Studio: https://studio.bike53.ru
-- 2. Перейдите в SQL Editor
-- 3. Скопируйте и выполните этот скрипт
-- ============================================

-- Включение расширений
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Для полнотекстового поиска

-- ============================================
-- ТАБЛИЦА: tasks (Задачи)
-- ============================================
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'postponed', 'archived')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  due_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  archived_at TIMESTAMPTZ,
  assigned_to_user_id TEXT,
  assigned_to_user_name TEXT,
  postponed_until TIMESTAMPTZ,
  
  -- Ограничения
  CONSTRAINT tasks_title_not_empty CHECK (LENGTH(TRIM(title)) > 0),
  CONSTRAINT tasks_due_at_future CHECK (due_at IS NULL OR due_at > created_at),
  CONSTRAINT tasks_postponed_valid CHECK (
    (status = 'postponed' AND postponed_until IS NOT NULL) OR 
    (status != 'postponed' AND postponed_until IS NULL)
  )
);

-- Комментарии к таблице tasks
COMMENT ON TABLE tasks IS 'Основная таблица задач';
COMMENT ON COLUMN tasks.id IS 'Уникальный идентификатор задачи';
COMMENT ON COLUMN tasks.user_id IS 'ID пользователя-владельца задачи';
COMMENT ON COLUMN tasks.title IS 'Название задачи';
COMMENT ON COLUMN tasks.description IS 'Описание задачи';
COMMENT ON COLUMN tasks.status IS 'Статус: pending, accepted, postponed, archived';
COMMENT ON COLUMN tasks.priority IS 'Приоритет: low, medium, high';
COMMENT ON COLUMN tasks.due_at IS 'Срок выполнения задачи';
COMMENT ON COLUMN tasks.created_at IS 'Дата создания';
COMMENT ON COLUMN tasks.updated_at IS 'Дата последнего обновления';
COMMENT ON COLUMN tasks.archived_at IS 'Дата архивирования';
COMMENT ON COLUMN tasks.assigned_to_user_id IS 'ID пользователя, ответственного за задачу';
COMMENT ON COLUMN tasks.assigned_to_user_name IS 'Имя пользователя, ответственного за задачу';
COMMENT ON COLUMN tasks.postponed_until IS 'Дата и время, на которое отложена задача';

-- ============================================
-- ТАБЛИЦА: task_reminders (Напоминания)
-- ============================================
CREATE TABLE IF NOT EXISTS task_reminders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL,
  remind_at TIMESTAMPTZ NOT NULL,
  type TEXT NOT NULL DEFAULT 'notification' CHECK (type IN ('notification', 'alarm')),
  enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Ограничения
  CONSTRAINT reminders_remind_at_future CHECK (remind_at > created_at)
);

-- Комментарии к таблице task_reminders
COMMENT ON TABLE task_reminders IS 'Напоминания для задач';
COMMENT ON COLUMN task_reminders.id IS 'Уникальный идентификатор напоминания';
COMMENT ON COLUMN task_reminders.task_id IS 'ID связанной задачи';
COMMENT ON COLUMN task_reminders.user_id IS 'ID пользователя';
COMMENT ON COLUMN task_reminders.remind_at IS 'Время напоминания';
COMMENT ON COLUMN task_reminders.type IS 'Тип: notification или alarm';
COMMENT ON COLUMN task_reminders.enabled IS 'Включено ли напоминание';

-- ============================================
-- ТАБЛИЦА: task_status_history (История статусов)
-- ============================================
CREATE TABLE IF NOT EXISTS task_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  from_status TEXT,
  to_status TEXT NOT NULL,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  changed_by TEXT NOT NULL,
  
  -- Ограничения
  CONSTRAINT history_status_valid CHECK (
    to_status IN ('pending', 'accepted', 'postponed', 'archived')
  ),
  CONSTRAINT history_from_status_valid CHECK (
    from_status IS NULL OR 
    from_status IN ('pending', 'accepted', 'postponed', 'archived')
  )
);

-- Комментарии к таблице task_status_history
COMMENT ON TABLE task_status_history IS 'История изменений статусов задач';
COMMENT ON COLUMN task_status_history.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN task_status_history.task_id IS 'ID задачи';
COMMENT ON COLUMN task_status_history.from_status IS 'Предыдущий статус';
COMMENT ON COLUMN task_status_history.to_status IS 'Новый статус';
COMMENT ON COLUMN task_status_history.changed_at IS 'Время изменения';
COMMENT ON COLUMN task_status_history.changed_by IS 'ID пользователя, изменившего статус';

-- ============================================
-- ИНДЕКСЫ ДЛЯ ПРОИЗВОДИТЕЛЬНОСТИ
-- ============================================

-- Индексы для tasks
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_due_at ON tasks(due_at) WHERE due_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to_user_id) WHERE assigned_to_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_postponed_until ON tasks(postponed_until) WHERE postponed_until IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_archived_at ON tasks(archived_at) WHERE archived_at IS NOT NULL;

-- Составные индексы для частых запросов
CREATE INDEX IF NOT EXISTS idx_tasks_user_status ON tasks(user_id, status);
CREATE INDEX IF NOT EXISTS idx_tasks_user_priority ON tasks(user_id, priority);
CREATE INDEX IF NOT EXISTS idx_tasks_status_due ON tasks(status, due_at) WHERE due_at IS NOT NULL;

-- Индекс для полнотекстового поиска
CREATE INDEX IF NOT EXISTS idx_tasks_title_trgm ON tasks USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_tasks_description_trgm ON tasks USING gin (description gin_trgm_ops);

-- Индексы для task_reminders
CREATE INDEX IF NOT EXISTS idx_reminders_task_id ON task_reminders(task_id);
CREATE INDEX IF NOT EXISTS idx_reminders_user_id ON task_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_reminders_remind_at ON task_reminders(remind_at) WHERE enabled = true;
CREATE INDEX IF NOT EXISTS idx_reminders_enabled ON task_reminders(enabled, remind_at);

-- Индексы для task_status_history
CREATE INDEX IF NOT EXISTS idx_status_history_task_id ON task_status_history(task_id);
CREATE INDEX IF NOT EXISTS idx_status_history_changed_at ON task_status_history(changed_at DESC);
CREATE INDEX IF NOT EXISTS idx_status_history_changed_by ON task_status_history(changed_by);

-- ============================================
-- ФУНКЦИИ И ТРИГГЕРЫ
-- ============================================

-- Функция автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для tasks
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Функция для автоматического создания записи в истории статусов
CREATE OR REPLACE FUNCTION log_task_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Проверяем, изменился ли статус
  IF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
    INSERT INTO task_status_history (task_id, from_status, to_status, changed_by)
    VALUES (NEW.id, OLD.status, NEW.status, NEW.user_id);
  ELSIF (TG_OP = 'INSERT') THEN
    INSERT INTO task_status_history (task_id, from_status, to_status, changed_by)
    VALUES (NEW.id, NULL, NEW.status, NEW.user_id);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для автоматического логирования изменений статуса
DROP TRIGGER IF EXISTS log_task_status_change_trigger ON tasks;
CREATE TRIGGER log_task_status_change_trigger
  AFTER INSERT OR UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION log_task_status_change();

-- Функция для автоматической установки archived_at
CREATE OR REPLACE FUNCTION set_archived_at()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.status = 'archived' AND OLD.status != 'archived') THEN
    NEW.archived_at = NOW();
  ELSIF (NEW.status != 'archived') THEN
    NEW.archived_at = NULL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для автоматической установки archived_at
DROP TRIGGER IF EXISTS set_archived_at_trigger ON tasks;
CREATE TRIGGER set_archived_at_trigger
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION set_archived_at();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
-- ⚠️ ВНИМАНИЕ: Текущие политики открытые!
-- 
-- Это сделано для упрощения разработки, но НЕ безопасно для production!
-- 
-- Для улучшения безопасности:
-- 1. Прочитайте файл БЕЗОПАСНОСТЬ.md
-- 2. Примените database_security.sql
-- 
-- Варианты защиты:
-- - ВАРИАНТ 1: Базовая защита (быстро)
-- - ВАРИАНТ 2: API ключи (рекомендуется для production)
-- - ВАРИАНТ 3: Supabase Auth (максимальная безопасность)
-- ============================================

-- Включение RLS для всех таблиц
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_status_history ENABLE ROW LEVEL SECURITY;

-- Удаление старых политик (если существуют)
DROP POLICY IF EXISTS "Allow all operations on tasks" ON tasks;
DROP POLICY IF EXISTS "Allow all operations on task_reminders" ON task_reminders;
DROP POLICY IF EXISTS "Allow all operations on task_status_history" ON task_status_history;

-- Политики для tasks (разрешаем все операции для anon роли)
CREATE POLICY "Enable all operations for tasks"
  ON tasks FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- Политики для task_reminders
CREATE POLICY "Enable all operations for task_reminders"
  ON task_reminders FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- Политики для task_status_history
CREATE POLICY "Enable all operations for task_status_history"
  ON task_status_history FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- ============================================
-- ПРЕДСТАВЛЕНИЯ (VIEWS)
-- ============================================

-- Представление для задач с количеством напоминаний
CREATE OR REPLACE VIEW tasks_with_reminder_count AS
SELECT 
  t.*,
  COUNT(tr.id) as reminder_count,
  COUNT(tr.id) FILTER (WHERE tr.enabled = true) as active_reminder_count
FROM tasks t
LEFT JOIN task_reminders tr ON t.id = tr.task_id
GROUP BY t.id;

COMMENT ON VIEW tasks_with_reminder_count IS 'Задачи с количеством напоминаний';

-- Представление для просроченных задач
CREATE OR REPLACE VIEW overdue_tasks AS
SELECT 
  t.*,
  EXTRACT(EPOCH FROM (NOW() - t.due_at))/3600 as hours_overdue
FROM tasks t
WHERE t.due_at < NOW()
  AND t.status NOT IN ('archived', 'postponed')
ORDER BY t.due_at ASC;

COMMENT ON VIEW overdue_tasks IS 'Просроченные задачи';

-- Представление для задач с ближайшими дедлайнами
CREATE OR REPLACE VIEW upcoming_tasks AS
SELECT 
  t.*,
  EXTRACT(EPOCH FROM (t.due_at - NOW()))/3600 as hours_until_due
FROM tasks t
WHERE t.due_at > NOW()
  AND t.due_at < NOW() + INTERVAL '7 days'
  AND t.status NOT IN ('archived', 'postponed')
ORDER BY t.due_at ASC;

COMMENT ON VIEW upcoming_tasks IS 'Задачи с ближайшими дедлайнами (в течение 7 дней)';

-- ============================================
-- ФУНКЦИИ ДЛЯ API
-- ============================================

-- Функция для получения статистики по задачам пользователя
CREATE OR REPLACE FUNCTION get_user_task_stats(p_user_id TEXT)
RETURNS TABLE (
  total_tasks BIGINT,
  pending_tasks BIGINT,
  accepted_tasks BIGINT,
  postponed_tasks BIGINT,
  archived_tasks BIGINT,
  overdue_tasks BIGINT,
  high_priority_tasks BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_tasks,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_tasks,
    COUNT(*) FILTER (WHERE status = 'accepted') as accepted_tasks,
    COUNT(*) FILTER (WHERE status = 'postponed') as postponed_tasks,
    COUNT(*) FILTER (WHERE status = 'archived') as archived_tasks,
    COUNT(*) FILTER (WHERE due_at < NOW() AND status NOT IN ('archived', 'postponed')) as overdue_tasks,
    COUNT(*) FILTER (WHERE priority = 'high' AND status NOT IN ('archived')) as high_priority_tasks
  FROM tasks
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_user_task_stats IS 'Получение статистики по задачам пользователя';

-- Функция для поиска задач
CREATE OR REPLACE FUNCTION search_tasks(
  p_user_id TEXT,
  p_search_query TEXT,
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  user_id TEXT,
  title TEXT,
  description TEXT,
  status TEXT,
  priority TEXT,
  due_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  similarity REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.user_id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.due_at,
    t.created_at,
    GREATEST(
      similarity(t.title, p_search_query),
      COALESCE(similarity(t.description, p_search_query), 0)
    ) as similarity
  FROM tasks t
  WHERE t.user_id = p_user_id
    AND (
      t.title ILIKE '%' || p_search_query || '%' OR
      t.description ILIKE '%' || p_search_query || '%'
    )
  ORDER BY similarity DESC, t.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION search_tasks IS 'Полнотекстовый поиск задач';

-- ============================================
-- НАЧАЛЬНЫЕ ДАННЫЕ (опционально)
-- ============================================

-- Можно добавить тестовые данные для разработки
-- Раскомментируйте, если нужно

/*
INSERT INTO tasks (user_id, title, description, status, priority, due_at)
VALUES 
  ('test-user-1', 'Тестовая задача 1', 'Описание задачи 1', 'pending', 'high', NOW() + INTERVAL '2 days'),
  ('test-user-1', 'Тестовая задача 2', 'Описание задачи 2', 'accepted', 'medium', NOW() + INTERVAL '5 days'),
  ('test-user-1', 'Тестовая задача 3', 'Описание задачи 3', 'pending', 'low', NOW() + INTERVAL '7 days');
*/

-- ============================================
-- ЗАВЕРШЕНИЕ
-- ============================================

-- Вывод информации о созданных объектах
DO $$
DECLARE
  table_count INT;
  index_count INT;
  function_count INT;
  view_count INT;
BEGIN
  SELECT COUNT(*) INTO table_count FROM information_schema.tables 
  WHERE table_schema = 'public' AND table_name IN ('tasks', 'task_reminders', 'task_status_history');
  
  SELECT COUNT(*) INTO index_count FROM pg_indexes 
  WHERE schemaname = 'public' AND tablename IN ('tasks', 'task_reminders', 'task_status_history');
  
  SELECT COUNT(*) INTO function_count FROM pg_proc 
  WHERE proname IN ('update_updated_at_column', 'log_task_status_change', 'set_archived_at', 'get_user_task_stats', 'search_tasks');
  
  SELECT COUNT(*) INTO view_count FROM information_schema.views 
  WHERE table_schema = 'public' AND table_name IN ('tasks_with_reminder_count', 'overdue_tasks', 'upcoming_tasks');
  
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Схема базы данных успешно создана!';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Таблицы: %', table_count;
  RAISE NOTICE 'Индексы: %', index_count;
  RAISE NOTICE 'Функции: %', function_count;
  RAISE NOTICE 'Представления: %', view_count;
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Следующие шаги:';
  RAISE NOTICE '1. Проверьте таблицы в Table Editor';
  RAISE NOTICE '2. Получите Anon Key из Settings → API';
  RAISE NOTICE '3. Обновите lib/core/constants.dart';
  RAISE NOTICE '============================================';
END $$;
