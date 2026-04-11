-- ============================================
-- Миграция для авторизации по телефону
-- ============================================
-- Версия: 3.0
-- Дата: 2026-04-11
-- Описание: Обновление схемы для работы с Supabase Auth
-- 
-- Применение:
-- 1. Откройте Supabase Studio: https://studio.bike53.ru
-- 2. SQL Editor → New query
-- 3. Скопируйте и выполните этот скрипт
-- ============================================

-- ============================================
-- ОБНОВЛЕНИЕ ТАБЛИЦЫ TASKS
-- ============================================

-- Сначала удаляем представления, которые зависят от user_id
DROP VIEW IF EXISTS tasks_with_reminder_count CASCADE;
DROP VIEW IF EXISTS overdue_tasks CASCADE;
DROP VIEW IF EXISTS upcoming_tasks CASCADE;

-- Изменяем тип user_id с TEXT на UUID для совместимости с auth.users
ALTER TABLE tasks ALTER COLUMN user_id TYPE UUID USING user_id::uuid;

-- Удаляем старый внешний ключ если существует
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_user_id_fkey;

-- Добавляем внешний ключ на auth.users
-- ВАЖНО: Используем DEFERRABLE для возможности создания задач в той же транзакции
ALTER TABLE tasks 
ADD CONSTRAINT tasks_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE
DEFERRABLE INITIALLY DEFERRED;

-- ============================================
-- ОБНОВЛЕНИЕ ТАБЛИЦЫ TASK_REMINDERS
-- ============================================

ALTER TABLE task_reminders ALTER COLUMN user_id TYPE UUID USING user_id::uuid;

-- Удаляем старый внешний ключ если существует
ALTER TABLE task_reminders DROP CONSTRAINT IF EXISTS task_reminders_user_id_fkey;

ALTER TABLE task_reminders 
ADD CONSTRAINT task_reminders_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE
DEFERRABLE INITIALLY DEFERRED;

-- ============================================
-- ОБНОВЛЕНИЕ ТАБЛИЦЫ TASK_STATUS_HISTORY
-- ============================================

ALTER TABLE task_status_history ALTER COLUMN changed_by TYPE UUID USING changed_by::uuid;

-- Удаляем старый внешний ключ если существует
ALTER TABLE task_status_history DROP CONSTRAINT IF EXISTS task_status_history_changed_by_fkey;

ALTER TABLE task_status_history 
ADD CONSTRAINT task_status_history_changed_by_fkey 
FOREIGN KEY (changed_by) 
REFERENCES auth.users(id) 
ON DELETE CASCADE
DEFERRABLE INITIALLY DEFERRED;

-- ============================================
-- ОБНОВЛЕНИЕ RLS ПОЛИТИК
-- ============================================

-- Удаляем старые политики
DROP POLICY IF EXISTS "Enable all operations for tasks" ON tasks;
DROP POLICY IF EXISTS "Allow anon read tasks" ON tasks;
DROP POLICY IF EXISTS "Allow anon insert tasks" ON tasks;
DROP POLICY IF EXISTS "Allow anon update tasks" ON tasks;
DROP POLICY IF EXISTS "Allow anon delete tasks" ON tasks;

DROP POLICY IF EXISTS "Enable all operations for task_reminders" ON task_reminders;
DROP POLICY IF EXISTS "Allow anon read reminders" ON task_reminders;
DROP POLICY IF EXISTS "Allow anon insert reminders" ON task_reminders;
DROP POLICY IF EXISTS "Allow anon update reminders" ON task_reminders;
DROP POLICY IF EXISTS "Allow anon delete reminders" ON task_reminders;

DROP POLICY IF EXISTS "Enable all operations for task_status_history" ON task_status_history;
DROP POLICY IF EXISTS "Allow anon read history" ON task_status_history;
DROP POLICY IF EXISTS "Allow anon insert history" ON task_status_history;

-- Создаем новые политики с проверкой auth.uid()

-- Политики для tasks
CREATE POLICY "Users can read own tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own tasks"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own tasks"
  ON tasks FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own tasks"
  ON tasks FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Политики для task_reminders
CREATE POLICY "Users can read own reminders"
  ON task_reminders FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own reminders"
  ON task_reminders FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own reminders"
  ON task_reminders FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own reminders"
  ON task_reminders FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Политики для task_status_history
CREATE POLICY "Users can read own history"
  ON task_status_history FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tasks
      WHERE tasks.id = task_status_history.task_id
        AND tasks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own history"
  ON task_status_history FOR INSERT
  TO authenticated
  WITH CHECK (changed_by = auth.uid());

