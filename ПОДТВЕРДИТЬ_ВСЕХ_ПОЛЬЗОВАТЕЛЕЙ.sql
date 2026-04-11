-- ============================================
-- ПОДТВЕРЖДЕНИЕ ВСЕХ ПОЛЬЗОВАТЕЛЕЙ
-- ============================================
-- Этот скрипт подтверждает всех пользователей
-- чтобы они могли войти без email подтверждения
-- ============================================

-- Показываем текущее состояние
SELECT 
  id,
  email,
  email_confirmed_at,
  confirmed_at,
  CASE 
    WHEN email_confirmed_at IS NULL THEN '❌ Не подтвержден'
    ELSE '✅ Подтвержден'
  END as status
FROM auth.users;

-- Подтверждаем всех пользователей
UPDATE auth.users
SET 
  email_confirmed_at = NOW(),
  phone_confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;

-- Показываем результат
SELECT 
  id,
  email,
  email_confirmed_at,
  confirmed_at,
  '✅ Подтвержден' as status
FROM auth.users;

-- Сообщение
DO $$
DECLARE
  user_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO user_count FROM auth.users;
  
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ Все пользователи подтверждены!';
  RAISE NOTICE 'Всего пользователей: %', user_count;
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Теперь все пользователи могут войти в систему';
  RAISE NOTICE 'без подтверждения email.';
  RAISE NOTICE '';
  RAISE NOTICE 'Попробуйте войти в приложение!';
  RAISE NOTICE '============================================';
END $$;
