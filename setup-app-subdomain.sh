#!/bin/bash
# ============================================
# БЫСТРАЯ НАСТРОЙКА app.bike53.ru
# ============================================

set -e

DOMAIN="app.bike53.ru"
WEB_ROOT="/var/www/$DOMAIN"

echo "🚀 Настройка $DOMAIN"
echo ""

# 1. Создать директорию
echo "📁 Создание директории..."
mkdir -p "$WEB_ROOT"
echo "✓ Создано: $WEB_ROOT"

# 2. Копировать конфигурацию
echo ""
echo "📝 Настройка Nginx..."
cp /tmp/nginx-flutter-app-no-ssl.conf /etc/nginx/sites-available/$DOMAIN
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
echo "✓ Конфигурация установлена"

# 3. Проверить Nginx
echo ""
echo "🔍 Проверка конфигурации..."
if nginx -t; then
    echo "✓ Конфигурация корректна"
else
    echo "✗ Ошибка в конфигурации!"
    exit 1
fi

# 4. Перезагрузить Nginx
echo ""
echo "🔄 Перезагрузка Nginx..."
systemctl reload nginx
echo "✓ Nginx перезагружен"

# 5. Получить SSL сертификат
echo ""
echo "🔒 Получение SSL сертификата..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@bike53.ru --redirect
echo "✓ SSL сертификат установлен"

# 6. Настроить права
echo ""
echo "🔐 Настройка прав доступа..."
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"
echo "✓ Права настроены"

echo ""
echo "✅ Готово!"
echo ""
echo "📝 Следующие шаги:"
echo ""
echo "1. Соберите приложение:"
echo "   flutter build web --release"
echo ""
echo "2. Загрузите файлы:"
echo "   scp -r build/web/* root@185.225.34.252:$WEB_ROOT/"
echo ""
echo "3. Откройте в браузере:"
echo "   https://$DOMAIN"
echo ""
