-- ============================================
-- ПОЛНАЯ ПЕРЕСБОРКА БАЗЫ ДАННЫХ
-- ============================================
-- Версия: 4.0
-- Дата: 2026-04-11
-- Описание: Удаляет все старые таблицы и создает новые
--           с правильной структурой для авторизации
-- 
-- ⚠️  ВНИМАНИЕ: Все данные будут удалены!
-- ============================================

BEGIN;

-- ============================================
-- ШАГ 1: УДАЛЕНИЕ СТАРЫХ ОБЪЕКТОВ
-- ============================================

-- Удаляем представления
DROP VIEW IF EXISTS tasks_with_reminder_count CASCADE;
DROP VIEW IF EXISTS overdue_tasks CASCADE;
DROP VIEW IF EXISTS upcoming_tasks CASCADE;

-- Удаляем функции
DROP FUNCTION IF EXISTS get_user_task_stats(UUID) CASCADE;
DROP FUNCTION IF EXISTS search_tasks(UUID, TEXT, INT) CASCADE;
DROP FUNCTION IF EXISTS get_tasks_by_status(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_tasks_by_priority(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_overdue_tasks(UUID) CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS validate_user_id(TEXT) CASCADE;
DROP FUNCTION IF EXISTS validate_user_id_trigger() CASCADE;
DROP FUNCTION IF EXISTS create_user_profile() CASCADE;
DROP FUNCTION IF EXISTS get_user_profile() CASCADE;

-- Удаляем таблицы (в правильном порядке из-за внешних ключей)
DROP TABLE IF EXISTS task_status_history CASCADE;
DROP TABLE IF EXISTS task_reminders CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- ============================================
-- ШАГ 2: СОЗДАНИЕ ТАБЛИЦЫ USER_PROFILES
-- ============================================

CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Индексы
CREATE INDEX idx_user_profiles_phone ON user_profiles(phone);

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

-- ============================================
-- ШАГ 3: СОЗДАНИЕ ТАБЛИЦЫ TASKS
-- ============================================

CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  priority TEXT NOT NULL DEFAULT 'medium',
  due_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  archived_at TIMESTAMPTZ,
  assigned_to_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  assigned_to_user_name TEXT,
  postponed_until TIMESTAMPTZ,
  
  CONSTRAINT tasks_status_check CHECK (status IN ('pending', 'accepted', 'postponed', 'archived')),
  CONSTRAINT tasks_priority_check CHECK (priority IN ('low', 'medium', 'high'))
);

-- Индексы для tasks
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_due_at ON tasks(due_at);
CREATE INDEX idx_tasks_created_at ON tasks(created_at DESC);
CREATE INDEX idx_tasks_user_status ON tasks(user_id, status);
CREATE INDEX idx_tasks_user_priority ON tasks(user_id, priority);
CREATE INDEX idx_tasks_archived ON tasks(archived_at) WHERE archived_at IS NOT NULL;

-- RLS для tasks
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

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

-- ============================================
-- ШАГ 4: СОЗДАНИЕ ТАБЛИЦЫ TASK_REMINDERS
-- ============================================

CREATE TABLE task_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  remind_at TIMESTAMPTZ NOT NULL,
  message TEXT,
  is_sent BOOLEAN NOT NULL DEFAULT FALSE,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Индексы для task_reminders
CREATE INDEX idx_task_reminders_task_id ON task_reminders(task_id);
CREATE INDEX idx_task_reminders_user_id ON task_reminders(user_id);
CREATE INDEX idx_task_reminders_remind_at ON task_reminders(remind_at);
CREATE INDEX idx_task_reminders_pending ON task_reminders(remind_at) WHERE is_sent = FALSE;

-- RLS для task_reminders
ALTER TABLE task_reminders ENABLE ROW LEVEL SECURITY;

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

-- ============================================
-- ШАГ 5: СОЗДАНИЕ ТАБЛИЦЫ TASK_STATUS_HISTORY
-- ============================================

CREATE TABLE task_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  old_status TEXT NOT NULL,
  new_status TEXT NOT NULL,
  changed_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  notes TEXT
);

