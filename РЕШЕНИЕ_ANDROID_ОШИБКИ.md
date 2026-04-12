# 🔧 Решение ошибки подключения на Android

## Проблема
```
ClientException with SocketException: Failed host lookup: 'api.bike53.ru' 
(OS Error: No address associated with hostname, errno = 7)
```

Это означает, что Android устройство не может подключиться к серверу `api.bike53.ru`.

---

## ✅ Решение 1: Проверьте интернет на устройстве

1. Убедитесь, что на Android устройстве включен Wi-Fi или мобильный интернет
2. Откройте браузер на устройстве и попробуйте открыть любой сайт
3. Попробуйте открыть `https://api.bike53.ru` в браузере на устройстве

---

## ✅ Решение 2: Используйте локальный Supabase для тестирования

Если сервер `api.bike53.ru` недоступен с вашего устройства, используйте локальный Supabase:

### Шаг 1: Узнайте IP адрес вашего компьютера

**Windows:**
```bash
ipconfig
```
Найдите строку "IPv4 Address" - это ваш локальный IP (например, `192.168.1.100`)

**Mac/Linux:**
```bash
ifconfig
```

### Шаг 2: Запустите локальный Supabase

```bash
docker-compose -f docker-compose.supabase.yml up -d
```

### Шаг 3: Измените константы в приложении

Откройте `lib/core/constants.dart` и замените:

```dart
// БЫЛО:
static const String supabaseUrl = 'https://api.bike53.ru';

// СТАЛО (замените 192.168.1.100 на ваш IP):
static const String supabaseUrl = 'http://192.168.1.100:54321';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
```

### Шаг 4: Разрешите HTTP трафик на Android

Откройте `android/app/src/main/AndroidManifest.xml` и добавьте:

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

### Шаг 5: Пересоберите приложение

```bash
flutter clean
flutter pub get
flutter build apk
```

---

## ✅ Решение 3: Проверьте доступность сервера

Если вы хотите использовать удаленный сервер `api.bike53.ru`:

### 1. Проверьте с компьютера:
```bash
curl https://api.bike53.ru/rest/v1/
```

### 2. Проверьте с Android устройства:
- Откройте браузер на устройстве
- Перейдите на `https://api.bike53.ru`
- Если сайт не открывается, проблема в сети или DNS

### 3. Возможные проблемы:
- ❌ Сервер выключен
- ❌ Firewall блокирует подключение
- ❌ DNS не настроен правильно
- ❌ SSL сертификат недействителен

---

## ✅ Решение 4: Используйте VPN или другую сеть

Если сервер доступен с компьютера, но не с Android:
1. Попробуйте подключить Android к той же Wi-Fi сети, что и компьютер
2. Попробуйте использовать мобильный интернет вместо Wi-Fi
3. Попробуйте VPN

---

## 🎯 Быстрое решение для тестирования

Самый простой способ - использовать локальный Supabase:

```bash
# 1. Узнайте свой IP
ipconfig

# 2. Запустите Supabase
docker-compose -f docker-compose.supabase.yml up -d

# 3. Измените lib/core/constants.dart:
# supabaseUrl = 'http://ВАШ_IP:54321'

# 4. Добавьте в AndroidManifest.xml:
# android:usesCleartextTraffic="true"

# 5. Пересоберите
flutter clean && flutter build apk
```

---

## 📱 Проверка после исправления

1. Установите новый APK на устройство
2. Откройте приложение
3. Попробуйте зарегистрироваться
4. Если ошибка исчезла - всё работает! ✅

---

## 💡 Совет

Для production используйте `https://api.bike53.ru`, а для разработки - локальный Supabase с IP вашего компьютера.
