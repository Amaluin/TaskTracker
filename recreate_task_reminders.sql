-- ============================================
-- ПОЛНОЕ ПЕРЕСОЗДАНИЕ таблицы task_reminders
-- ============================================
-- ⚠️ ВНИМАНИЕ: Это удалит все существующие напоминания!
-- Используйте только если add_enabled_column.sql не помог

-- Удаляем старую таблицу
DROP TABLE IF EXISTS task_reminders CASCADE;

-- Создаём таблицу заново с правильной структурой
CREATE TABLE task_reminders (
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

-- Комментарии
COMMENT ON TABLE task_reminders IS 'Напоминания для задач';
COMMENT ON COLUMN task_reminders.id IS 'Уникальный идентификатор напоминания';
COMMENT ON COLUMN task_reminders.task_id IS 'ID связанной задачи';
COMMENT ON COLUMN task_reminders.user_id IS 'ID пользователя';
COMMENT ON COLUMN task_reminders.remind_at IS 'Время напоминания';
COMMENT ON COLUMN task_reminders.type IS 'Тип: notification или alarm';
COMMENT ON COLUMN task_reminders.enabled IS 'Включено ли напоминание';

-- Индексы
CREATE INDEX idx_reminders_task_id ON task_reminders(task_id);
CREATE INDEX idx_reminders_user_id ON task_reminders(user_id);
CREATE INDEX idx_reminders_remind_at ON task_reminders(remind_at) WHERE enabled = true;
CREATE INDEX idx_reminders_enabled ON task_reminders(enabled, remind_at);

-- RLS политики
ALTER TABLE task_reminders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable all operations for task_reminders" ON task_reminders;
CREATE POLICY "Enable all operations for task_reminders"
  ON task_reminders FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- Проверка
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns
WHERE table_name = 'task_reminders'
ORDER BY ordinal_position;
