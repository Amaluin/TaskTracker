-- ============================================
-- АВТОМАТИЧЕСКОЕ ПОДТВЕРЖДЕНИЕ ПОЛЬЗОВАТЕЛЕЙ
-- ============================================
-- Этот триггер автоматически подтверждает всех
-- новых пользователей при регистрации
-- ============================================

-- Создаем функцию для автоподтверждения
CREATE OR REPLACE FUNCTION public.auto_confirm_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Автоматически подтверждаем email и телефон
  -- confirmed_at вычисляется автоматически на основе email_confirmed_at
  NEW.email_confirmed_at = NOW();
  NEW.phone_confirmed_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Удаляем старый триггер если существует
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Создаем триггер на создание пользователя
CREATE TRIGGER on_auth_user_created
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_confirm_user();

-- Подтверждаем всех существующих пользователей
UPDATE auth.users
SET 
  email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
  phone_confirmed_at = COALESCE(phone_confirmed_at, NOW())
WHERE email_confirmed_at IS NULL;

-- Сообщение
DO $$
DECLARE
  user_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO user_count FROM auth.users;
  
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ Триггер автоподтверждения создан!';
  RAISE NOTICE 'Всего пользователей: %', user_count;
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Теперь все новые пользователи будут';
  RAISE NOTICE 'автоматически подтверждаться при регистрации.';
  RAISE NOTICE '';
  RAISE NOTICE 'Все существующие пользователи подтверждены.';
  RAISE NOTICE '============================================';
END $$;
