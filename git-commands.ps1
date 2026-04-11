# ============================================
# PowerShell скрипт для публикации на GitHub
# ============================================
# Использование: .\git-commands.ps1
# ============================================

Write-Host "============================================" -ForegroundColor Blue
Write-Host "Публикация Task Tracker на GitHub" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# Проверка, что мы в правильной директории
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ Ошибка: Запустите скрипт из корневой директории проекта!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Директория проекта найдена" -ForegroundColor Green
Write-Host ""

# Шаг 1: Инициализация Git
Write-Host "Шаг 1: Инициализация Git..." -ForegroundColor Yellow
if (Test-Path ".git") {
    Write-Host "⚠ Git уже инициализирован" -ForegroundColor Yellow
} else {
    git init
    Write-Host "✓ Git инициализирован" -ForegroundColor Green
}
Write-Host ""

# Шаг 2: Добавление файлов
Write-Host "Шаг 2: Добавление файлов..." -ForegroundColor Yellow
git add .
Write-Host "✓ Файлы добавлены" -ForegroundColor Green
Write-Host ""

# Шаг 3: Проверка безопасности
Write-Host "Шаг 3: Проверка безопасности..." -ForegroundColor Yellow
$status = git status --porcelain

if ($status -match "\.env") {
    Write-Host "❌ ВНИМАНИЕ: .env файл будет закоммичен!" -ForegroundColor Red
    Write-Host "Удалите его: git rm --cached .env" -ForegroundColor Yellow
    exit 1
}

if ($status -match "jwt-keys\.txt") {
    Write-Host "❌ ВНИМАНИЕ: jwt-keys.txt будет закоммичен!" -ForegroundColor Red
    Write-Host "Удалите его: git rm --cached jwt-keys.txt" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Конфиденциальные файлы не найдены" -ForegroundColor Green
Write-Host ""

# Шаг 4: Создание коммита
Write-Host "Шаг 4: Создание первого коммита..." -ForegroundColor Yellow
git commit -m "Initial commit: Task Tracker with Supabase backend"
Write-Host "✓ Коммит создан" -ForegroundColor Green
Write-Host ""

# Шаг 5: Инструкции
Write-Host "============================================" -ForegroundColor Blue
Write-Host "Следующие шаги:" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""
Write-Host "1. Создайте репозиторий на GitHub:" -ForegroundColor White
Write-Host "   https://github.com/new" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Выполните команды (замените YOUR_USERNAME):" -ForegroundColor White
Write-Host ""
Write-Host "   git remote add origin https://github.com/YOUR_USERNAME/task-tracker.git" -ForegroundColor Gray
Write-Host "   git branch -M main" -ForegroundColor Gray
Write-Host "   git push -u origin main" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "Готово!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Blue
