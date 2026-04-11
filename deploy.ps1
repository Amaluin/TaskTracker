# ============================================
# СКРИПТ ПУБЛИКАЦИИ НА app.bike53.ru
# ============================================

Write-Host ""
Write-Host "🚀 Публикация приложения на app.bike53.ru" -ForegroundColor Cyan
Write-Host ""

# Проверка наличия Flutter
Write-Host "🔍 Проверка Flutter..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1 | Select-String "Flutter"
if ($flutterVersion) {
    Write-Host "✓ Flutter найден" -ForegroundColor Green
} else {
    Write-Host "✗ Flutter не найден! Установите Flutter." -ForegroundColor Red
    exit 1
}

# Сборка приложения
Write-Host ""
Write-Host "🔨 Сборка приложения..." -ForegroundColor Yellow
flutter build web --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Сборка завершена успешно" -ForegroundColor Green
} else {
    Write-Host "✗ Ошибка сборки!" -ForegroundColor Red
    exit 1
}

# Проверка наличия build/web
if (Test-Path "build/web") {
    Write-Host "✓ Папка build/web найдена" -ForegroundColor Green
} else {
    Write-Host "✗ Папка build/web не найдена!" -ForegroundColor Red
    exit 1
}

# Загрузка на сервер
Write-Host ""
Write-Host "📤 Загрузка на сервер..." -ForegroundColor Yellow
Write-Host "Сервер: 185.225.34.252" -ForegroundColor Gray
Write-Host "Путь: /var/www/app.bike53.ru/" -ForegroundColor Gray
Write-Host ""

scp -r build/web/* root@185.225.34.252:/var/www/app.bike53.ru/

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Загрузка завершена успешно" -ForegroundColor Green
    
    # Исправление прав доступа
    Write-Host ""
    Write-Host "🔐 Исправление прав доступа..." -ForegroundColor Yellow
    ssh root@185.225.34.252 "chmod -R 755 /var/www/app.bike53.ru && chown -R www-data:www-data /var/www/app.bike53.ru"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Права доступа исправлены" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🎉 Приложение опубликовано!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🌐 Откройте в браузере:" -ForegroundColor Yellow
    Write-Host "   https://app.bike53.ru" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 Если видите старую версию:" -ForegroundColor Yellow
    Write-Host "   Нажмите Ctrl+Shift+R для очистки кэша" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "✗ Ошибка загрузки!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Возможные причины:" -ForegroundColor Yellow
    Write-Host "1. Неверный пароль" -ForegroundColor Gray
    Write-Host "2. Нет доступа к серверу" -ForegroundColor Gray
    Write-Host "3. Папка /var/www/app.bike53.ru не существует" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
