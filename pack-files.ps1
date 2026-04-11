# PowerShell скрипт для упаковки файлов конфигурации Supabase
# Использование: .\pack-files.ps1

Write-Host "===================================" -ForegroundColor Blue
Write-Host "Упаковка файлов конфигурации Supabase" -ForegroundColor Blue
Write-Host "===================================" -ForegroundColor Blue
Write-Host ""

# Имя архива
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$archiveName = "supabase-config-$timestamp.zip"

# Список файлов для упаковки
$files = @(
    "nginx-supabase.conf",
    "docker-compose.supabase.yml",
    "kong.yml",
    ".env.example",
    "setup-supabase.sh",
    "generate-jwt.sh",
    "monitor-supabase.sh",
    "SUPABASE_README.md",
    "SUPABASE_NGINX_SETUP.md",
    "QUICK_START.md",
    "БЫСТРЫЙ_СТАРТ.md",
    "DEPLOYMENT_CHECKLIST.md",
    "ФАЙЛЫ_КОНФИГУРАЦИИ.md",
    "README_SUPABASE.md",
    "ИНСТРУКЦИЯ_ЗАГРУЗКИ.md",
    ".gitignore.supabase"
)

# Проверка наличия файлов
Write-Host "Проверка файлов..." -ForegroundColor Yellow
$missingFiles = 0
$existingFiles = @()

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "✓ $file" -ForegroundColor Green
        $existingFiles += $file
    } else {
        Write-Host "⚠ Файл не найден: $file" -ForegroundColor Red
        $missingFiles++
    }
}

Write-Host ""

if ($missingFiles -gt 0) {
    Write-Host "⚠ Внимание: $missingFiles файл(ов) не найдено" -ForegroundColor Yellow
    Write-Host ""
    $response = Read-Host "Продолжить упаковку? (y/n)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Упаковка отменена" -ForegroundColor Red
        exit 1
    }
}

# Создание архива
Write-Host "Создание архива $archiveName..." -ForegroundColor Yellow

try {
    Compress-Archive -Path $existingFiles -DestinationPath $archiveName -Force
    
    Write-Host "✓ Архив создан успешно!" -ForegroundColor Green
    Write-Host ""
    
    $fileInfo = Get-Item $archiveName
    $sizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
    
    Write-Host "Файл: $archiveName" -ForegroundColor Cyan
    Write-Host "Размер: $sizeKB KB" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "===================================" -ForegroundColor Blue
    Write-Host "Следующие шаги:" -ForegroundColor Blue
    Write-Host "===================================" -ForegroundColor Blue
    Write-Host ""
    
    Write-Host "1. Загрузите архив на сервер:" -ForegroundColor White
    Write-Host "   scp $archiveName root@185.225.34.252:/opt/" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "2. Подключитесь к серверу:" -ForegroundColor White
    Write-Host "   ssh root@185.225.34.252" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "3. Распакуйте архив:" -ForegroundColor White
    Write-Host "   cd /opt" -ForegroundColor Gray
    Write-Host "   unzip $archiveName -d supabase" -ForegroundColor Gray
    Write-Host "   cd supabase" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "4. Установите права:" -ForegroundColor White
    Write-Host "   chmod +x setup-supabase.sh generate-jwt.sh monitor-supabase.sh" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "5. Запустите установку:" -ForegroundColor White
    Write-Host "   sudo bash setup-supabase.sh" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Альтернатива - загрузка отдельных файлов:" -ForegroundColor Yellow
    Write-Host ""
    
    $scpCommand = "scp nginx-supabase.conf docker-compose.supabase.yml kong.yml .env.example setup-supabase.sh generate-jwt.sh monitor-supabase.sh root@185.225.34.252:/opt/supabase/"
    Write-Host $scpCommand -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host "✗ Ошибка при создании архива: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Готово!" -ForegroundColor Green
