#!/bin/bash

# Скрипт для настройки Supabase с Nginx
# Использование: sudo bash setup-supabase.sh

set -e

echo "==================================="
echo "Настройка Supabase с Nginx"
echo "==================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка прав root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Пожалуйста, запустите скрипт с правами root (sudo)${NC}"
    exit 1
fi

# Функция для вывода сообщений
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Шаг 1: Проверка установки Nginx
echo ""
echo "Шаг 1: Проверка Nginx..."
if ! command -v nginx &> /dev/null; then
    print_warning "Nginx не установлен. Устанавливаю..."
    apt update
    apt install -y nginx
    print_status "Nginx установлен"
else
    print_status "Nginx уже установлен"
fi

# Шаг 2: Проверка установки Docker
echo ""
echo "Шаг 2: Проверка Docker..."
if ! command -v docker &> /dev/null; then
    print_warning "Docker не установлен. Устанавливаю..."
    apt update
    apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    print_status "Docker установлен"
else
    print_status "Docker уже установлен"
fi

# Шаг 3: Проверка установки Docker Compose
echo ""
echo "Шаг 3: Проверка Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    print_warning "Docker Compose не установлен. Устанавливаю..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_status "Docker Compose установлен"
else
    print_status "Docker Compose уже установлен"
fi

# Шаг 4: Установка Certbot
echo ""
echo "Шаг 4: Установка Certbot для SSL..."
if ! command -v certbot &> /dev/null; then
    print_warning "Certbot не установлен. Устанавливаю..."
    apt update
    apt install -y certbot python3-certbot-nginx
    print_status "Certbot установлен"
else
    print_status "Certbot уже установлен"
fi

# Шаг 5: Получение SSL сертификатов
echo ""
echo "Шаг 5: Получение SSL сертификатов..."
read -p "Получить SSL сертификаты для api.bike53.ru и studio.bike53.ru? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Убедитесь, что DNS записи настроены правильно!"
    
    # Получение сертификата для api.bike53.ru
    if [ ! -d "/etc/letsencrypt/live/api.bike53.ru" ]; then
        certbot certonly --nginx -d api.bike53.ru --non-interactive --agree-tos --email admin@bike53.ru
        print_status "Сертификат для api.bike53.ru получен"
    else
        print_status "Сертификат для api.bike53.ru уже существует"
    fi
    
    # Получение сертификата для studio.bike53.ru
    if [ ! -d "/etc/letsencrypt/live/studio.bike53.ru" ]; then
        certbot certonly --nginx -d studio.bike53.ru --non-interactive --agree-tos --email admin@bike53.ru
        print_status "Сертификат для studio.bike53.ru получен"
    else
        print_status "Сертификат для studio.bike53.ru уже существует"
    fi
else
    print_warning "Пропускаю получение SSL сертификатов"
    print_warning "Вам нужно будет получить их вручную или обновить конфигурацию Nginx"
fi

# Шаг 6: Копирование конфигурации Nginx
echo ""
echo "Шаг 6: Установка конфигурации Nginx..."
if [ -f "nginx-supabase.conf" ]; then
    cp nginx-supabase.conf /etc/nginx/sites-available/supabase
    
    # Создание символической ссылки
    if [ ! -L "/etc/nginx/sites-enabled/supabase" ]; then
        ln -s /etc/nginx/sites-available/supabase /etc/nginx/sites-enabled/
        print_status "Конфигурация Nginx установлена"
    else
        print_status "Символическая ссылка уже существует"
    fi
    
    # Проверка конфигурации
    if nginx -t; then
        print_status "Конфигурация Nginx корректна"
    else
        print_error "Ошибка в конфигурации Nginx"
        exit 1
    fi
else
    print_error "Файл nginx-supabase.conf не найден"
    exit 1
fi

# Шаг 7: Настройка Firewall
echo ""
echo "Шаг 7: Настройка Firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    print_status "Firewall настроен (порты 80 и 443 открыты)"
else
    print_warning "UFW не установлен, пропускаю настройку firewall"
fi

# Шаг 8: Создание директорий для Supabase
echo ""
echo "Шаг 8: Создание директорий для Supabase..."
mkdir -p volumes/db/data
mkdir -p volumes/storage
mkdir -p volumes/kong
print_status "Директории созданы"

# Шаг 9: Генерация секретов
echo ""
echo "Шаг 9: Генерация секретов..."
print_warning "ВАЖНО: Сохраните эти секреты в безопасном месте!"
echo ""
echo "JWT Secret (используйте в docker-compose.supabase.yml):"
openssl rand -base64 32
echo ""
echo "Postgres Password (используйте в docker-compose.supabase.yml):"
openssl rand -base64 32
echo ""

# Шаг 10: Перезапуск Nginx
echo ""
echo "Шаг 10: Перезапуск Nginx..."
systemctl restart nginx
print_status "Nginx перезапущен"

# Финальные инструкции
echo ""
echo "==================================="
echo -e "${GREEN}Установка завершена!${NC}"
echo "==================================="
echo ""
echo "Следующие шаги:"
echo "1. Обновите docker-compose.supabase.yml с сгенерированными секретами"
echo "2. Запустите Supabase: docker-compose -f docker-compose.supabase.yml up -d"
echo "3. Проверьте статус: docker-compose -f docker-compose.supabase.yml ps"
echo "4. Откройте Studio: https://studio.bike53.ru"
echo "5. Получите Anon Key из Studio и обновите lib/core/constants.dart"
echo ""
echo "Полезные команды:"
echo "  - Просмотр логов: docker-compose -f docker-compose.supabase.yml logs -f"
echo "  - Остановка: docker-compose -f docker-compose.supabase.yml down"
echo "  - Перезапуск: docker-compose -f docker-compose.supabase.yml restart"
echo ""
echo "Документация: см. SUPABASE_NGINX_SETUP.md"
echo ""
