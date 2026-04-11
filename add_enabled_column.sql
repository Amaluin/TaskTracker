-- ============================================
-- Исправление структуры таблицы task_reminders
-- ============================================
-- Выполните этот скрипт в Supabase SQL Editor

-- Сначала проверим текущую структуру
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns
WHERE table_name = 'task_reminders'
ORDER BY ordinal_position;

-- Добавляем колонку type, если её нет
ALTER TABLE task_reminders 
ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'notification' 
CHECK (type IN ('notification', 'alarm'));

-- Добавляем колонку enabled, если её нет
ALTER TABLE task_reminders 
ADD COLUMN IF NOT EXISTS enabled BOOLEAN NOT NULL DEFAULT true;

-- Добавляем комментарии
COMMENT ON COLUMN task_reminders.type IS 'Тип: notification или alarm';
COMMENT ON COLUMN task_reminders.enabled IS 'Включено ли напоминание';

-- Пересоздаём индексы
DROP INDEX IF EXISTS idx_reminders_enabled;
CREATE INDEX idx_reminders_enabled ON task_reminders(enabled, remind_at);

DROP INDEX IF EXISTS idx_reminders_remind_at;
CREATE INDEX idx_reminders_remind_at ON task_reminders(remind_at) WHERE enabled = true;

-- Обновляем существующие записи (если есть)
UPDATE task_reminders 
SET 
  type = COALESCE(type, 'notification'),
  enabled = COALESCE(enabled, true)
WHERE type IS NULL OR enabled IS NULL;

-- Финальная проверка
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns
WHERE table_name = 'task_reminders'
ORDER BY ordinal_position;
