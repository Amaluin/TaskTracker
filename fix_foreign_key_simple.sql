-- ============================================
-- ПРОСТОЕ ИСПРАВЛЕНИЕ ВНЕШНЕГО КЛЮЧА
-- ============================================
-- Этот скрипт просто пересоздает внешний ключ
-- на правильную таблицу auth.users
-- ============================================

-- Удаляем старый внешний ключ (если есть)
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_user_id_fkey;

-- Создаем правильный внешний ключ на auth.users
ALTER TABLE tasks 
ADD CONSTRAINT tasks_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE
DEFERRABLE INITIALLY DEFERRED;

-- Проверяем результат
SELECT
  'Внешний ключ создан!' as status,
  tc.constraint_name,
  ccu.table_schema || '.' || ccu.table_name AS references_table,
  ccu.column_name AS references_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'tasks'
  AND kcu.column_name = 'user_id';
