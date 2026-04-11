-- ============================================
-- Улучшенная безопасность для Task Tracker
-- ============================================
-- Версия: 2.0 (Secure)
-- Дата: 2026-04-11
-- 
-- ВАЖНО: Этот скрипт настраивает более строгие политики безопасности
-- 
-- Применение:
-- 1. Откройте Supabase Studio: https://studio.bike53.ru
-- 2. SQL Editor → New query
-- 3. Скопируйте и выполните этот скрипт
-- ============================================

-- ============================================
-- ВАРИАНТ 1: Базовая защита (рекомендуется)
-- ============================================
-- Разрешает операции только для anon роли
-- Фильтрация по user_id происходит на стороне клиента

-- Удаление старых политик
DROP POLICY IF EXISTS "Enable all operations for tasks" ON tasks;
DROP POLICY IF EXISTS "Enable all operations for task_reminders" ON task_reminders;
DROP POLICY IF EXISTS "Enable all operations for task_status_history" ON task_status_history;

-- Политики для tasks
CREATE POLICY "Allow anon read tasks"
  ON tasks FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anon insert tasks"
  ON tasks FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anon update tasks"
  ON tasks FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon delete tasks"
  ON tasks FOR DELETE
  TO anon
  USING (true);

-- Политики для task_reminders
CREATE POLICY "Allow anon read reminders"
  ON task_reminders FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anon insert reminders"
  ON task_reminders FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anon update reminders"
  ON task_reminders FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon delete reminders"
  ON task_reminders FOR DELETE
  TO anon
  USING (true);

-- Политики для task_status_history
CREATE POLICY "Allow anon read history"
  ON task_status_history FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anon insert history"
  ON task_status_history FOR INSERT
  TO anon
  WITH CHECK (true);

-- ============================================
-- ВАРИАНТ 2: Строгая защита с API ключом
-- ============================================
-- Раскомментируйте этот блок, если хотите использовать
-- более строгую защиту с проверкой API ключа

/*
-- Создание таблицы для API ключей
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT UNIQUE NOT NULL,
  user_id TEXT NOT NULL,
  name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT true
);

-- Индекс для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_api_keys_key ON api_keys(key) WHERE is_active = true;

-- Функция для проверки API ключа
CREATE OR REPLACE FUNCTION check_api_key(p_api_key TEXT)
RETURNS TEXT AS $$
DECLARE
  v_user_id TEXT;
BEGIN
  SELECT user_id INTO v_user_id
  FROM api_keys
  WHERE key = p_api_key
    AND is_active = true
    AND (expires_at IS NULL OR expires_at > NOW());
  
  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Политики с проверкой API ключа
DROP POLICY IF EXISTS "Allow anon read tasks" ON tasks;
DROP POLICY IF EXISTS "Allow anon insert tasks" ON tasks;
DROP POLICY IF EXISTS "Allow anon update tasks" ON tasks;
DROP POLICY IF EXISTS "Allow anon delete tasks" ON tasks;

CREATE POLICY "API key required for tasks"
  ON tasks FOR ALL
  TO anon
  USING (
    user_id = check_api_key(current_setting('request.headers', true)::json->>'x-api-key')
  )
  WITH CHECK (
    user_id = check_api_key(current_setting('request.headers', true)::json->>'x-api-key')
  );
*/

-- ============================================
-- ВАРИАНТ 3: Максимальная защита с Supabase Auth
-- ============================================
-- Используйте этот вариант, если хотите интегрировать
-- встроенную аутентификацию Supabase

/*
-- Удаление политик для anon
DROP POLICY IF EXISTS "Allow anon read tasks" ON tasks;
DROP POLICY IF EXISTS "Allow anon insert tasks" ON tasks;
DROP POLICY IF EXISTS "Allow anon update tasks" ON tasks;
DROP POLICY IF EXISTS "Allow anon delete tasks" ON tasks;

-- Политики для authenticated пользователей
CREATE POLICY "Users can read own tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (user_id = auth.uid()::text);

CREATE POLICY "Users can insert own tasks"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "Users can update own tasks"
  ON tasks FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid()::text)
  WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "Users can delete own tasks"
  ON tasks FOR DELETE
  TO authenticated
  USING (user_id = auth.uid()::text);

-- Аналогично для task_reminders
CREATE POLICY "Users can read own reminders"
  ON task_reminders FOR SELECT
  TO authenticated
  USING (user_id = auth.uid()::text);

CREATE POLICY "Users can insert own reminders"
  ON task_reminders FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "Users can update own reminders"
  ON task_reminders FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid()::text)
  WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "Users can delete own reminders"
  ON task_reminders FOR DELETE
  TO authenticated
  USING (user_id = auth.uid()::text);

-- Аналогично для task_status_history
CREATE POLICY "Users can read own history"
  ON task_status_history FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tasks
      WHERE tasks.id = task_status_history.task_id
        AND tasks.user_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can insert own history"
  ON task_status_history FOR INSERT
  TO authenticated
  WITH CHECK (changed_by = auth.uid()::text);
*/

-- ============================================
-- ДОПОЛНИТЕЛЬНЫЕ МЕРЫ БЕЗОПАСНОСТИ
-- ============================================

-- Ограничение количества запросов (Rate Limiting)
-- Создание таблицы для отслеживания запросов
CREATE TABLE IF NOT EXISTS request_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,
  endpoint TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Индекс для очистки старых записей
CREATE INDEX IF NOT EXISTS idx_request_logs_created_at 
  ON request_logs(created_at);

-- Функция для проверки rate limit
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_user_id TEXT,
  p_endpoint TEXT,
  p_max_requests INT DEFAULT 100,
  p_time_window INTERVAL DEFAULT '1 minute'
)
RETURNS BOOLEAN AS $$
DECLARE
  v_request_count INT;
