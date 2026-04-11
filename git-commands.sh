#!/bin/bash

# ============================================
# Скрипт для публикации проекта на GitHub
# ============================================
# Использование: bash git-commands.sh
# Или скопируйте команды по одной
# ============================================

echo "============================================"
echo "Публикация Task Tracker на GitHub"
echo "============================================"
echo ""

# Проверка, что мы в правильной директории
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Ошибка: Запустите скрипт из корневой директории проекта!"
    exit 1
fi

echo "✓ Директория проекта найдена"
echo ""

# Шаг 1: Инициализация Git
echo "Шаг 1: Инициализация Git..."
if [ -d ".git" ]; then
    echo "⚠ Git уже инициализирован"
else
    git init
    echo "✓ Git инициализирован"
fi
echo ""

# Шаг 2: Добавление файлов
echo "Шаг 2: Добавление файлов..."
git add .
echo "✓ Файлы добавлены"
echo ""

# Шаг 3: Проверка, что конфиденциальные файлы не добавлены
echo "Шаг 3: Проверка безопасности..."
if git status | grep -q ".env"; then
    echo "❌ ВНИМАНИЕ: .env файл будет закоммичен!"
    echo "Удалите его из индекса: git rm --cached .env"
    exit 1
fi

if git status | grep -q "jwt-keys.txt"; then
    echo "❌ ВНИМАНИЕ: jwt-keys.txt будет закоммичен!"
    echo "Удалите его из индекса: git rm --cached jwt-keys.txt"
    exit 1
fi

echo "✓ Конфиденциальные файлы не найдены"
echo ""

# Шаг 4: Создание коммита
echo "Шаг 4: Создание первого коммита..."
git commit -m "Initial commit: Task Tracker with Supabase backend"
echo "✓ Коммит создан"
echo ""

# Шаг 5: Инструкции для GitHub
echo "============================================"
echo "Следующие шаги:"
echo "============================================"
echo ""
echo "1. Создайте репозиторий на GitHub:"
echo "   https://github.com/new"
echo ""
echo "2. Выполните команды (замените YOUR_USERNAME):"
echo ""
echo "   git remote add origin https://github.com/YOUR_USERNAME/task-tracker.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "============================================"
echo "Готово!"
echo "============================================"
