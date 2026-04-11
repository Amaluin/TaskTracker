#!/bin/bash
# ============================================
# ИСПРАВЛЕНИЕ SUPABASE POOLER
# ============================================

echo "🔧 Исправление Supabase Pooler..."
echo ""

cd /home/supabase/supabase/docker

# Остановить pooler
echo "⏸️  Остановка pooler..."
docker compose stop supabase-pooler

# Удалить контейнер
echo "🗑️  Удаление контейнера..."
docker compose rm -f supabase-pooler

# Запустить без pooler (он опционален)
echo "✅ Pooler отключен"
echo ""
echo "Проверьте работу приложения:"
echo "https://app.bike53.ru"
echo ""
echo "Если всё работает, pooler не нужен."
echo "Если нужен pooler, обновите Supabase до последней версии."
