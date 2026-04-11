-- ============================================
-- ДИАГНОСТИКА ВНЕШНИХ КЛЮЧЕЙ
-- ============================================
-- Этот скрипт проверяет и исправляет внешние ключи
-- ============================================

-- 1. Проверяем текущие внешние ключи на таблице tasks
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_schema AS foreign_table_schema,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'tasks'
  AND kcu.column_name = 'user_id';

-- 2. Проверяем, существует ли пользователь в auth.users
DO $$
DECLARE
  test_user_id UUID := 'bbea4612-574b-433f-bc10-9a227c74d780';
  user_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM auth.users WHERE id = test_user_id
  ) INTO user_exists;
  
  IF user_exists THEN
    RAISE NOTICE '✓ Пользователь % существует в auth.users', test_user_id;
  ELSE
    RAISE NOTICE '✗ Пользователь % НЕ существует в auth.users', test_user_id;
  END IF;
END $$;

-- 3. Проверяем, есть ли таблица public.users (не должно быть)
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'users'
  ) THEN
    RAISE WARNING '⚠️  Найдена таблица public.users - это может быть проблемой!';
    RAISE NOTICE 'Внешний ключ должен ссылаться на auth.users, а не на public.users';
  ELSE
    RAISE NOTICE '✓ Таблица public.users не существует (это правильно)';
  END IF;
END $$;

-- 4. Показываем всех пользователей в auth.users
DO $$
BEGIN
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Пользователи в auth.users:';
  RAISE NOTICE '============================================';
END $$;

SELECT 
  id,
  email,
  created_at,
  raw_user_meta_data->>'phone' as phone
FROM auth.users
ORDER BY created_at DESC;

-- 5. Показываем профили (если таблица существует)
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'user_profiles'
  ) THEN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Профили в user_profiles:';
    RAISE NOTICE '============================================';
  ELSE
    RAISE WARNING '⚠️  Таблица user_profiles НЕ СУЩЕСТВУЕТ!';
    RAISE NOTICE '';
    RAISE NOTICE '╔═══════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ⚠️  КРИТИЧЕСКАЯ ОШИБКА!                                 ║';
    RAISE NOTICE '╚═══════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE 'Вы НЕ применили основную миграцию!';
    RAISE NOTICE '';
    RAISE NOTICE 'РЕШЕНИЕ:';
    RAISE NOTICE '1. Закройте этот запрос';
    RAISE NOTICE '2. SQL Editor → New query';
    RAISE NOTICE '3. Скопируйте файл: database_auth_migration.sql';
    RAISE NOTICE '4. Выполните его (Run)';
    RAISE NOTICE '5. Дождитесь завершения';
    RAISE NOTICE '6. Затем выполните diagnose_foreign_keys.sql снова';
    RAISE NOTICE '';
    RAISE NOTICE '╔═══════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  БЕЗ database_auth_migration.sql НИЧЕГО НЕ РАБОТАЕТ!    ║';
    RAISE NOTICE '╚═══════════════════════════════════════════════════════════╝';
  END IF;
END $$;

SELECT * FROM public.user_profiles WHERE EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'user_profiles'
);

-- ============================================
-- ИСПРАВЛЕНИЕ (только если таблица user_profiles существует)
-- ============================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'user_profiles'
  ) THEN
    RAISE EXCEPTION '
╔═══════════════════════════════════════════════════════════╗
║  🛑 ОСТАНОВКА! ТАБЛИЦА user_profiles НЕ СУЩЕСТВУЕТ       ║
╚═══════════════════════════════════════════════════════════╝

ВЫ ПРОПУСТИЛИ ОСНОВНУЮ МИГРАЦИЮ!

Этот скрипт (diagnose_foreign_keys.sql) предназначен для
ИСПРАВЛЕНИЯ проблем, но основная структура БД должна быть
создана СНАЧАЛА.

═══════════════════════════════════════════════════════════
ПРАВИЛЬНЫЙ ПОРЯДОК:
═══════════════════════════════════════════════════════════

1️⃣  database_auth_migration.sql  ← СНАЧАЛА ЭТО!
    (создает таблицы, ключи, политики)
    
2️⃣  fix_user_profile.sql
    (создает профили для пользователей)
    
3️⃣  diagnose_foreign_keys.sql    ← Вы здесь
    (исправляет проблемы с ключами)

═══════════════════════════════════════════════════════════
ЧТО ДЕЛАТЬ СЕЙЧАС:
═══════════════════════════════════════════════════════════

1. Закройте этот запрос
2. Откройте файл: ПРАВИЛЬНЫЙ_ПОРЯДОК.txt
3. Следуйте инструкциям
4. Начните с database_auth_migration.sql

═══════════════════════════════════════════════════════════
';
  END IF;
  
  RAISE NOTICE '✓ Таблица user_profiles существует. Продолжаем исправление...';
END $$;

-- Удаляем неправильный внешний ключ
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_user_id_fkey;

-- Создаем правильный внешний ключ на auth.users
ALTER TABLE tasks 
ADD CONSTRAINT tasks_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE
DEFERRABLE INITIALLY DEFERRED;

DO $$
BEGIN
  RAISE NOTICE '============================================';
  RAISE NOTICE '✓ Внешний ключ пересоздан!';
  RAISE NOTICE '✓ Теперь tasks.user_id → auth.users(id)';
  RAISE NOTICE '============================================';
END $$;

-- Проверяем результат
SELECT
  tc.constraint_name,
  ccu.table_schema || '.' || ccu.table_name AS references_table,
  ccu.column_name AS references_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'tasks'
  AND kcu.column_name = 'user_id';
