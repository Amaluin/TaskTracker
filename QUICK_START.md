# Быстрый старт - Supabase + Nginx

## Автоматическая установка

```bash
# Сделайте скрипт исполняемым
chmod +x setup-supabase.sh

# Запустите установку
sudo bash setup-supabase.sh
```

## Ручная установка (если нужно)

### 1. Установка SSL сертификатов

```bash
sudo certbot certonly --nginx -d api.bike53.ru
sudo certbot certonly --nginx -d studio.bike53.ru
```

### 2. Установка конфигурации Nginx

```bash
sudo cp nginx-supabase.conf /etc/nginx/sites-available/supabase
sudo ln -s /etc/nginx/sites-available/supabase /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 3. Генерация секретов

```bash
# JWT Secret
openssl rand -base64 32

# Postgres Password
openssl rand -base64 32
```

### 4. Обновление docker-compose.supabase.yml

Замените следующие значения:
- `your-super-secret-and-long-postgres-password` - на сгенерированный пароль
- `your-super-secret-jwt-token-with-at-least-32-characters-long` - на сгенерированный JWT secret
- `your-email@gmail.com` и `your-app-password` - на ваши SMTP данные (опционально)

### 5. Запуск Supabase

```bash
# Создание директорий
mkdir -p volumes/db/data volumes/storage volumes/kong

# Запуск контейнеров
docker-compose -f docker-compose.supabase.yml up -d

# Проверка статуса
docker-compose -f docker-compose.supabase.yml ps
```

### 6. Получение Anon Key

1. Откройте https://studio.bike53.ru
2. Перейдите в Settings → API
3. Скопируйте `anon` ключ

### 7. Обновление Flutter приложения

Отредактируйте `lib/core/constants.dart`:

```dart
static const String supabaseUrl = 'https://api.bike53.ru';
static const String supabaseAnonKey = 'ВАШ_ANON_KEY_ИЗ_STUDIO';
```

## Проверка работы

```bash
# Проверка API
curl https://api.bike53.ru/health

# Проверка портов
sudo netstat -tulpn | grep -E '8000|54321|54323|54324|54325|54326'

# Логи Nginx
sudo tail -f /var/log/nginx/error.log

# Логи Supabase
docker-compose -f docker-compose.supabase.yml logs -f
```

## Полезные команды

```bash
# Остановка Supabase
docker-compose -f docker-compose.supabase.yml down

# Перезапуск Supabase
docker-compose -f docker-compose.supabase.yml restart

# Просмотр логов конкретного сервиса
docker-compose -f docker-compose.supabase.yml logs -f auth
docker-compose -f docker-compose.supabase.yml logs -f rest
docker-compose -f docker-compose.supabase.yml logs -f studio

# Перезапуск Nginx
sudo systemctl restart nginx

# Проверка конфигурации Nginx
sudo nginx -t

# Обновление SSL сертификатов
sudo certbot renew
```

## Структура URL

- **API**: https://api.bike53.ru
- **Studio**: https://studio.bike53.ru
- **REST API**: https://api.bike53.ru/rest/v1/
- **Auth**: https://api.bike53.ru/auth/v1/
- **Realtime**: https://api.bike53.ru/realtime/v1/
- **Storage**: https://api.bike53.ru/storage/v1/

## Troubleshooting

### 502 Bad Gateway
```bash
# Проверьте, запущен ли Supabase
docker-compose -f docker-compose.supabase.yml ps

# Проверьте порты
sudo netstat -tulpn | grep 8000
```

### SSL ошибки
```bash
# Проверьте сертификаты
sudo certbot certificates

# Обновите сертификаты
sudo certbot renew --dry-run
```

### База данных не запускается
```bash
# Проверьте логи
docker-compose -f docker-compose.supabase.yml logs db

# Очистите данные и перезапустите (ВНИМАНИЕ: удалит все данные!)
docker-compose -f docker-compose.supabase.yml down -v
docker-compose -f docker-compose.supabase.yml up -d
```

## Безопасность

### Ограничение доступа к Studio по IP

Добавьте в `/etc/nginx/sites-available/supabase` в блок `server` для studio.bike53.ru:

```nginx
# Разрешить только с вашего IP
allow ВАШ_IP;
deny all;
```

### Базовая аутентификация

```bash
# Создать пользователя
sudo htpasswd -c /etc/nginx/.htpasswd admin

# Раскомментировать в nginx-supabase.conf:
# auth_basic "Supabase Studio";
# auth_basic_user_file /etc/nginx/.htpasswd;

# Перезапустить Nginx
sudo systemctl restart nginx
```

## Мониторинг

```bash
# Использование ресурсов
docker stats

# Размер данных
du -sh volumes/

# Логи в реальном времени
docker-compose -f docker-compose.supabase.yml logs -f --tail=100
```

## Бэкап

```bash
# Бэкап базы данных
docker exec supabase-db pg_dump -U postgres postgres > backup_$(date +%Y%m%d).sql

# Восстановление
docker exec -i supabase-db psql -U postgres postgres < backup_20240411.sql
```
