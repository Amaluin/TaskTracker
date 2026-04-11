# Чеклист развертывания Supabase

Используйте этот чеклист для пошагового развертывания Supabase с Nginx.

## 📋 Предварительная подготовка

- [ ] Сервер с Ubuntu 20.04+ или Debian 11+
- [ ] Минимум 4GB RAM и 20GB свободного места
- [ ] Статический IP адрес: 185.225.34.252
- [ ] Root или sudo доступ к серверу
- [ ] Доступ к панели управления DNS

## 🌐 Настройка DNS

- [ ] Создана A-запись: `api.bike53.ru` → `185.225.34.252`
- [ ] Создана A-запись: `studio.bike53.ru` → `185.225.34.252`
- [ ] DNS записи распространились (проверить: `nslookup api.bike53.ru`)
- [ ] DNS записи распространились (проверить: `nslookup studio.bike53.ru`)

## 🔧 Установка зависимостей

- [ ] Обновлена система: `sudo apt update && sudo apt upgrade -y`
- [ ] Установлен Docker: `docker --version`
- [ ] Установлен Docker Compose: `docker-compose --version`
- [ ] Установлен Nginx: `nginx -v`
- [ ] Установлен Certbot: `certbot --version`
- [ ] Установлен Git: `git --version`
- [ ] Установлен OpenSSL: `openssl version`

## 📁 Подготовка проекта

- [ ] Скопированы все конфигурационные файлы на сервер
- [ ] Файлы находятся в директории проекта
- [ ] Установлены права на выполнение скриптов:
  - [ ] `chmod +x setup-supabase.sh`
  - [ ] `chmod +x generate-jwt.sh`
  - [ ] `chmod +x monitor-supabase.sh`

## 🔐 Генерация секретов

- [ ] Запущен скрипт: `bash generate-jwt.sh`
- [ ] Сохранен JWT Secret
- [ ] Сохранен Postgres Password
- [ ] Сохранен Anon Key
- [ ] Сохранен Service Role Key
- [ ] Файл `jwt-keys.txt` создан и сохранен в безопасном месте

## 🔒 SSL Сертификаты

- [ ] Получен сертификат для api.bike53.ru:
  ```bash
  sudo certbot certonly --nginx -d api.bike53.ru
  ```
- [ ] Получен сертификат для studio.bike53.ru:
  ```bash
  sudo certbot certonly --nginx -d studio.bike53.ru
  ```
- [ ] Проверены сертификаты: `sudo certbot certificates`
- [ ] Настроено автоматическое обновление: `sudo certbot renew --dry-run`

## 🌐 Настройка Nginx

- [ ] Скопирована конфигурация:
  ```bash
  sudo cp nginx-supabase.conf /etc/nginx/sites-available/supabase
  ```
- [ ] Создана символическая ссылка:
  ```bash
  sudo ln -s /etc/nginx/sites-available/supabase /etc/nginx/sites-enabled/
  ```
- [ ] Удалена дефолтная конфигурация (опционально):
  ```bash
  sudo rm /etc/nginx/sites-enabled/default
  ```
- [ ] Проверена конфигурация: `sudo nginx -t`
- [ ] Перезапущен Nginx: `sudo systemctl restart nginx`
- [ ] Nginx работает: `sudo systemctl status nginx`

## 🐳 Настройка Docker

- [ ] Создан файл `.env` из `.env.example`
- [ ] Обновлены значения в `.env`:
  - [ ] `POSTGRES_PASSWORD`
  - [ ] `JWT_SECRET`
  - [ ] `SUPABASE_ANON_KEY`
  - [ ] `SUPABASE_SERVICE_KEY`
  - [ ] `SMTP_*` (если нужна отправка email)
- [ ] Созданы директории:
  ```bash
  mkdir -p volumes/db/data volumes/storage volumes/kong
  ```
- [ ] Скопирована конфигурация Kong:
  ```bash
  cp kong.yml volumes/kong/
  ```
- [ ] Обновлен `docker-compose.supabase.yml` с секретами

## 🚀 Запуск Supabase

- [ ] Запущены контейнеры:
  ```bash
  docker-compose -f docker-compose.supabase.yml up -d
  ```
- [ ] Проверен статус:
  ```bash
  docker-compose -f docker-compose.supabase.yml ps
  ```
- [ ] Все контейнеры в статусе "Up"
- [ ] Просмотрены логи на наличие ошибок:
  ```bash
  docker-compose -f docker-compose.supabase.yml logs
  ```

## 🔥 Настройка Firewall

- [ ] Установлен UFW: `sudo apt install -y ufw`
- [ ] Настроены правила:
  ```bash
  sudo ufw allow 22/tcp
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  ```
- [ ] Включен firewall: `sudo ufw enable`
- [ ] Проверен статус: `sudo ufw status`

