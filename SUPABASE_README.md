# Настройка Supabase с Nginx для Task Tracker

Полное руководство по развертыванию Supabase с Nginx для Flutter приложения Task Tracker.

## 📋 Содержание

1. [Обзор](#обзор)
2. [Требования](#требования)
3. [Быстрый старт](#быстрый-старт)
4. [Подробная установка](#подробная-установка)
5. [Конфигурация](#конфигурация)
6. [Тестирование](#тестирование)
7. [Безопасность](#безопасность)
8. [Troubleshooting](#troubleshooting)
9. [Полезные команды](#полезные-команды)

## 🎯 Обзор

Эта конфигурация настраивает:
- **Supabase** - Backend as a Service (PostgreSQL, Auth, Storage, Realtime)
- **Nginx** - Reverse proxy с SSL
- **Docker** - Контейнеризация всех сервисов
- **Let's Encrypt** - Бесплатные SSL сертификаты

### Архитектура

```
Internet
    ↓
Nginx (443) → SSL Termination
    ↓
    ├─→ api.bike53.ru → Kong (8000) → Supabase Services
    └─→ studio.bike53.ru → Studio (54321)
```

### Домены

- **api.bike53.ru** - Основной API endpoint
- **studio.bike53.ru** - Админ панель Supabase

## 📦 Требования

### Сервер
- Ubuntu 20.04+ / Debian 11+
- 2+ CPU cores
- 4+ GB RAM
- 20+ GB свободного места
- Статический IP: 185.225.34.252

### Программное обеспечение
- Docker 20.10+
- Docker Compose 2.0+
- Nginx 1.18+
- Certbot (для SSL)

### DNS
Настройте A-записи:
```
api.bike53.ru       A    185.225.34.252
studio.bike53.ru    A    185.225.34.252
```

## 🚀 Быстрый старт

### Автоматическая установка

```bash
# 1. Клонируйте проект или скопируйте файлы
cd /path/to/task_tracker

# 2. Сделайте скрипт исполняемым
chmod +x setup-supabase.sh
chmod +x generate-jwt.sh

# 3. Запустите установку
sudo bash setup-supabase.sh

# 4. Сгенерируйте JWT токены
bash generate-jwt.sh

# 5. Обновите docker-compose.supabase.yml с сгенерированными ключами

# 6. Запустите Supabase
docker-compose -f docker-compose.supabase.yml up -d

# 7. Проверьте статус
docker-compose -f docker-compose.supabase.yml ps
```

### Проверка

```bash
# Проверка API
curl https://api.bike53.ru/health

# Откройте Studio
# https://studio.bike53.ru
```

## 📖 Подробная установка

### Шаг 1: Подготовка сервера

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y curl git openssl
```

### Шаг 2: Установка Docker

```bash
# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER

# Установка Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Проверка
docker --version
docker-compose --version
```

### Шаг 3: Установка Nginx

```bash
# Установка Nginx
sudo apt install -y nginx

# Запуск и автозагрузка
sudo systemctl start nginx
sudo systemctl enable nginx

# Проверка
sudo systemctl status nginx
```

### Шаг 4: Настройка DNS

Убедитесь, что DNS записи настроены и распространились:

```bash
# Проверка DNS
nslookup api.bike53.ru
nslookup studio.bike53.ru

# Или с помощью dig
dig api.bike53.ru +short
dig studio.bike53.ru +short
```

### Шаг 5: Получение SSL сертификатов

```bash
# Установка Certbot
sudo apt install -y certbot python3-certbot-nginx

# Получение сертификатов
sudo certbot certonly --nginx -d api.bike53.ru --email admin@bike53.ru --agree-tos --non-interactive
sudo certbot certonly --nginx -d studio.bike53.ru --email admin@bike53.ru --agree-tos --non-interactive

# Проверка сертификатов
sudo certbot certificates
```

### Шаг 6: Конфигурация Nginx

```bash
# Копирование конфигурации
sudo cp nginx-supabase.conf /etc/nginx/sites-available/supabase

# Создание символической ссылки
sudo ln -s /etc/nginx/sites-available/supabase /etc/nginx/sites-enabled/

# Удаление дефолтной конфигурации (опционально)
sudo rm /etc/nginx/sites-enabled/default

# Проверка конфигурации
sudo nginx -t

# Перезапуск Nginx
sudo systemctl restart nginx
```

### Шаг 7: Генерация секретов

```bash
# Генерация JWT токенов
bash generate-jwt.sh

# Или вручную
openssl rand -base64 32  # JWT Secret
openssl rand -base64 32  # Postgres Password
```

### Шаг 8: Конфигурация Supabase

```bash
# Создание .env файла
cp .env.example .env

# Редактирование .env
nano .env

# Обновите следующие значения:
# - POSTGRES_PASSWORD
# - JWT_SECRET
# - SUPABASE_ANON_KEY
# - SUPABASE_SERVICE_KEY
# - SMTP настройки (если нужна отправка email)
```

### Шаг 9: Подготовка директорий

```bash
# Создание директорий для данных
mkdir -p volumes/db/data
mkdir -p volumes/storage
mkdir -p volumes/kong

# Копирование Kong конфигурации
cp kong.yml volumes/kong/

# Установка прав
chmod -R 755 volumes/
```

### Шаг 10: Запуск Supabase

```bash
# Запуск всех сервисов
docker-compose -f docker-compose.supabase.yml up -d

# Проверка статуса
docker-compose -f docker-compose.supabase.yml ps

# Просмотр логов
docker-compose -f docker-compose.supabase.yml logs -f
```

### Шаг 11: Настройка Flutter приложения

```bash
# Откройте Studio
# https://studio.bike53.ru

# Получите Anon Key:
# Settings → API → anon key

# Обновите lib/core/constants.dart
nano lib/core/constants.dart
```

```dart
class AppConstants {
  static const String appName = 'Планировщик задач';

  // Supabase credentials
  static const String supabaseUrl = 'https://api.bike53.ru';
  static const String supabaseAnonKey = 'ВАШ_ANON_KEY_ИЗ_STUDIO';

  // ... остальной код
}
```

## ⚙️ Конфигурация

### Структура файлов

```
task_tracker/
├── nginx-supabase.conf          # Конфигурация Nginx
├── docker-compose.supabase.yml  # Docker Compose для Supabase
├── kong.yml                     # Конфигурация Kong Gateway
├── .env.example                 # Пример переменных окружения
├── setup-supabase.sh            # Скрипт автоматической установки
├── generate-jwt.sh              # Генератор JWT токенов
├── SUPABASE_NGINX_SETUP.md      # Подробная документация
├── QUICK_START.md               # Быстрый старт
└── volumes/                     # Данные Docker
    ├── db/data/                 # База данных PostgreSQL
    ├── storage/                 # Файловое хранилище
    └── kong/                    # Конфигурация Kong
```

### Порты

| Сервис | Внутренний порт | Внешний порт | Описание |
|--------|----------------|--------------|----------|
| Kong | 8000 | 8000 | API Gateway |
| Studio | 3000 | 54321 | Админ панель |
| Auth | 9999 | 54323 | Аутентификация |
| REST | 3000 | 54324 | REST API |
| Realtime | 4000 | 54325 | WebSocket |
| Storage | 5000 | 54326 | Файловое хранилище |
| PostgreSQL | 5432 | 5432 | База данных |

### Переменные окружения

Основные переменные в `.env`:

```bash
# Безопасность
POSTGRES_PASSWORD=your-password
JWT_SECRET=your-jwt-secret
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key

# Домены
API_DOMAIN=api.bike53.ru
STUDIO_DOMAIN=studio.bike53.ru

# Email (опционально)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

## 🧪 Тестирование

### Проверка API endpoints

```bash
# Health check
curl https://api.bike53.ru/health

# REST API
curl https://api.bike53.ru/rest/v1/ \
  -H "apikey: YOUR_ANON_KEY"

# Auth endpoint
curl https://api.bike53.ru/auth/v1/health

# Storage endpoint
curl https://api.bike53.ru/storage/v1/
```

### Проверка портов

```bash
# Проверка, что все сервисы слушают на нужных портах
sudo netstat -tulpn | grep -E '8000|54321|54323|54324|54325|54326|5432'
```

### Проверка SSL

```bash
# Проверка SSL сертификата
openssl s_client -connect api.bike53.ru:443 -servername api.bike53.ru

# Проверка срока действия
echo | openssl s_client -servername api.bike53.ru -connect api.bike53.ru:443 2>/dev/null | openssl x509 -noout -dates
```

### Проверка Docker контейнеров

```bash
# Статус всех контейнеров
docker-compose -f docker-compose.supabase.yml ps

# Использование ресурсов
docker stats

# Логи конкретного сервиса
docker-compose -f docker-compose.supabase.yml logs -f db
docker-compose -f docker-compose.supabase.yml logs -f auth
docker-compose -f docker-compose.supabase.yml logs -f rest
```

## 🔒 Безопасность

### 1. Firewall

```bash
# Установка UFW
sudo apt install -y ufw

# Базовые правила
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Разрешить SSH
sudo ufw allow 22/tcp

# Разрешить HTTP и HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Включить firewall
sudo ufw enable

# Проверка статуса
sudo ufw status
```

### 2. Ограничение доступа к Studio

Добавьте в `/etc/nginx/sites-available/supabase` в блок server для studio.bike53.ru:

```nginx
# Разрешить только с определенных IP
allow 192.168.1.0/24;  # Ваша локальная сеть
allow YOUR_PUBLIC_IP;   # Ваш публичный IP
deny all;
```

### 3. Базовая аутентификация

```bash
# Установка утилиты
sudo apt install -y apache2-utils

# Создание пользователя
sudo htpasswd -c /etc/nginx/.htpasswd admin

# Добавьте в конфигурацию Nginx для Studio:
auth_basic "Supabase Studio";
auth_basic_user_file /etc/nginx/.htpasswd;

# Перезапуск Nginx
sudo systemctl restart nginx
```

### 4. Rate Limiting

Добавьте в `/etc/nginx/nginx.conf` в блок `http`:

```nginx
# Rate limiting
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=auth_limit:10m rate=5r/s;

# В блоке server для API:
location /rest/v1/ {
    limit_req zone=api_limit burst=20 nodelay;
    # ... остальная конфигурация
}

location /auth/v1/ {
    limit_req zone=auth_limit burst=10 nodelay;
    # ... остальная конфигурация
}
```

### 5. Регулярные обновления

```bash
# Автоматическое обновление системы
sudo apt install -y unattended-upgrades

# Настройка
sudo dpkg-reconfigure -plow unattended-upgrades
```

### 6. Бэкапы

```bash
# Создание скрипта бэкапа
cat > backup-supabase.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Бэкап базы данных
docker exec supabase-db pg_dump -U postgres postgres > "$BACKUP_DIR/db_$DATE.sql"

# Бэкап файлов storage
tar -czf "$BACKUP_DIR/storage_$DATE.tar.gz" volumes/storage/

# Удаление старых бэкапов (старше 30 дней)
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
EOF

chmod +x backup-supabase.sh

# Добавление в cron (каждый день в 2:00)
(crontab -l 2>/dev/null; echo "0 2 * * * /path/to/backup-supabase.sh") | crontab -
```

## 🔧 Troubleshooting

### Проблема: 502 Bad Gateway

```bash
# Проверьте, запущены ли контейнеры
docker-compose -f docker-compose.supabase.yml ps

# Проверьте логи Nginx
sudo tail -f /var/log/nginx/error.log

# Проверьте логи Kong
docker-compose -f docker-compose.supabase.yml logs kong

# Перезапустите сервисы
docker-compose -f docker-compose.supabase.yml restart
```

### Проблема: SSL ошибки

```bash
# Проверьте сертификаты
sudo certbot certificates

# Обновите сертификаты
sudo certbot renew

# Проверьте права на файлы
sudo ls -la /etc/letsencrypt/live/api.bike53.ru/
```

### Проблема: База данных не запускается

```bash
# Проверьте логи
docker-compose -f docker-compose.supabase.yml logs db

# Проверьте права на директорию
ls -la volumes/db/

# Очистите данные и перезапустите (ВНИМАНИЕ: удалит все данные!)
docker-compose -f docker-compose.supabase.yml down -v
rm -rf volumes/db/data/*
docker-compose -f docker-compose.supabase.yml up -d
```

### Проблема: WebSocket не работает

```bash
# Проверьте конфигурацию Nginx
sudo nginx -t

# Убедитесь, что присутствуют заголовки для WebSocket:
# proxy_http_version 1.1;
# proxy_set_header Upgrade $http_upgrade;
# proxy_set_header Connection 'upgrade';

# Проверьте логи Realtime
docker-compose -f docker-compose.supabase.yml logs realtime
```

### Проблема: Не могу подключиться к Studio

```bash
# Проверьте, запущен ли Studio
docker-compose -f docker-compose.supabase.yml ps studio

# Проверьте логи
docker-compose -f docker-compose.supabase.yml logs studio

# Проверьте, открыт ли порт
sudo netstat -tulpn | grep 54321

# Проверьте Nginx
sudo nginx -t
sudo systemctl status nginx
```

## 📝 Полезные команды

### Docker

```bash
# Запуск всех сервисов
docker-compose -f docker-compose.supabase.yml up -d

# Остановка всех сервисов
docker-compose -f docker-compose.supabase.yml down

# Перезапуск всех сервисов
docker-compose -f docker-compose.supabase.yml restart

# Перезапуск конкретного сервиса
docker-compose -f docker-compose.supabase.yml restart auth

# Просмотр логов
docker-compose -f docker-compose.supabase.yml logs -f

# Просмотр логов конкретного сервиса
docker-compose -f docker-compose.supabase.yml logs -f db

# Статус контейнеров
docker-compose -f docker-compose.supabase.yml ps

# Использование ресурсов
docker stats

# Очистка неиспользуемых ресурсов
docker system prune -a
```

### Nginx

```bash
# Проверка конфигурации
sudo nginx -t

# Перезапуск
sudo systemctl restart nginx

# Перезагрузка конфигурации без остановки
sudo nginx -s reload

# Статус
sudo systemctl status nginx

# Просмотр логов
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### PostgreSQL

```bash
# Подключение к базе данных
docker exec -it supabase-db psql -U postgres

# Бэкап базы данных
docker exec supabase-db pg_dump -U postgres postgres > backup.sql

# Восстановление из бэкапа
docker exec -i supabase-db psql -U postgres postgres < backup.sql

# Просмотр таблиц
docker exec -it supabase-db psql -U postgres -c "\dt"
```

### SSL

```bash
# Обновление сертификатов
sudo certbot renew

# Тестовое обновление
sudo certbot renew --dry-run

# Просмотр сертификатов
sudo certbot certificates

# Удаление сертификата
sudo certbot delete --cert-name api.bike53.ru
```

## 📚 Дополнительные ресурсы

- [Документация Supabase](https://supabase.com/docs)
- [Документация Nginx](https://nginx.org/ru/docs/)
- [Документация Docker](https://docs.docker.com/)
- [Документация Kong](https://docs.konghq.com/)
- [Let's Encrypt](https://letsencrypt.org/)

## 🆘 Поддержка

Если у вас возникли проблемы:

1. Проверьте логи: `docker-compose -f docker-compose.supabase.yml logs -f`
2. Проверьте статус: `docker-compose -f docker-compose.supabase.yml ps`
3. Проверьте конфигурацию Nginx: `sudo nginx -t`
4. Проверьте SSL сертификаты: `sudo certbot certificates`

## 📄 Лицензия

Этот проект использует открытое ПО:
- Supabase - Apache License 2.0
- Nginx - 2-clause BSD license
- PostgreSQL - PostgreSQL License

---

**Создано для Task Tracker Flutter App**