-- Индексы для task_status_history
CREATE INDEX idx_task_status_history_task_id ON task_status_history(task_id);
CREATE INDEX idx_task_status_history_changed_at ON task_status_history(changed_at DESC);

-- RLS для task_status_history
ALTER TABLE task_status_history ENABLE ROW LEVEL SECURITY;

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
-- ШАГ 6: СОЗДАНИЕ ФУНКЦИЙ
-- ============================================

-- Функция для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггеры для updated_at
CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Функция для автоматического создания профиля
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, phone, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(
      NEW.raw_user_meta_data->>'display_name', 
      NEW.raw_user_meta_data->>'name', 
      'Пользователь'
    )
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to create user profile for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Триггер для создания профиля
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_user_profile();

-- Функция для получения профиля
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

-- Функция для статистики задач
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

-- Функция для поиска задач
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
  created_at TIMESTAMPTZ
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
    t.created_at
  FROM tasks t
  WHERE t.user_id = p_user_id
    AND (
      t.title ILIKE '%' || p_search_query || '%' OR
      t.description ILIKE '%' || p_search_query || '%'
    )
  ORDER BY t.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ШАГ 7: СОЗДАНИЕ ПРЕДСТАВЛЕНИЙ
-- ============================================

-- Представление задач с количеством напоминаний
CREATE OR REPLACE VIEW tasks_with_reminder_count AS
SELECT 
  t.*,
  COUNT(tr.id) as reminder_count
FROM tasks t
LEFT JOIN task_reminders tr ON t.id = tr.task_id
GROUP BY t.id;

-- Представление просроченных задач
CREATE OR REPLACE VIEW overdue_tasks AS
SELECT *
FROM tasks
WHERE due_at < NOW()
  AND status NOT IN ('archived', 'postponed');

-- Представление предстоящих задач
CREATE OR REPLACE VIEW upcoming_tasks AS
SELECT *
FROM tasks
WHERE due_at BETWEEN NOW() AND NOW() + INTERVAL '7 days'
  AND status NOT IN ('archived', 'postponed')
ORDER BY due_at ASC;

-- ============================================
-- ЗАВЕРШЕНИЕ
-- ============================================

COMMIT;

-- Вывод информации
DO $$
BEGIN
  RAISE NOTICE '============================================';
  RAISE NOTICE '✓ БАЗА ДАННЫХ ПЕРЕСОЗДАНА!';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Созданные таблицы:';
  RAISE NOTICE '  ✓ user_profiles';
  RAISE NOTICE '  ✓ tasks';
  RAISE NOTICE '  ✓ task_reminders';
  RAISE NOTICE '  ✓ task_status_history';
  RAISE NOTICE '';
  RAISE NOTICE 'Созданные функции:';
  RAISE NOTICE '  ✓ update_updated_at_column()';
  RAISE NOTICE '  ✓ create_user_profile()';
  RAISE NOTICE '  ✓ get_user_profile()';
  RAISE NOTICE '  ✓ get_user_task_stats()';
  RAISE NOTICE '  ✓ search_tasks()';
  RAISE NOTICE '';
  RAISE NOTICE 'Созданные представления:';
  RAISE NOTICE '  ✓ tasks_with_reminder_count';
  RAISE NOTICE '  ✓ overdue_tasks';
  RAISE NOTICE '  ✓ upcoming_tasks';
  RAISE NOTICE '';
  RAISE NOTICE 'RLS политики:';
  RAISE NOTICE '  ✓ Все таблицы защищены RLS';
  RAISE NOTICE '  ✓ Пользователи видят только свои данные';
  RAISE NOTICE '';
  RAISE NOTICE 'Следующие шаги:';
  RAISE NOTICE '1. Настройте Supabase Auth (см. инструкцию)';
  RAISE NOTICE '2. Запустите приложение: flutter run';
  RAISE NOTICE '3. Зарегистрируйте нового пользователя';
  RAISE NOTICE '4. Создайте задачу';
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
END $$;
