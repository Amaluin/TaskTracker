#!/bin/bash

# Скрипт для генерации JWT токенов для Supabase
# Использование: bash generate-jwt.sh [JWT_SECRET]

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "==================================="
echo "Генератор JWT токенов для Supabase"
echo "==================================="
echo ""

# Проверка наличия jq
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Внимание: jq не установлен. Устанавливаю...${NC}"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y jq
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install jq
    else
        echo "Пожалуйста, установите jq вручную: https://stedolan.github.io/jq/download/"
        exit 1
    fi
fi

# Получение JWT Secret
if [ -z "$1" ]; then
    echo "Введите JWT Secret (или нажмите Enter для генерации нового):"
    read -r JWT_SECRET
    
    if [ -z "$JWT_SECRET" ]; then
        JWT_SECRET=$(openssl rand -base64 32)
        echo -e "${GREEN}Сгенерирован новый JWT Secret:${NC}"
        echo "$JWT_SECRET"
        echo ""
    fi
else
    JWT_SECRET=$1
fi

# Функция для генерации JWT токена
generate_jwt() {
    local role=$1
    local exp=$2
    
    # Header
    header='{"alg":"HS256","typ":"JWT"}'
    
    # Payload
    payload="{\"iss\":\"supabase\",\"role\":\"$role\",\"exp\":$exp}"
    
    # Base64 URL encode
    header_base64=$(echo -n "$header" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
    payload_base64=$(echo -n "$payload" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
    
    # Signature
    signature=$(echo -n "${header_base64}.${payload_base64}" | openssl dgst -sha256 -hmac "$JWT_SECRET" -binary | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
    
    # JWT Token
    echo "${header_base64}.${payload_base64}.${signature}"
}

# Генерация токенов
echo "==================================="
echo -e "${GREEN}Генерация токенов...${NC}"
echo "==================================="
echo ""

# Expiration time (100 лет в будущем)
exp_time=$(($(date +%s) + 3153600000))

# Anon Key
echo "ANON KEY (для публичного доступа):"
anon_key=$(generate_jwt "anon" "$exp_time")
echo "$anon_key"
echo ""

# Service Role Key
echo "SERVICE ROLE KEY (для серверных операций):"
service_key=$(generate_jwt "service_role" "$exp_time")
echo "$service_key"
echo ""

# Authenticated Key
echo "AUTHENTICATED KEY (для авторизованных пользователей):"
authenticated_key=$(generate_jwt "authenticated" "$exp_time")
echo "$authenticated_key"
echo ""

# Сохранение в файл
echo "==================================="
echo "Сохранение в файл..."
echo "==================================="

cat > jwt-keys.txt << EOF
# Supabase JWT Keys
# Сгенерировано: $(date)

JWT_SECRET=$JWT_SECRET

ANON_KEY=$anon_key

SERVICE_ROLE_KEY=$service_key

AUTHENTICATED_KEY=$authenticated_key

# Использование:
# 1. Обновите docker-compose.supabase.yml с JWT_SECRET
# 2. Используйте ANON_KEY в Flutter приложении (lib/core/constants.dart)
# 3. Используйте SERVICE_ROLE_KEY для серверных операций
# 4. AUTHENTICATED_KEY используется автоматически после входа пользователя

# ВАЖНО: Храните эти ключи в безопасности!
# Не коммитьте их в Git!
EOF

echo -e "${GREEN}Ключи сохранены в jwt-keys.txt${NC}"
echo ""

# Обновление .env файла
if [ -f ".env" ]; then
    echo "Обновить .env файл? (y/n)"
    read -r -n 1 response
    echo ""
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Создание резервной копии
        cp .env .env.backup
        
        # Обновление значений
        sed -i.bak "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|g" .env
        sed -i.bak "s|SUPABASE_ANON_KEY=.*|SUPABASE_ANON_KEY=$anon_key|g" .env
        sed -i.bak "s|SUPABASE_SERVICE_KEY=.*|SUPABASE_SERVICE_KEY=$service_key|g" .env
        
        rm .env.bak
        
        echo -e "${GREEN}.env файл обновлен (резервная копия: .env.backup)${NC}"
    fi
fi

echo ""
echo "==================================="
echo -e "${GREEN}Готово!${NC}"
echo "==================================="
echo ""
echo "Следующие шаги:"
echo "1. Обновите docker-compose.supabase.yml с новыми ключами"
echo "2. Перезапустите Supabase: docker-compose -f docker-compose.supabase.yml restart"
echo "3. Обновите lib/core/constants.dart с ANON_KEY"
echo ""
