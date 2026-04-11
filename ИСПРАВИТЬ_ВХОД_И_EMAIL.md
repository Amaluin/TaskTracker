# 🔧 ИСПРАВЛЕНИЕ ВХОДА И ПОДТВЕРЖДЕНИЯ EMAIL

## ✅ ЧТО СДЕЛАНО

1. **Маска телефона добавлена в регистрацию** - теперь оба экрана используют формат `+7 (XXX) XXX-XX-XX`
2. **Регистрация работает** - пользователи создаются и автоматически переходят на главный экран

## ❌ ЧТО НЕ РАБОТАЕТ

1. **Вход выдает ошибку 400** - проблема с форматом запроса
2. **Email подтверждение** - может блокировать вход

---

## 🚀 РЕШЕНИЕ 1: УБРАТЬ ПОДТВЕРЖДЕНИЕ EMAIL (ОБЯЗАТЕЛЬНО!)

### Вариант A: Автоматический скрипт (РЕКОМЕНДУЕТСЯ)

```bash
# На вашем компьютере
scp ПРОВЕРИТЬ_И_ИСПРАВИТЬ_AUTH.sh root@185.225.34.252:/tmp/

# На сервере
ssh root@185.225.34.252
chmod +x /tmp/ПРОВЕРИТЬ_И_ИСПРАВИТЬ_AUTH.sh
/tmp/ПРОВЕРИТЬ_И_ИСПРАВИТЬ_AUTH.sh
```

### Вариант B: Ручная проверка

```bash
ssh root@185.225.34.252

# Проверить настройки
docker exec supabase-auth env | grep GOTRUE_MAILER_AUTOCONFIRM

# Если НЕ выводит "GOTRUE_MAILER_AUTOCONFIRM=true", исправить:
echo "GOTRUE_MAILER_AUTOCONFIRM=true" >> /home/supabase/supabase/docker/.env

# Перезапустить Auth
cd /home/supabase/supabase/docker
docker-compose restart auth

# Проверить снова
docker exec supabase-auth env | grep GOTRUE_MAILER_AUTOCONFIRM
```

### Вариант C: Подтвердить существующих пользователей

1. Откройте: https://studio.bike53.ru
2. SQL Editor → New query
3. Скопируйте содержимое файла `ПОДТВЕРДИТЬ_ВСЕХ_ПОЛЬЗОВАТЕЛЕЙ.sql`
4. Выполните (Run)

---

## 🚀 РЕШЕНИЕ 2: ИСПРАВИТЬ ОШИБКУ ВХОДА 400

Проблема может быть в том, что Supabase Auth ожидает другой формат запроса или пользователь не подтвержден.

### Шаг 1: Проверить логи Auth

```bash
ssh root@185.225.34.252
docker logs --tail 50 supabase-auth
```

Ищите строки с ошибками при попытке входа.

### Шаг 2: Проверить пользователя в БД

1. Откройте: https://studio.bike53.ru
2. SQL Editor → New query
3. Выполните:

```sql
-- Проверить пользователей
SELECT 
    id,
    email,
    phone,
    email_confirmed_at,
    phone_confirmed_at,
    created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;
```

Если `email_confirmed_at` = NULL, значит пользователь не подтвержден!

### Шаг 3: Подтвердить пользователя

```sql
-- Подтвердить всех пользователей
UPDATE auth.users 
SET 
    email_confirmed_at = NOW(),
    phone_confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;
```

---

## 🚀 РЕШЕНИЕ 3: АЛЬТЕРНАТИВНЫЙ МЕТОД ВХОДА

Если проблема сохраняется, можно попробовать использовать `signInWithOtp` вместо `signInWithPassword`:

### Вариант A: Вход по коду (требует настройки SMS)

```dart
// В login_screen.dart
final response = await Supabase.instance.client.auth.signInWithOtp(
  phone: phone,
);
```

### Вариант B: Вход через API напрямую (временное решение)

```dart
// В login_screen.dart, заменить метод _login:
Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final phone = _formatPhoneNumber(_phoneController.text.trim());
    final password = _passwordController.text;
    final email = '${phone.replaceAll('+', '')}@tasktracker.local';

    print('🔐 Попытка входа: $email');

    // Попробовать вход с grant_type=password
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null && mounted) {
      print('✅ Вход успешен: ${response.user!.id}');
      Navigator.of(context).pop();
    }
  } on AuthException catch (e) {
    print('❌ AuthException: ${e.message}');
    print('❌ Status: ${e.statusCode}');
    
    if (mounted) {
      String message = 'Ошибка входа';
      
      if (e.statusCode == '400') {
        message = 'Неверный формат запроса. Проверьте, что пользователь подтвержден.';
      } else if (e.message.contains('Invalid login credentials')) {
        message = 'Неверный номер телефона или пароль';
      } else if (e.message.contains('Email not confirmed')) {
        message = 'Email не подтвержден. Выполните SQL скрипт подтверждения.';
      } else {
        message = 'Ошибка: ${e.message} (${e.statusCode})';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } catch (e) {
    print('❌ Ошибка: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

---

## 📋 ПОРЯДОК ДЕЙСТВИЙ

### 1. Убрать подтверждение email (ОБЯЗАТЕЛЬНО!)

```bash
# Вариант A: Автоматический скрипт
scp ПРОВЕРИТЬ_И_ИСПРАВИТЬ_AUTH.sh root@185.225.34.252:/tmp/
ssh root@185.225.34.252
chmod +x /tmp/ПРОВЕРИТЬ_И_ИСПРАВИТЬ_AUTH.sh
/tmp/ПРОВЕРИТЬ_И_ИСПРАВИТЬ_AUTH.sh
```

### 2. Подтвердить существующих пользователей

1. Откройте: https://studio.bike53.ru
2. SQL Editor → New query
3. Выполните содержимое `ПОДТВЕРДИТЬ_ВСЕХ_ПОЛЬЗОВАТЕЛЕЙ.sql`

### 3. Проверить логи

```bash
ssh root@185.225.34.252
docker logs --tail 50 supabase-auth
```

### 4. Попробовать войти

- Откройте приложение
- Попробуйте войти с данными зарегистрированного пользователя
- Если ошибка 400 сохраняется, пришлите логи Auth

---

## 🔍 ДИАГНОСТИКА

Если проблема сохраняется, выполните эти команды и пришлите результаты:

```bash
ssh root@185.225.34.252

# 1. Проверить настройки Auth
docker exec supabase-auth env | grep GOTRUE

# 2. Проверить логи Auth
docker logs --tail 100 supabase-auth

# 3. Проверить .env
cat /home/supabase/supabase/docker/.env | grep GOTRUE

# 4. Проверить пользователей в БД (через Studio)
SELECT * FROM auth.users ORDER BY created_at DESC LIMIT 5;
```

---

## ✅ ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

После выполнения всех шагов:

1. ✅ Регистрация работает - пользователь создается и сразу переходит на главный экран
2. ✅ Вход работает - пользователь может войти с номером телефона и паролем
3. ✅ Email подтверждение отключено - не требуется подтверждение
4. ✅ Маска телефона работает - формат `+7 (XXX) XXX-XX-XX`

---

## 📞 ЕСЛИ НЕ РАБОТАЕТ

Пришлите результаты команд из раздела "ДИАГНОСТИКА" и скриншот ошибки из приложения.
