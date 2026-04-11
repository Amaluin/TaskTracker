#!/bin/bash

# Скрипт для упаковки всех файлов конфигурации Supabase
# Использование: bash pack-files.sh

echo "==================================="
echo "Упаковка файлов конфигурации Supabase"
echo "==================================="
echo ""

# Имя архива
ARCHIVE_NAME="supabase-config-$(date +%Y%m%d_%H%M%S).tar.gz"

# Список файлов для упаковки
FILES=(
    "nginx-supabase.conf"
    "docker-compose.supabase.yml"
    "kong.yml"
    ".env.example"
    "setup-supabase.sh"
    "generate-jwt.sh"
    "monitor-supabase.sh"
    "SUPABASE_README.md"
    "SUPABASE_NGINX_SETUP.md"
    "QUICK_START.md"
    "БЫСТРЫЙ_СТАРТ.md"
    "DEPLOYMENT_CHECKLIST.md"
    "ФАЙЛЫ_КОНФИГУРАЦИИ.md"
    "README_SUPABASE.md"
    "ИНСТРУКЦИЯ_ЗАГРУЗКИ.md"
    ".gitignore.supabase"
)

# Проверка наличия файлов
echo "Проверка файлов..."
missing_files=0
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "⚠ Файл не найден: $file"
        ((missing_files++))
    else
        echo "✓ $file"
    fi
done

echo ""

if [ $missing_files -gt 0 ]; then
    echo "⚠ Внимание: $missing_files файл(ов) не найдено"
    echo ""
    read -p "Продолжить упаковку? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Упаковка отменена"
        exit 1
    fi
fi

# Создание архива
echo "Создание архива $ARCHIVE_NAME..."
tar -czf "$ARCHIVE_NAME" "${FILES[@]}" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Архив создан успешно!"
    echo ""
    echo "Файл: $ARCHIVE_NAME"
    echo "Размер: $(du -h "$ARCHIVE_NAME" | cut -f1)"
    echo ""
    echo "==================================="
    echo "Следующие шаги:"
    echo "==================================="
    echo ""
    echo "1. Загрузите архив на сервер:"
    echo "   scp $ARCHIVE_NAME root@185.225.34.252:/opt/"
    echo ""
    echo "2. Подключитесь к серверу:"
    echo "   ssh root@185.225.34.252"
    echo ""
    echo "3. Распакуйте архив:"
    echo "   cd /opt"
    echo "   tar -xzf $ARCHIVE_NAME"
    echo "   cd /opt"
    echo ""
    echo "4. Установите права:"
    echo "   chmod +x setup-supabase.sh generate-jwt.sh monitor-supabase.sh"
    echo ""
    echo "5. Запустите установку:"
    echo "   sudo bash setup-supabase.sh"
    echo ""
else
    echo "✗ Ошибка при создании архива"
    exit 1
fi
