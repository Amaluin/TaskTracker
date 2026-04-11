# 🚀 Настройка Supabase для Task Tracker

Полный набор конфигурационных файлов и документации для развертывания Supabase с Nginx на вашем сервере.

---

## 📦 Что включено

### Конфигурационные файлы
- ✅ Nginx конфигурация с SSL
- ✅ Docker Compose для Supabase
- ✅ Kong API Gateway конфигурация
- ✅ Переменные окружения (.env)

### Скрипты автоматизации
- ✅ Автоматическая установка всех зависимостей
- ✅ Генератор JWT токенов
- ✅ Скрипт мониторинга состояния

### Документация
- ✅ Полное руководство по развертыванию
- ✅ Быстрый старт (русский и английский)
- ✅ Чеклист развертывания
- ✅ Инструкция по Nginx
- ✅ Описание всех файлов

---

## ⚡ Быстрый старт (3 команды)

```bash
# 1. Автоматическая установка
sudo bash setup-supabase.sh

# 2. Генерация ключей
bash generate-jwt.sh

# 3. Запуск Supabase
docker-compose -f docker-compose.supabase.yml up -d
```

**Готово!** Ваш Supabase работает на:
- API: https://api.bike53.ru
- Studio: https://studio.bike53.ru

---

## 📚 Документация

### Для начинающих
1. **[БЫСТРЫЙ_СТАРТ.md](БЫСТРЫЙ_СТАРТ.md)** - Пошаговая инструкция на русском (30 минут)
2. **[QUICK_START.md](QUICK_START.md)** - Quick start guide in English

### Для опытных
1. **[SUPABASE_README.md](SUPABASE_README.md)** - Полное руководство
2. **[SUPABASE_NGINX_SETUP.md](SUPABASE_NGINX_SETUP.md)** - Детальная настройка Nginx
3. **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Чеклист развертывания

### Справочная информация
1. **[ФАЙЛЫ_КОНФИГУРАЦИИ.md](ФАЙЛЫ_КОНФИГУРАЦИИ.md)** - Описание всех файлов
2. **[README_SUPABASE.md](README_SUPABASE.md)** - Этот файл

---

## 🎯 Архитектура

```
Internet (HTTPS)
    ↓
Nginx (SSL Termination)
    ↓
    ├─→ api.bike53.ru → Kong Gateway → Supabase Services
    │                                   ├─ PostgreSQL
    │                                   ├─ Auth (GoTrue)
    │                                   ├─ REST (PostgREST)
    │                                   ├─ Realtime
    │                                   └─ Storage
    │
    └─→ studio.bike53.ru → Supabase Studio (Admin Panel)
```

---

## 📋 Требования

### Сервер
- Ubuntu 20.04+ / Debian 11+
- 2+ CPU cores
- 4+ GB RAM
- 20+ GB свободного места
- Статический IP: **185.225.34.252**

### DNS
```
api.bike53.ru       A    185.225.34.252
studio.bike53.ru    A    185.225.34.252
```

