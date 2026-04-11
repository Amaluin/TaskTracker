-- ============================================
-- НЕМЕДЛЕННОЕ ИСПРАВЛЕНИЕ ВНЕШНЕГО КЛЮЧА
-- ============================================
-- Выполните этот скрипт ПРЯМО СЕЙЧАС!
-- ============================================

-- Шаг 1: Показываем текущую проблему
SELECT
  'ТЕКУЩЕЕ СОСТОЯНИЕ:' as info,
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_schema AS foreign_schema,
  ccu.table_name AS foreign_table
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'tasks'
  AND tc.constraint_type = 'FOREIGN KEY'
  AND kcu.column_name = 'user_id';

-- Шаг 2: УДАЛЯЕМ неправильный внешний ключ
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_user_id_fkey;

-- Шаг 3: СОЗДАЕМ правильный внешний ключ на auth.users
ALTER TABLE tasks 
ADD CONSTRAINT tasks_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE;

-- Шаг 4: Проверяем результат
SELECT
  '✓ ИСПРАВЛЕНО!' as status,
  tc.constraint_name,
  ccu.table_schema || '.' || ccu.table_name AS now_references
FROM information_schema.table_constraints AS tc
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'tasks'
  AND tc.constraint_name = 'tasks_user_id_fkey';

-- Шаг 5: Проверяем, что пользователь существует
SELECT
  CASE 
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE id = 'bbea4612-574b-433f-bc10-9a227c74d780')
    THEN '✓ Пользователь существует в auth.users'
    ELSE '✗ Пользователь НЕ существует - нужна регистрация заново'
  END as user_check;
