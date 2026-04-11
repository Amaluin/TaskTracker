# Настройка Nginx для Supabase

## Предварительные требования

1. Установленный Nginx
2. Запущенный Supabase (локально или в Docker)
3. Настроенные DNS записи для доменов

## Шаг 1: Настройка DNS

Добавьте A-записи для ваших доменов, указывающие на IP сервера (185.225.34.252):

```
api.bike53.ru       A    185.225.34.252
studio.bike53.ru    A    185.225.34.252
```

## Шаг 2: Установка SSL сертификатов

Установите Certbot для получения бесплатных SSL сертификатов:

```bash
# Установка Certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Получение сертификатов для api.bike53.ru
sudo certbot certonly --nginx -d api.bike53.ru

# Получение сертификатов для studio.bike53.ru
sudo certbot certonly --nginx -d studio.bike53.ru
```

## Шаг 3: Установка конфигурации Nginx

```bash
# Скопируйте конфигурационный файл
sudo cp nginx-supabase.conf /etc/nginx/sites-available/supabase

# Создайте символическую ссылку
sudo ln -s /etc/nginx/sites-available/supabase /etc/nginx/sites-enabled/

# Проверьте конфигурациюw
sudo nginx -t

# Перезапустите Nginx
sudo systemctl restart nginx
```

## Шаг 4: Проверка портов Supabase

Убедитесь, что Supabase запущен и слушает на следующих портах:

```bash
# Проверка портов
sudo netstat -tulpn | grep -E '8000|54321|54323|54324|54325|54326'
```

Ожидаемые порты:
- **8000** - Kong API Gateway (основной API)
- **54321** - Studio (админ панель)
- **54323** - Auth
- **54324** - REST API
- **54325** - Realtime
- **54326** - Storage

## Шаг 5: Настройка Firewall

Откройте необходимые порты:

```bash
# Разрешить HTTP и HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Проверить статус
sudo ufw status
```

## Шаг 6: Обновление конфигурации Flutter приложения

Обновите файл `lib/core/constants.dart`:

```dart
class AppConstants {
  static const String appName = 'Планировщик задач';

  // Supabase credentials
  static const String supabaseUrl = 'https://api.bike53.ru';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'; // Получите из Supabase Studio

  // ... остальной код
}
```

## Шаг 7: Получение Supabase Anon Key

1. Откройте Supabase Studio: https://studio.bike53.ru
2. Перейдите в Settings → API
3. Скопируйте `anon` ключ
4. Вставьте его в `lib/core/constants.dart`

## Тестирование

### Проверка API endpoint

```bash
# Проверка здоровья API
curl https://api.bike53.ru/health

# Проверка REST API
curl https://api.bike53.ru/rest/v1/ \
  -H "apikey: YOUR_SUPABASE_ANON_KEY"
```

### Проверка Studio

Откройте в браузере: https://studio.bike53.ru

## Дополнительная безопасность

### 1. Ограничение доступа к Studio по IP

Добавьте в конфигурацию Studio блока:

```nginx
# Разрешить доступ только с определенных IP
allow 192.168.1.0/24;  # Ваша локальная сеть
allow YOUR_IP_ADDRESS;  # Ваш IP
deny all;
```

### 2. Базовая аутентификация для Studio

```bash
# Создать файл с паролем
sudo apt install apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd admin

# Раскомментируйте строки в nginx-supabase.conf:
# auth_basic "Supabase Studio";
# auth_basic_user_file /etc/nginx/.htpasswd;
```

### 3. Rate Limiting

Добавьте в конфигурацию Nginx:

```nginx
# В блоке http
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

# В блоке location /
limit_req zone=api_limit burst=20 nodelay;
```

## Мониторинг логов

```bash
# Логи Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Логи Supabase (если используется Docker)
docker-compose logs -f
```

## Автоматическое обновление SSL сертификатов

Certbot автоматически настраивает cron job для обновления сертификатов. Проверьте:

```bash
# Проверка таймера обновления
sudo systemctl status certbot.timer

# Тестовое обновление
sudo certbot renew --dry-run
```

## Troubleshooting

### Ошибка 502 Bad Gateway

```bash
# Проверьте, запущен ли Supabase
docker-compose ps

# Проверьте логи Nginx
sudo tail -f /var/log/nginx/error.log

# Проверьте, слушает ли Supabase на нужных портах
sudo netstat -tulpn | grep 8000
```

### Ошибка SSL

```bash
# Проверьте сертификаты
sudo certbot certificates

# Обновите сертификаты
sudo certbot renew
```

### WebSocket не работает

Убедитесь, что в конфигурации Nginx присутствуют:
```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection 'upgrade';
```

## Полезные команды

```bash
# Перезапуск Nginx
sudo systemctl restart nginx

# Проверка конфигурации
sudo nginx -t

# Просмотр статуса Nginx
sudo systemctl status nginx

# Перезагрузка конфигурации без остановки
sudo nginx -s reload
```

## Контакты и поддержка

- Документация Supabase: https://supabase.com/docs
- Документация Nginx: https://nginx.org/ru/docs/
