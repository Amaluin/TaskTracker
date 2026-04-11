-- Быстрая проверка функций пользователей

-- 1. Проверяем, есть ли пользователи в auth.users
SELECT 
    '=== Пользователи в auth.users ===' as info,
    COUNT(*) as total_users
FROM auth.users
WHERE deleted_at IS NULL;

SELECT 
    id,
    email,
    phone,
    raw_user_meta_data->>'name' as name,
    raw_user_meta_data->>'display_name' as display_name,
    created_at
FROM auth.users
WHERE deleted_at IS NULL
ORDER BY created_at DESC
LIMIT 5;

-- 2. Проверяем существование функций
SELECT 
    '=== Функции ===' as info,
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('get_all_users', 'get_user_by_id');

-- 3. Пробуем вызвать функцию get_all_users()
SELECT '=== Тест get_all_users() ===' as info;
SELECT * FROM get_all_users() LIMIT 5;

-- 4. Проверяем права
SELECT 
    '=== Права доступа ===' as info,
    routine_name,
    grantee,
    privilege_type
FROM information_schema.routine_privileges
WHERE routine_name IN ('get_all_users', 'get_user_by_id')
ORDER BY routine_name, grantee;
