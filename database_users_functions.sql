-- ============================================
-- ФУНКЦИИ ДЛЯ РАБОТЫ С ПОЛЬЗОВАТЕЛЯМИ
-- ============================================

-- Функция для получения всех пользователей
CREATE OR REPLACE FUNCTION get_all_users()
RETURNS TABLE (
  id UUID,
  email TEXT,
  phone TEXT,
  raw_user_meta_data JSONB,
  created_at TIMESTAMPTZ
) 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    au.id::UUID,
    au.email::TEXT,
    au.phone::TEXT,
    au.raw_user_meta_data::JSONB,
    au.created_at::TIMESTAMPTZ
  FROM auth.users au
  ORDER BY au.created_at DESC;
END;
$$;

-- Функция для получения пользователя по ID
CREATE OR REPLACE FUNCTION get_user_by_id(user_id UUID)
RETURNS TABLE (
  id UUID,
  email TEXT,
  phone TEXT,
  raw_user_meta_data JSONB,
  created_at TIMESTAMPTZ
) 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    au.id::UUID,
    au.email::TEXT,
    au.phone::TEXT,
    au.raw_user_meta_data::JSONB,
    au.created_at::TIMESTAMPTZ
  FROM auth.users au
  WHERE au.id = user_id;
END;
$$;

-- Предоставляем права на выполнение функций
GRANT EXECUTE ON FUNCTION get_all_users() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_by_id(UUID) TO authenticated;

-- Комментарии
COMMENT ON FUNCTION get_all_users() IS 'Получить список всех пользователей';
COMMENT ON FUNCTION get_user_by_id(UUID) IS 'Получить пользователя по ID';