## ✅ Тестирование

### API Endpoints

- [ ] Health check работает:
  ```bash
  curl https://api.bike53.ru/health
  ```
- [ ] REST API отвечает:
  ```bash
  curl https://api.bike53.ru/rest/v1/
  ```
- [ ] Auth endpoint работает:
  ```bash
  curl https://api.bike53.ru/auth/v1/health
  ```

### Studio

- [ ] Studio открывается: https://studio.bike53.ru
- [ ] Можно войти в Studio
- [ ] Видна база данных
- [ ] Можно создать таблицу (тест)

### SSL

- [ ] HTTPS работает для api.bike53.ru
- [ ] HTTPS работает для studio.bike53.ru
- [ ] Нет предупреждений о сертификате
- [ ] Сертификат валиден (проверить в браузере)

### Порты

- [ ] Все порты слушают:
  ```bash
  sudo netstat -tulpn | grep -E '8000|54321|54323|54324|54325|54326'
  ```

## 📱 Настройка Flutter приложения

- [ ] Открыт Studio: https://studio.bike53.ru
- [ ] Получен Anon Key из Settings → API
- [ ] Обновлен файл `lib/core/constants.dart`:
  ```dart
  static const String supabaseUrl = 'https://api.bike53.ru';
  static const String supabaseAnonKey = 'ВАШ_ANON_KEY';
  ```
- [ ] Приложение пересобрано
- [ ] Приложение подключается к Supabase

## 🗄️ Настройка базы данных

- [ ] Выполнена миграция схемы:
  ```bash
  docker exec -i supabase-db psql -U postgres postgres < database_schema.sql
  ```
- [ ] Выполнена миграция данных (если есть):
  ```bash
  docker exec -i supabase-db psql -U postgres postgres < database_migration.sql
  ```
- [ ] Проверены таблицы в Studio
- [ ] Настроены Row Level Security (RLS) политики
- [ ] Созданы необходимые индексы

## 🔒 Безопасность

- [ ] Изменены все дефолтные пароли
- [ ] JWT Secret уникален и сложен
- [ ] Postgres Password уникален и сложен
- [ ] Настроено ограничение доступа к Studio по IP (опционально)
- [ ] Настроена базовая аутентификация для Studio (опционально)
- [ ] Настроен Rate Limiting в Nginx (опционально)
- [ ] Файл `.env` добавлен в `.gitignore`
- [ ] Файл `jwt-keys.txt` добавлен в `.gitignore`

## 💾 Настройка бэкапов

- [ ] Создан скрипт бэкапа
- [ ] Протестирован бэкап базы данных
- [ ] Протестировано восстановление из бэкапа
- [ ] Настроен cron для автоматических бэкапов
- [ ] Определено место хранения бэкапов
- [ ] Настроена ротация старых бэкапов

## 📊 Мониторинг

- [ ] Запущен скрипт мониторинга:
  ```bash
  bash monitor-supabase.sh
  ```
- [ ] Все сервисы работают
- [ ] Нет критических ошибок в логах
- [ ] Использование ресурсов в норме
- [ ] SSL сертификаты валидны

## 📝 Документация

- [ ] Сохранены все пароли и ключи в безопасном месте
- [ ] Задокументированы изменения в конфигурации
- [ ] Созданы инструкции для команды
- [ ] Записаны контакты для поддержки

## 🎉 Финальная проверка

- [ ] Приложение работает с production Supabase
- [ ] Пользователи могут регистрироваться
- [ ] Пользователи могут входить
- [ ] Данные сохраняются корректно
- [ ] Realtime обновления работают (если используются)
- [ ] Storage работает (если используется)
- [ ] Email уведомления работают (если настроены)

## 📞 Контакты и поддержка

- [ ] Записаны контакты администратора сервера
- [ ] Записаны контакты DNS провайдера
- [ ] Записаны контакты хостинг провайдера
- [ ] Создан план действий при сбоях

## 🔄 Регулярное обслуживание

Настройте регулярные задачи:

- [ ] Еженедельная проверка логов
- [ ] Ежемесячная проверка обновлений
- [ ] Ежемесячная проверка бэкапов
- [ ] Ежеквартальная проверка безопасности
- [ ] Мониторинг использования ресурсов

---

## ✅ Развертывание завершено!

Дата завершения: _______________

Ответственный: _______________

Подпись: _______________

---

## 📚 Полезные команды для справки

```bash
# Перезапуск всех сервисов
docker-compose -f docker-compose.supabase.yml restart

# Просмотр логов
docker-compose -f docker-compose.supabase.yml logs -f

# Мониторинг
bash monitor-supabase.sh

# Бэкап
docker exec supabase-db pg_dump -U postgres postgres > backup.sql

# Обновление SSL
sudo certbot renew

# Перезапуск Nginx
sudo systemctl restart nginx
```
