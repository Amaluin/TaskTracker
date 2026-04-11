#!/bin/bash

# Скрипт мониторинга Supabase
# Использование: bash monitor-supabase.sh

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
print_header() {
    echo -e "${BLUE}==================================="
    echo -e "$1"
    echo -e "===================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Проверка наличия docker-compose
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose не установлен"
    exit 1
fi

clear
print_header "Мониторинг Supabase"
echo ""

# 1. Проверка статуса контейнеров
print_header "1. Статус Docker контейнеров"
echo ""

CONTAINERS=("supabase-db" "supabase-kong" "supabase-auth" "supabase-rest" "supabase-realtime" "supabase-storage" "supabase-studio" "supabase-meta")

for container in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
        if [ "$status" == "running" ]; then
            print_success "$container: Running"
        else
            print_error "$container: $status"
        fi
    else
        print_error "$container: Not found"
    fi
done

echo ""

# 2. Проверка использования ресурсов
print_header "2. Использование ресурсов"
echo ""

docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep supabase

echo ""

# 3. Проверка портов
print_header "3. Проверка портов"
echo ""

PORTS=("8000:Kong" "54321:Studio" "54323:Auth" "54324:REST" "54325:Realtime" "54326:Storage" "5432:PostgreSQL")

for port_info in "${PORTS[@]}"; do
    port="${port_info%%:*}"
    name="${port_info##*:}"
    
    if sudo netstat -tulpn 2>/dev/null | grep -q ":$port "; then
        print_success "$name (port $port): Listening"
    else
        print_error "$name (port $port): Not listening"
    fi
done

echo ""

# 4. Проверка Nginx
print_header "4. Статус Nginx"
echo ""

if systemctl is-active --quiet nginx; then
    print_success "Nginx: Running"
    
    # Проверка конфигурации
    if sudo nginx -t &>/dev/null; then
        print_success "Nginx configuration: Valid"
    else
        print_error "Nginx configuration: Invalid"
    fi
else
    print_error "Nginx: Not running"
fi

echo ""

# 5. Проверка SSL сертификатов
print_header "5. SSL Сертификаты"
echo ""

DOMAINS=("api.bike53.ru" "studio.bike53.ru")

for domain in "${DOMAINS[@]}"; do
    cert_path="/etc/letsencrypt/live/$domain/fullchain.pem"
    
    if [ -f "$cert_path" ]; then
        expiry=$(sudo openssl x509 -enddate -noout -in "$cert_path" | cut -d= -f2)
        expiry_epoch=$(date -d "$expiry" +%s)
        now_epoch=$(date +%s)
        days_left=$(( ($expiry_epoch - $now_epoch) / 86400 ))
        
        if [ $days_left -gt 30 ]; then
            print_success "$domain: Valid ($days_left days left)"
        elif [ $days_left -gt 7 ]; then
            print_warning "$domain: Expires soon ($days_left days left)"
        else
            print_error "$domain: Expires very soon ($days_left days left)"
        fi
    else
        print_error "$domain: Certificate not found"
    fi
done

echo ""

# 6. Проверка API endpoints
print_header "6. API Endpoints"
echo ""

# Health check
if curl -s -o /dev/null -w "%{http_code}" https://api.bike53.ru/health 2>/dev/null | grep -q "200"; then
    print_success "API Health: OK"
else
    print_error "API Health: Failed"
fi

# Studio
if curl -s -o /dev/null -w "%{http_code}" https://studio.bike53.ru 2>/dev/null | grep -q "200"; then
    print_success "Studio: OK"
else
    print_error "Studio: Failed"
fi

echo ""

# 7. Проверка дискового пространства
print_header "7. Дисковое пространство"
echo ""

# Общее использование
df -h / | tail -n 1 | awk '{print "Root: " $3 " / " $2 " (" $5 " used)"}'

# Размер volumes
if [ -d "volumes" ]; then
    db_size=$(du -sh volumes/db 2>/dev/null | cut -f1)
    storage_size=$(du -sh volumes/storage 2>/dev/null | cut -f1)
    
    print_info "Database volume: $db_size"
    print_info "Storage volume: $storage_size"
fi

echo ""

# 8. Последние ошибки в логах
print_header "8. Последние ошибки (последние 10)"
echo ""

echo "Nginx errors:"
sudo tail -n 10 /var/log/nginx/error.log 2>/dev/null | grep -i error | tail -n 3 || echo "No recent errors"

echo ""
echo "Docker errors:"
docker-compose -f docker-compose.supabase.yml logs --tail=50 2>/dev/null | grep -i error | tail -n 3 || echo "No recent errors"

echo ""

# 9. Проверка подключения к базе данных
print_header "9. База данных"
echo ""

if docker exec supabase-db psql -U postgres -c "SELECT version();" &>/dev/null; then
    print_success "PostgreSQL: Connected"
    
    # Размер базы данных
    db_size=$(docker exec supabase-db psql -U postgres -t -c "SELECT pg_size_pretty(pg_database_size('postgres'));" 2>/dev/null | xargs)
    print_info "Database size: $db_size"
    
    # Количество подключений
    connections=$(docker exec supabase-db psql -U postgres -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | xargs)
    print_info "Active connections: $connections"
else
    print_error "PostgreSQL: Connection failed"
fi

echo ""

# 10. Uptime
print_header "10. Uptime"
echo ""

for container in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        uptime=$(docker inspect --format='{{.State.StartedAt}}' "$container" 2>/dev/null)
        if [ -n "$uptime" ]; then
            echo "$container: Started at $uptime"
        fi
    fi
done

echo ""

# Итоговая информация
print_header "Итого"
echo ""

# Подсчет работающих контейнеров
running_count=0
for container in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
        if [ "$status" == "running" ]; then
            ((running_count++))
        fi
    fi
done

total_count=${#CONTAINERS[@]}
echo "Контейнеры: $running_count/$total_count работают"

# Общий статус
if [ $running_count -eq $total_count ]; then
    print_success "Все сервисы работают нормально"
else
    print_warning "Некоторые сервисы не работают"
fi

echo ""
echo "Мониторинг завершен: $(date)"
echo ""

# Опция для непрерывного мониторинга
if [ "$1" == "--watch" ]; then
    echo "Обновление через 30 секунд..."
    sleep 30
    exec "$0" "$@"
fi
