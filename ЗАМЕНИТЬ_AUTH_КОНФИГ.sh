#!/bin/bash
# ============================================
# ПОЛНАЯ ЗАМЕНА AUTH КОНФИГУРАЦИИ
# ============================================

set -e

echo "🔧 Замена конфигурации Auth..."
echo ""

# Путь к .env (измените если нужно)
ENV_FILE="/home/supabase/supabase/docker/.env"
DOCKER_DIR="/home/supabase/supabase/docker"

# Проверка существования файла
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Файл .env не найден: $ENV_FILE"
    echo "Укажите правильный путь к .env файлу"
    exit 1
fi

echo "✓ Найден .env: $ENV_FILE"
echo ""

# Резервная копия
BACKUP_FILE="${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$ENV_FILE" "$BACKUP_FILE"
echo "✓ Создана резервная копия: $BACKUP_FILE"
echo ""

# Удаляем все старые GOTRUE_* переменные
echo "🗑️  Удаление старых GOTRUE_* переменных..."
sed -i '/^GOTRUE_/d' "$ENV_FILE"
echo "✓ Старые переменные удалены"
echo ""

# Добавляем новые настройки
echo "➕ Добавление новых настроек Auth..."
cat >> "$ENV_FILE" << 'EOF'

# ============================================
# AUTH КОНФИГУРАЦИЯ (обновлено автоматически)
# ============================================

# Основные
GOTRUE_SITE_URL=https://api.bike53.ru
GOTRUE_URI_ALLOW_LIST=*
GOTRUE_DISABLE_SIGNUP=false
GOTRUE_JWT_EXP=3600
GOTRUE_JWT_AUD=authenticated
GOTRUE_JWT_DEFAULT_GROUP_NAME=authenticated

# Email ОТКЛЮЧЕН
GOTRUE_MAILER_AUTOCONFIRM=true
GOTRUE_SMTP_HOST=
GOTRUE_SMTP_PORT=587
GOTRUE_SMTP_USER=
GOTRUE_SMTP_PASS=

# Провайдеры
GOTRUE_EXTERNAL_EMAIL_ENABLED=true
GOTRUE_EXTERNAL_PHONE_ENABLED=false

# Безопасность
GOTRUE_PASSWORD_MIN_LENGTH=6

# Rate Limiting ОТКЛЮЧЕН
GOTRUE_RATE_LIMIT_EMAIL_SENT=10000
GOTRUE_RATE_LIMIT_TOKEN_REFRESH=10000
GOTRUE_RATE_LIMIT_VERIFY=10000

# API
GOTRUE_API_HOST=0.0.0.0
GOTRUE_API_PORT=9999
GOTRUE_API_EXTERNAL_URL=https://api.bike53.ru

# Логирование
GOTRUE_LOG_LEVEL=debug

# Database
GOTRUE_DB_DRIVER=postgres

EOF

echo "✓ Новые настройки добавлены"
echo ""

# Перезапуск Auth
echo "🔄 Перезапуск Auth сервиса..."
cd "$DOCKER_DIR"
docker-compose stop auth
sleep 2
docker-compose start auth
sleep 5

echo ""
echo "📋 Проверка статуса..."
docker ps | grep auth

echo ""
echo "🔍 Последние логи Auth:"
docker logs --tail 20 supabase-auth

echo ""
echo "✅ Проверка health endpoint..."
curl -s http://localhost:9999/health || echo "❌ Health endpoint не отвечает"

echo ""
echo "🎉 Готово!"
echo ""
echo "Попробуйте зарегистрироваться в приложении."
echo ""
echo "Если не работает, выполните:"
echo "  docker logs --tail 50 supabase-auth"
echo ""
