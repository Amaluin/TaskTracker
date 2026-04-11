#!/bin/bash
# ============================================
# ИСПРАВЛЕНИЕ AUTH - ОТКЛЮЧЕНИЕ EMAIL
# ============================================

echo "🔧 Исправление настроек Auth..."

# Путь к .env файлу (измените если нужно)
ENV_FILE="/home/supabase/supabase/docker/.env"

# Резервная копия
cp $ENV_FILE ${ENV_FILE}.backup

# Добавляем/обновляем настройки Auth
cat >> $ENV_FILE << 'EOF'

# ============================================
# AUTH НАСТРОЙКИ (добавлено автоматически)
# ============================================

# Отключить email подтверждение
GOTRUE_MAILER_AUTOCONFIRM=true

# Отключить email сервис
GOTRUE_SMTP_HOST=
GOTRUE_SMTP_PORT=
GOTRUE_SMTP_USER=
GOTRUE_SMTP_PASS=

# Разрешить регистрацию без email
GOTRUE_DISABLE_SIGNUP=false
GOTRUE_EXTERNAL_EMAIL_ENABLED=true

# Минимальная длина пароля
GOTRUE_PASSWORD_MIN_LENGTH=6

# Site URL
GOTRUE_SITE_URL=https://api.bike53.ru

# Отключить rate limiting для разработки
GOTRUE_RATE_LIMIT_EMAIL_SENT=1000
GOTRUE_RATE_LIMIT_TOKEN_REFRESH=1000
GOTRUE_RATE_LIMIT_VERIFY=1000

EOF

echo "✓ Настройки добавлены в .env"
echo ""
echo "🔄 Перезапуск Auth сервиса..."

# Перезапуск Auth
cd /home/supabase/supabase/docker
docker-compose restart auth

echo ""
echo "⏳ Ждем 5 секунд..."
sleep 5

echo ""
echo "✅ Проверка Auth..."
curl -s http://localhost:9999/health | jq .

echo ""
echo "🎉 Готово! Попробуйте зарегистрироваться снова."
