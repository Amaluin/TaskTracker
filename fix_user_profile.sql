-- ============================================
-- ИСПРАВЛЕНИЕ ПРОБЛЕМЫ С ПРОФИЛЯМИ
-- ============================================
-- Этот скрипт создает профили для пользователей,
-- у которых они не были созданы автоматически
-- 
-- ВАЖНО: Запускайте ПОСЛЕ database_auth_migration.sql!
-- ============================================

-- Проверяем, существует ли таблица user_profiles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'user_profiles'
  ) THEN
    RAISE EXCEPTION '
╔═══════════════════════════════════════════════════════════╗
║  ⚠️  ОШИБКА: Таблица user_profiles не существует!        ║
╚═══════════════════════════════════════════════════════════╝

ПРИЧИНА:
  Вы запустили fix_user_profile.sql ДО применения
  основной миграции database_auth_migration.sql

РЕШЕНИЕ:
  1. Сначала примените: database_auth_migration.sql
  2. Затем примените: fix_user_profile.sql

ПОРЯДОК ДЕЙСТВИЙ:
  1. SQL Editor → New query
  2. Скопируйте database_auth_migration.sql
  3. Выполните (Run)
  4. Дождитесь завершения
  5. Затем выполните fix_user_profile.sql
';
  END IF;
  
  RAISE NOTICE '✓ Таблица user_profiles существует. Продолжаем...';
END $$;

-- Проверяем, есть ли пользователи без профилей
DO $$
DECLARE
  missing_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO missing_count
  FROM auth.users au
  LEFT JOIN public.user_profiles up ON au.id = up.id
  WHERE up.id IS NULL;
  
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Пользователей без профилей: %', missing_count;
  RAISE NOTICE '============================================';
END $$;

-- Создаем профили для всех пользователей, у которых их нет
INSERT INTO public.user_profiles (id, phone, display_name)
SELECT 
  au.id,
  COALESCE(au.raw_user_meta_data->>'phone', ''),
  COALESCE(
    au.raw_user_meta_data->>'display_name',
    au.raw_user_meta_data->>'name',
    'Пользователь'
  )
FROM auth.users au
LEFT JOIN public.user_profiles up ON au.id = up.id
WHERE up.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- Проверяем результат
DO $$
DECLARE
  total_users INTEGER;
  total_profiles INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_users FROM auth.users;
  SELECT COUNT(*) INTO total_profiles FROM public.user_profiles;
  
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Всего пользователей: %', total_users;
  RAISE NOTICE 'Всего профилей: %', total_profiles;
  
  IF total_users = total_profiles THEN
    RAISE NOTICE '✓ Все пользователи имеют профили!';
  ELSE
    RAISE WARNING '⚠ Несоответствие количества пользователей и профилей!';
  END IF;
  RAISE NOTICE '============================================';
END $$;
