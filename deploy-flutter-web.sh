#!/bin/bash
# ============================================
# СКРИПТ РАЗВЕРТЫВАНИЯ FLUTTER WEB APP
# ============================================

set -e

echo "🚀 Развертывание Flutter Web приложения на app.bike53.ru"
echo ""

# Переменные
DOMAIN="app.bike53.ru"
WEB_ROOT="/var/www/$DOMAIN"
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
SERVER_IP="185.225.34.252"

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Проверка: запущен ли скрипт на сервере
if [ "$(hostname -I | grep -o '^[0-9.]*')" != "$SERVER_IP" ]; then
    log_error "Этот скрипт должен быть запущен на сервере $SERVER_IP"
    echo ""
    echo "Выполните:"
    echo "  scp deploy-flutter-web.sh root@$SERVER_IP:/tmp/"
    echo "  scp nginx-flutter-app.conf root@$SERVER_IP:/tmp/"
    echo "  ssh root@$SERVER_IP"
    echo "  chmod +x /tmp/deploy-flutter-web.sh"
    echo "  /tmp/deploy-flutter-web.sh"
    exit 1
fi

echo "📋 Шаг 1: Создание директории для приложения"
mkdir -p "$WEB_ROOT"
log_info "Директория создана: $WEB_ROOT"

echo ""
echo "📋 Шаг 2: Копирование Nginx конфигурации"
if [ -f "/tmp/nginx-flutter-app.conf" ]; then
    cp /tmp/nginx-flutter-app.conf "$NGINX_CONF"
    log_info "Конфигурация скопирована"
else
    log_error "Файл /tmp/nginx-flutter-app.conf не найден!"
    echo "Загрузите его командой:"
    echo "  scp nginx-flutter-app.conf root@$SERVER_IP:/tmp/"
    exit 1
fi

echo ""
echo "📋 Шаг 3: Активация конфигурации Nginx"
ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
log_info "Конфигурация активирована"

echo ""
echo "📋 Шаг 4: Проверка конфигурации Nginx"
if nginx -t; then
    log_info "Конфигурация Nginx корректна"
else
    log_error "Ошибка в конфигурации Nginx!"
    exit 1
fi

echo ""
echo "📋 Шаг 5: Получение SSL сертификата"
if [ ! -f "/etc/letsencrypt/live/bike53.ru/fullchain.pem" ]; then
    log_warn "SSL сертификат не найден, получаем новый..."
    certbot certonly --nginx -d "$DOMAIN" --non-interactive --agree-tos --email admin@bike53.ru
    log_info "SSL сертификат получен"
else
    log_info "SSL сертификат уже существует"
fi

echo ""
echo "📋 Шаг 6: Перезагрузка Nginx"
systemctl reload nginx
log_info "Nginx перезагружен"

echo ""
echo "📋 Шаг 7: Настройка прав доступа"
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"
log_info "Права доступа настроены"

echo ""
echo "✅ Развертывание завершено!"
echo ""
echo "📝 Следующие шаги:"
echo ""
echo "1. На вашем компьютере соберите приложение:"
echo "   flutter build web --release"
echo ""
echo "2. Загрузите файлы на сервер:"
echo "   scp -r build/web/* root@$SERVER_IP:$WEB_ROOT/"
echo ""
echo "3. Откройте в браузере:"
echo "   https://$DOMAIN"
echo ""
echo "🎉 Готово!"