### Программное обеспечение
Устанавливается автоматически скриптом `setup-supabase.sh`:
- Docker 20.10+
- Docker Compose 2.0+
- Nginx 1.18+
- Certbot (Let's Encrypt)

---

## 🔧 Установка

### Вариант 1: Автоматическая (рекомендуется)

```bash
# Скопируйте все файлы на сервер
scp -r * root@185.225.34.252:/opt/supabase/

# Подключитесь к серверу
ssh root@185.225.34.252

# Перейдите в директорию
cd /opt/supabase

# Запустите установку
chmod +x setup-supabase.sh generate-jwt.sh monitor-supabase.sh
sudo bash setup-supabase.sh
bash generate-jwt.sh

# Настройте переменные окружения
cp .env.example .env
nano .env  # Заполните значениями из jwt-keys.txt

# Обновите docker-compose.supabase.yml с ключами
nano docker-compose.supabase.yml

# Запустите Supabase
mkdir -p volumes/db/data volumes/storage volumes/kong
cp kong.yml volumes/kong/
docker-compose -f docker-compose.supabase.yml up -d

# Проверьте статус
docker-compose -f docker-compose.supabase.yml ps
bash monitor-supabase.sh
```

### Вариант 2: Ручная

Следуйте инструкциям в **[SUPABASE_README.md](SUPABASE_README.md)**

---

## ✅ Проверка работы

```bash
# 1. Проверьте API
curl https://api.bike53.ru/health
# Ожидается: healthy

# 2. Откройте Studio
# https://studio.bike53.ru

# 3. Проверьте все сервисы
bash monitor-supabase.sh
```

---

## 📱 Настройка Flutter приложения

1. Откройте Studio: https://studio.bike53.ru
2. Перейдите в **Settings** → **API**
3. Скопируйте **anon** ключ
4. Обновите `lib/core/constants.dart`:

```dart
class AppConstants {
  static const String supabaseUrl = 'https://api.bike53.ru';
  static const String supabaseAnonKey = 'ВАШ_ANON_KEY_ИЗ_STUDIO';
  // ...
}
```

5. Пересоберите приложение:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🔒 Безопасность

### Важно!
- ✅ Сохраните `jwt-keys.txt` в безопасном месте
- ✅ Не коммитьте `.env` в Git
- ✅ Используйте сложные пароли
- ✅ Регулярно обновляйте SSL сертификаты
- ✅ Делайте бэкапы базы данных

### Файлы, которые НЕ должны быть в Git:
```
.env
jwt-keys.txt
volumes/
backups/
*.key
*.pem
```

---

## 📊 Мониторинг

```bash
# Запустите скрипт мониторинга
bash monitor-supabase.sh

# Непрерывный мониторинг (обновление каждые 30 сек)
bash monitor-supabase.sh --watch

# Просмотр логов
docker-compose -f docker-compose.supabase.yml logs -f

# Статус контейнеров
docker-compose -f docker-compose.supabase.yml ps

# Использование ресурсов
docker stats
```

---

## 🔧 Полезные команды

### Docker
```bash
# Запуск
docker-compose -f docker-compose.supabase.yml up -d

# Остановка
docker-compose -f docker-compose.supabase.yml down

# Перезапуск
docker-compose -f docker-compose.supabase.yml restart

# Логи
docker-compose -f docker-compose.supabase.yml logs -f
```

### Nginx
```bash
# Проверка конфигурации
sudo nginx -t

# Перезапуск
sudo systemctl restart nginx

# Статус
sudo systemctl status nginx

# Логи
sudo tail -f /var/log/nginx/error.log
```

### SSL
```bash
# Обновление сертификатов
sudo certbot renew

# Проверка сертификатов
sudo certbot certificates
```

### База данных
```bash
# Бэкап
docker exec supabase-db pg_dump -U postgres postgres > backup.sql

# Восстановление
docker exec -i supabase-db psql -U postgres postgres < backup.sql

# Подключение
docker exec -it supabase-db psql -U postgres
```

---

## 🆘 Troubleshooting

### 502 Bad Gateway
```bash
docker-compose -f docker-compose.supabase.yml ps
docker-compose -f docker-compose.supabase.yml restart
```

### SSL ошибки
```bash
sudo certbot certificates
sudo certbot renew
```

### База данных не запускается
```bash
docker-compose -f docker-compose.supabase.yml logs db
```

**Подробнее:** См. раздел Troubleshooting в [SUPABASE_README.md](SUPABASE_README.md)

---

## 📁 Структура файлов

```
task_tracker/
├── nginx-supabase.conf              # Конфигурация Nginx
├── docker-compose.supabase.yml      # Docker Compose
├── kong.yml                         # Kong Gateway
├── .env.example                     # Шаблон переменных
├── setup-supabase.sh                # Автоустановка
├── generate-jwt.sh                  # Генератор JWT
├── monitor-supabase.sh              # Мониторинг
├── SUPABASE_README.md               # Полная документация
├── SUPABASE_NGINX_SETUP.md          # Инструкция Nginx
├── QUICK_START.md                   # Быстрый старт (EN)
├── БЫСТРЫЙ_СТАРТ.md                 # Быстрый старт (RU)
├── DEPLOYMENT_CHECKLIST.md          # Чеклист
├── ФАЙЛЫ_КОНФИГУРАЦИИ.md            # Описание файлов
├── README_SUPABASE.md               # Этот файл
└── .gitignore.supabase              # Git ignore
```

---

## 🎓 Обучающие материалы

### Новичок в Supabase?
1. Начните с **[БЫСТРЫЙ_СТАРТ.md](БЫСТРЫЙ_СТАРТ.md)**
2. Используйте **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)**
3. Изучите **[SUPABASE_README.md](SUPABASE_README.md)**