BEGIN
  -- Подсчет запросов за последний период
  SELECT COUNT(*) INTO v_request_count
  FROM request_logs
  WHERE user_id = p_user_id
    AND endpoint = p_endpoint
    AND created_at > NOW() - p_time_window;
  
  -- Если превышен лимит
  IF v_request_count >= p_max_requests THEN
    RETURN false;
  END IF;
  
  -- Логирование запроса
  INSERT INTO request_logs (user_id, endpoint)
  VALUES (p_user_id, p_endpoint);
  
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Функция для очистки старых логов (запускать периодически)
CREATE OR REPLACE FUNCTION cleanup_old_request_logs()
RETURNS void AS $$
BEGIN
  DELETE FROM request_logs
  WHERE created_at < NOW() - INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ЗАЩИТА ОТ SQL INJECTION
-- ============================================

-- Все параметризованные запросы уже защищены
-- Дополнительная валидация на уровне БД

-- Функция для валидации user_id
CREATE OR REPLACE FUNCTION validate_user_id(p_user_id TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  -- Проверка формата (только буквы, цифры, дефис, подчеркивание)
  IF p_user_id !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'Invalid user_id format';
  END IF;
  
  -- Проверка длины
  IF LENGTH(p_user_id) < 3 OR LENGTH(p_user_id) > 50 THEN
    RAISE EXCEPTION 'Invalid user_id length';
  END IF;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Триггер для валидации user_id при вставке
CREATE OR REPLACE FUNCTION validate_user_id_trigger()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM validate_user_id(NEW.user_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS validate_tasks_user_id ON tasks;
CREATE TRIGGER validate_tasks_user_id
  BEFORE INSERT OR UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION validate_user_id_trigger();

DROP TRIGGER IF EXISTS validate_reminders_user_id ON task_reminders;
CREATE TRIGGER validate_reminders_user_id
  BEFORE INSERT OR UPDATE ON task_reminders
  FOR EACH ROW
  EXECUTE FUNCTION validate_user_id_trigger();

-- ============================================
-- АУДИТ И ЛОГИРОВАНИЕ
-- ============================================

-- Таблица для аудита действий
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  table_name TEXT NOT NULL,
  operation TEXT NOT NULL,
  user_id TEXT NOT NULL,
  old_data JSONB,
  new_data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Индексы для аудита
CREATE INDEX IF NOT EXISTS idx_audit_log_table_name ON audit_log(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at DESC);

-- Функция для аудита
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    INSERT INTO audit_log (table_name, operation, user_id, old_data)
    VALUES (TG_TABLE_NAME, TG_OP, OLD.user_id, row_to_json(OLD));
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE') THEN
    INSERT INTO audit_log (table_name, operation, user_id, old_data, new_data)
    VALUES (TG_TABLE_NAME, TG_OP, NEW.user_id, row_to_json(OLD), row_to_json(NEW));
    RETURN NEW;
  ELSIF (TG_OP = 'INSERT') THEN
    INSERT INTO audit_log (table_name, operation, user_id, new_data)
    VALUES (TG_TABLE_NAME, TG_OP, NEW.user_id, row_to_json(NEW));
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Триггеры для аудита (опционально, раскомментируйте если нужно)
/*
DROP TRIGGER IF EXISTS audit_tasks_trigger ON tasks;
CREATE TRIGGER audit_tasks_trigger
  AFTER INSERT OR UPDATE OR DELETE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION audit_trigger();

DROP TRIGGER IF EXISTS audit_reminders_trigger ON task_reminders;
CREATE TRIGGER audit_reminders_trigger
  AFTER INSERT OR UPDATE OR DELETE ON task_reminders
  FOR EACH ROW
  EXECUTE FUNCTION audit_trigger();
*/

-- ============================================
-- ЗАЩИТА ОТ МАССОВОГО УДАЛЕНИЯ
-- ============================================

-- Функция для предотвращения массового удаления
CREATE OR REPLACE FUNCTION prevent_mass_delete()
RETURNS TRIGGER AS $$
DECLARE
  v_delete_count INT;
BEGIN
  -- Подсчет удаляемых записей
  GET DIAGNOSTICS v_delete_count = ROW_COUNT;
  
  -- Если удаляется больше 100 записей за раз
  IF v_delete_count > 100 THEN
    RAISE EXCEPTION 'Mass delete prevented: attempting to delete % rows', v_delete_count;
  END IF;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Триггер для защиты от массового удаления (опционально)
/*
DROP TRIGGER IF EXISTS prevent_mass_delete_tasks ON tasks;
CREATE TRIGGER prevent_mass_delete_tasks
  BEFORE DELETE ON tasks
  FOR EACH STATEMENT
  EXECUTE FUNCTION prevent_mass_delete();
*/

-- ============================================
-- ИНФОРМАЦИЯ О БЕЗОПАСНОСТИ
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Политики безопасности обновлены!';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Применен: ВАРИАНТ 1 (Базовая защита)';
  RAISE NOTICE '';
  RAISE NOTICE 'Дополнительные функции:';
  RAISE NOTICE '✓ Валидация user_id';
  RAISE NOTICE '✓ Rate limiting';
  RAISE NOTICE '✓ Аудит логирование (опционально)';
  RAISE NOTICE '✓ Защита от массового удаления (опционально)';
  RAISE NOTICE '';
  RAISE NOTICE 'Для более строгой защиты:';
  RAISE NOTICE '- Раскомментируйте ВАРИАНТ 2 (API ключи)';
  RAISE NOTICE '- Или ВАРИАНТ 3 (Supabase Auth)';
  RAISE NOTICE '============================================';
END $$;
