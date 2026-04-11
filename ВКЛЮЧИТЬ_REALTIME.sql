-- ============================================
-- ВКЛЮЧЕНИЕ REALTIME ДЛЯ ТАБЛИЦЫ TASKS
-- ============================================

-- 1. Проверяем текущий статус Realtime
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename = 'tasks';

-- 2. Включаем Realtime для таблицы tasks
-- Это позволит клиентам подписываться на изменения в реальном времени
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;

-- 3. Проверяем, что таблица добавлена в публикацию
SELECT 
    pubname,
    schemaname,
    tablename
FROM pg_publication_tables
WHERE tablename = 'tasks';

-- 4. Проверяем права доступа
SELECT 
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.table_privileges
WHERE table_name = 'tasks'
  AND grantee IN ('authenticated', 'anon')
ORDER BY grantee, privilege_type;

-- 5. Убедимся, что RLS включен
SELECT 
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename = 'tasks';

-- ПРИМЕЧАНИЕ:
-- После выполнения этого скрипта, клиенты смогут подписываться на изменения:
-- - INSERT (создание новых задач)
-- - UPDATE (обновление задач, включая изменение статуса)
-- - DELETE (удаление задач)
--
-- В Flutter приложении это работает через:
-- supabase.channel('tasks_changes')
--   .onPostgresChanges(
--     event: PostgresChangeEvent.all,
--     schema: 'public',
--     table: 'tasks',
--     callback: (payload) { /* обработка */ }
--   )
--   .subscribe();