### Опытный пользователь?
1. **[QUICK_START.md](QUICK_START.md)** - быстрые команды
2. **[SUPABASE_NGINX_SETUP.md](SUPABASE_NGINX_SETUP.md)** - детальная настройка
3. **[ФАЙЛЫ_КОНФИГУРАЦИИ.md](ФАЙЛЫ_КОНФИГУРАЦИИ.md)** - справка по файлам

---

## 🌐 URL структура

После установки доступны:

| Сервис | URL | Описание |
|--------|-----|----------|
| API | https://api.bike53.ru | Основной API endpoint |
| Studio | https://studio.bike53.ru | Админ панель |
| REST | https://api.bike53.ru/rest/v1/ | REST API |
| Auth | https://api.bike53.ru/auth/v1/ | Аутентификация |
| Realtime | https://api.bike53.ru/realtime/v1/ | WebSocket |
| Storage | https://api.bike53.ru/storage/v1/ | Файловое хранилище |

---

## 💾 Бэкапы

```bash
# Создание бэкапа
docker exec supabase-db pg_dump -U postgres postgres > backup_$(date +%Y%m%d).sql

# Бэкап файлов
tar -czf storage_backup.tar.gz volumes/storage/

# Восстановление
docker exec -i supabase-db psql -U postgres postgres < backup_20240411.sql
```

**Рекомендация:** Настройте автоматические бэкапы через cron

---

## 📞 Поддержка

### Документация
- [Supabase Docs](https://supabase.com/docs)
- [Nginx Docs](https://nginx.org/ru/docs/)
- [Docker Docs](https://docs.docker.com/)

### Проблемы?
1. Проверьте логи: `docker-compose -f docker-compose.supabase.yml logs -f`
2. Запустите мониторинг: `bash monitor-supabase.sh`
3. Смотрите Troubleshooting в документации

---

## 📝 Лицензия

Этот проект использует открытое ПО:
- Supabase - Apache License 2.0
- Nginx - 2-clause BSD license
- PostgreSQL - PostgreSQL License

---

## ✅ Чеклист готовности

Перед началом убедитесь:

- [ ] DNS записи настроены
- [ ] Сервер доступен по SSH
- [ ] Все файлы скопированы на сервер
- [ ] Скрипты имеют права на выполнение

После установки проверьте:

- [ ] API отвечает: `curl https://api.bike53.ru/health`
- [ ] Studio открывается: https://studio.bike53.ru
- [ ] SSL сертификаты валидны
- [ ] Все контейнеры запущены
- [ ] Flutter приложение подключается

---

## 🎉 Готово!

Ваш Supabase backend готов к работе!

**Следующие шаги:**
1. Настройте Flutter приложение
2. Выполните миграцию базы данных
3. Настройте бэкапы
4. Протестируйте все функции

---

**Создано для Task Tracker Flutter App** 🚀

**Версия:** 1.0.0  
**Дата:** Апрель 2026  
**Автор:** Kiro AI Assistant
