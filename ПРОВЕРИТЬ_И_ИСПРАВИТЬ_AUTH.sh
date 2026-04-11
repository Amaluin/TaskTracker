#!/bin/bash
# ============================================
# ПРОВЕРКА И ИСПРАВЛЕНИЕ AUTH НАСТРОЕК
# ============================================

echo "🔍 Проверка настроек Auth..."
echo ""

# Проверяем текущие настройки
echo "📋 Текущие GOTRUE настройки в .env:"
cat /home/supabase/supabase/docker/.env | grep GOTRUE_MAILER
echo ""

# Проверяем переменные окружения в контейнере
echo "📋 Переменные окружения в контейнере Auth:"
docker exec supabase-auth env | grep GOTRUE_MAILER
echo ""

# Если GOTRUE_MAILER_AUTOCONFIRM не true, исправляем
if ! docker exec supabase-auth env | grep -q "GOTRUE_MAILER_AUTOCONFIRM=true"; then
    echo "❌ GOTRUE_MAILER_AUTOCONFIRM не установлен в true!"
    echo "🔧 Исправляем..."
    
    # Добавляем в .env если нет
    if ! grep -q "GOTRUE_MAILER_AUTOCONFIRM" /home/supabase/supabase/docker/.env; then
        echo "GOTRUE_MAILER_AUTOCONFIRM=true" >> /home/supabase/supabase/docker/.env
    else
        sed -i 's/GOTRUE_MAILER_AUTOCONFIRM=.*/GOTRUE_MAILER_AUTOCONFIRM=true/' /home/supabase/supabase/docker/.env
    fi
    
    echo "✅ Настройка добавлена в .env"
    echo ""
    echo "🔄 Перезапуск Auth..."
    cd /home/supabase/supabase/docker
    docker-compose restart auth
    sleep 5
    
    echo "✅ Auth перезапущен"
else
    echo "✅ GOTRUE_MAILER_AUTOCONFIRM уже установлен в true"
fi

echo ""
echo "🔍 Проверка после изменений:"
docker exec supabase-auth env | grep GOTRUE_MAILER
echo ""

echo "📋 Логи Auth (последние 20 строк):"
docker logs --tail 20 supabase-auth
echo ""

echo "✅ Готово!"
echo ""
echo "Теперь:"
echo "1. Примените SQL: ПОДТВЕРДИТЬ_ВСЕХ_ПОЛЬЗОВАТЕЛЕЙ.sql"
echo "2. Попробуйте войти в приложение"
