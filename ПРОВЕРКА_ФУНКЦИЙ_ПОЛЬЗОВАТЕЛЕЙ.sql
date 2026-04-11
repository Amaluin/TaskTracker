-- ============================================
-- ПРОВЕРКА И СОЗДАНИЕ ФУНКЦИЙ ДЛЯ ПОЛЬЗОВАТЕЛЕЙ
-- ============================================

-- 1. Проверяем существующие функции
SELECT 
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('get_all_users', 'get_user_by_id');

-- 2. Удаляем старые функции (если есть)
DROP FUNCTION IF EXISTS get_all_users();
DROP FUNCTION IF EXISTS get_user_by_id(UUID);

-- 3. Создаем функцию для получения всех пользователей
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
    au.id,
    au.email,
    au.phone,
    au.raw_user_meta_data,
    au.created_at
  FROM auth.users au
  WHERE au.deleted_at IS NULL  -- Только активные пользователи
  ORDER BY au.created_at DESC;
END;
$$;

-- 4. Создаем функцию для получения пользователя по ID
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
    au.id,
    au.email,
    au.phone,
    au.raw_user_meta_data,
    au.created_at
  FROM auth.users au
  WHERE au.id = user_id
    AND au.deleted_at IS NULL;
END;
$$;

-- 5. Предоставляем права на выполнение
GRANT EXECUTE ON FUNCTION get_all_users() TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_users() TO anon;
GRANT EXECUTE ON FUNCTION get_user_by_id(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_by_id(UUID) TO anon;

-- 6. Добавляем комментарии
COMMENT ON FUNCTION get_all_users() IS 'Получить список всех активных пользователей';
COMMENT ON FUNCTION get_user_by_id(UUID) IS 'Получить пользователя по ID';

-- 7. Тестируем функции
SELECT '=== Тест get_all_users() ===' as test;
SELECT * FROM get_all_users();

SELECT '=== Проверка прав ===' as test;
SELECT 
    routine_name,
    grantee,
    privilege_type
FROM information_schema.routine_privileges
WHERE routine_name IN ('get_all_users', 'get_user_by_id')
ORDER BY routine_name, grantee;