-- ============================================
-- ОБНОВЛЕНИЕ ФУНКЦИЙ
-- ============================================

-- Обновляем функцию статистики
DROP FUNCTION IF EXISTS get_user_task_stats(TEXT);

CREATE OR REPLACE FUNCTION get_user_task_stats(p_user_id UUID)
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Обновляем функцию поиска
DROP FUNCTION IF EXISTS search_tasks(TEXT, TEXT, INT);

CREATE OR REPLACE FUNCTION search_tasks(
  p_user_id UUID,
  p_search_query TEXT,
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ОБНОВЛЕНИЕ ТРИГГЕРОВ
-- ============================================

-- Удаляем старый триггер валидации user_id
DROP TRIGGER IF EXISTS validate_tasks_user_id ON tasks;
DROP TRIGGER IF EXISTS validate_reminders_user_id ON task_reminders;
DROP FUNCTION IF EXISTS validate_user_id_trigger();
DROP FUNCTION IF EXISTS validate_user_id(TEXT);

-- Теперь валидация происходит через внешний ключ на auth.users

-- ============================================
-- СОЗДАНИЕ ПРОФИЛЕЙ ПОЛЬЗОВАТЕЛЕЙ
-- ============================================

-- Таблица для дополнительной информации о пользователях
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Индексы
CREATE INDEX IF NOT EXISTS idx_user_profiles_phone ON user_profiles(phone);

-- RLS для user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Триггер для автоматического создания профиля
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_profiles (id, phone, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'name', 'Пользователь')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_user_profile();

-- Триггер для обновления updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ФУНКЦИЯ ДЛЯ ПОЛУЧЕНИЯ ПРОФИЛЯ
-- ============================================

CREATE OR REPLACE FUNCTION get_user_profile()
RETURNS TABLE (
  id UUID,
  phone TEXT,
  display_name TEXT,
  avatar_url TEXT,
  email TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    up.id,
    up.phone,
    up.display_name,
    up.avatar_url,
    au.email
  FROM user_profiles up
  JOIN auth.users au ON au.id = up.id
  WHERE up.id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- МИГРАЦИЯ СУЩЕСТВУЮЩИХ ДАННЫХ
-- ============================================

-- ВНИМАНИЕ: Если у вас есть существующие данные с TEXT user_id,
-- вам нужно будет создать пользователей в auth.users
-- и обновить user_id в tasks

-- Пример миграции (раскомментируйте если нужно):
/*
-- 1. Создайте пользователей в auth.users через Supabase Studio
-- 2. Обновите user_id в tasks:

UPDATE tasks 
SET user_id = 'UUID_FROM_AUTH_USERS'
WHERE user_id = 'OLD_TEXT_USER_ID';
*/

-- ============================================
-- ЗАВЕРШЕНИЕ
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Миграция для авторизации завершена!';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Изменения:';
  RAISE NOTICE '✓ user_id изменен на UUID';
  RAISE NOTICE '✓ Добавлены внешние ключи на auth.users';
  RAISE NOTICE '✓ Обновлены RLS политики';
  RAISE NOTICE '✓ Создана таблица user_profiles';
  RAISE NOTICE '✓ Добавлены триггеры для профилей';
  RAISE NOTICE '';
  RAISE NOTICE 'Следующие шаги:';
  RAISE NOTICE '1. Протестируйте регистрацию в приложении';
  RAISE NOTICE '2. Проверьте создание профиля';
  RAISE NOTICE '3. Проверьте создание задач';
  RAISE NOTICE '============================================';
END $$;

-- ============================================
-- ПЕРЕСОЗДАНИЕ ПРЕДСТАВЛЕНИЙ
-- ============================================

-- Пересоздаем представление tasks_with_reminder_count
CREATE OR REPLACE VIEW tasks_with_reminder_count AS
SELECT 
  t.*,
  COUNT(tr.id) as reminder_count
FROM tasks t
LEFT JOIN task_reminders tr ON t.id = tr.task_id
GROUP BY t.id;

-- Пересоздаем представление overdue_tasks
CREATE OR REPLACE VIEW overdue_tasks AS
SELECT *
FROM tasks
WHERE due_at < NOW()
  AND status NOT IN ('archived', 'postponed');

-- Пересоздаем представление upcoming_tasks
CREATE OR REPLACE VIEW upcoming_tasks AS
SELECT *
FROM tasks
WHERE due_at BETWEEN NOW() AND NOW() + INTERVAL '7 days'
  AND status NOT IN ('archived', 'postponed')
ORDER BY due_at ASC;
