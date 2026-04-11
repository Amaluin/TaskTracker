# 🚀 Инициализация Git и публикация на GitHub

Пошаговая инструкция по загрузке проекта Task Tracker на GitHub.

---

## 📋 Предварительные требования

1. ✅ Установлен Git: `git --version`
2. ✅ Есть аккаунт на GitHub
3. ✅ Настроен Git:
   ```bash
   git config --global user.name "Ваше Имя"
   git config --global user.email "your.email@example.com"
   ```

---

## 🔒 Проверка безопасности (ВАЖНО!)

Перед пушем убедитесь, что конфиденциальные данные не попадут в Git:

### Проверьте .gitignore

Файл `.gitignore` уже настроен и исключает:
- ✅ `.env` файлы
- ✅ `jwt-keys.txt`
- ✅ `volumes/` (данные Docker)
- ✅ `backups/`
- ✅ SSL сертификаты (*.key, *.pem)

### Проверьте lib/core/constants.dart

**ВАЖНО:** Убедитесь, что Anon Key НЕ закоммичен!

```dart
// ✅ ПРАВИЛЬНО (для публичного репозитория)
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

// ❌ НЕПРАВИЛЬНО (не коммитьте реальный ключ!)
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

Если уже вставили реальный ключ:
```bash
# Верните к шаблону
git checkout lib/core/constants.dart
```

---

## 🚀 Инициализация и публикация

### Вариант 1: Новый репозиторий (рекомендуется)

#### Шаг 1: Инициализация Git

```bash
# Перейдите в директорию проекта
cd C:\path\to\task_tracker

# Инициализируйте Git
git init

# Проверьте статус
git status
```

#### Шаг 2: Добавьте файлы

```bash
# Добавьте все файлы
git add .

# Проверьте, что будет закоммичено
git status

# Убедитесь, что .env, jwt-keys.txt, volumes/ НЕ в списке!
```

#### Шаг 3: Создайте первый коммит

```bash
git commit -m "Initial commit: Task Tracker with Supabase"
```

#### Шаг 4: Создайте репозиторий на GitHub

1. Откройте https://github.com
2. Нажмите **New repository** (зеленая кнопка)
3. Заполните:
   - **Repository name**: `task-tracker`
   - **Description**: `Task Tracker Flutter app with Supabase backend`
   - **Visibility**: 
     - ✅ **Public** (если хотите открытый проект)
     - ✅ **Private** (если хотите приватный)
   - ❌ НЕ добавляйте README, .gitignore, license (уже есть)
4. Нажмите **Create repository**

#### Шаг 5: Подключите удаленный репозиторий

GitHub покажет команды. Используйте:

```bash
# Добавьте удаленный репозиторий
git remote add origin https://github.com/YOUR_USERNAME/task-tracker.git

# Или через SSH (если настроен)
git remote add origin git@github.com:YOUR_USERNAME/task-tracker.git

# Переименуйте ветку в main (если нужно)
git branch -M main

# Запушьте код
git push -u origin main
```

#### Шаг 6: Проверьте

Откройте https://github.com/YOUR_USERNAME/task-tracker

Вы должны увидеть все файлы проекта!

---

### Вариант 2: Существующий репозиторий

Если репозиторий уже создан на GitHub:

```bash
# Клонируйте репозиторий
git clone https://github.com/YOUR_USERNAME/task-tracker.git

# Скопируйте файлы проекта в клонированную папку
# (кроме .git директории)

# Перейдите в директорию
cd task-tracker

# Добавьте файлы
git add .

# Коммит
git commit -m "Add Task Tracker project"

# Пуш
git push origin main
```

---

## 📝 Полезные команды Git

### Проверка статуса

```bash
# Посмотреть статус
git status

# Посмотреть изменения
git diff

# Посмотреть историю
git log --oneline
```

### Работа с файлами

```bash
# Добавить конкретный файл
git add filename.dart

# Добавить все файлы
git add .

# Удалить файл из индекса (но не из файловой системы)
git rm --cached filename

# Отменить изменения в файле
git checkout -- filename
```

### Коммиты

```bash
# Создать коммит
git commit -m "Описание изменений"

# Изменить последний коммит
git commit --amend -m "Новое описание"

# Посмотреть изменения в коммите
git show
```

### Работа с удаленным репозиторием

```bash
# Посмотреть удаленные репозитории
git remote -v

# Получить изменения с GitHub
git pull origin main

# Отправить изменения на GitHub
git push origin main

# Отправить все ветки
git push --all origin
```

### Ветки

```bash
# Посмотреть ветки
git branch

# Создать новую ветку
git branch feature-name

# Переключиться на ветку
git checkout feature-name

# Создать и переключиться
git checkout -b feature-name

# Слить ветку в main
git checkout main
git merge feature-name
```

---

## 🔐 Работа с конфиденциальными данными

### Использование переменных окружения

Вместо хардкода в `constants.dart`:

#### 1. Создайте .env файл (НЕ коммитьте!)

```env
SUPABASE_URL=https://api.bike53.ru
SUPABASE_ANON_KEY=your_real_anon_key_here
```

#### 2. Добавьте в .gitignore

```
.env
.env.local
.env.production
```

#### 3. Используйте в Flutter

```dart
// pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0

// main.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(const MyApp());
}
```

#### 4. Создайте .env.example для других разработчиков

```env
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

---

## 📄 Создание README.md

Создайте хороший README для GitHub:

```bash
# Создайте файл
touch README.md
```

Пример содержимого:

```markdown
# Task Tracker

Flutter приложение для управления задачами с backend на Supabase.

## Возможности

- ✅ Создание и управление задачами
- ✅ Приоритеты и статусы
- ✅ Напоминания
- ✅ История изменений
- ✅ Синхронизация с Supabase

## Технологии

- Flutter 3.11+
- Supabase (PostgreSQL, Auth, Storage)
- Riverpod (State Management)
- Local Notifications

## Установка

1. Клонируйте репозиторий:
\`\`\`bash
git clone https://github.com/YOUR_USERNAME/task-tracker.git
cd task-tracker
\`\`\`

2. Установите зависимости:
\`\`\`bash
flutter pub get
\`\`\`

3. Настройте Supabase:
   - Следуйте инструкциям в `SUPABASE_README.md`
   - Обновите `lib/core/constants.dart` с вашими credentials

4. Запустите приложение:
\`\`\`bash
flutter run
\`\`\`

## Документация

- [Настройка Supabase](SUPABASE_README.md)
- [Настройка базы данных](DATABASE_SETUP.md)
- [Безопасность](БЕЗОПАСНОСТЬ.md)
- [Быстрый старт](БЫСТРЫЙ_СТАРТ.md)

## Лицензия

MIT License
```

---

## 🏷️ Создание релиза

После первого пуша создайте релиз:

```bash
# Создайте тег
git tag -a v1.0.0 -m "First release"

# Запушьте тег
git push origin v1.0.0
```

На GitHub:
1. Перейдите в **Releases**
2. Нажмите **Create a new release**
3. Выберите тег `v1.0.0`
4. Заполните описание
5. Нажмите **Publish release**

---

## 🔄 Регулярные обновления

После изменений:

```bash
# 1. Проверьте изменения
git status

# 2. Добавьте файлы
git add .

# 3. Коммит
git commit -m "Описание изменений"

# 4. Пуш
git push origin main
```

---

## 🆘 Troubleshooting

### Ошибка: "remote origin already exists"

```bash
# Удалите существующий remote
git remote remove origin

# Добавьте заново
git remote add origin https://github.com/YOUR_USERNAME/task-tracker.git
```

### Ошибка: "failed to push some refs"

```bash
# Получите изменения с GitHub
git pull origin main --rebase

# Попробуйте пуш снова
git push origin main
```

### Случайно закоммитили .env

```bash
# Удалите из Git (но не из файловой системы)
git rm --cached .env

# Коммит
git commit -m "Remove .env from Git"

# Пуш
git push origin main
```

### Случайно закоммитили Anon Key

```bash
# 1. Удалите ключ из файла
# 2. Коммит
git commit -am "Remove sensitive data"

# 3. Пуш
git push origin main

# 4. ВАЖНО: Сгенерируйте новый Anon Key в Supabase Studio!
# Settings → API → Regenerate anon key
```

---

## ✅ Чеклист перед пушем

- [ ] `.gitignore` настроен правильно
- [ ] `.env` файлы НЕ в Git
- [ ] `jwt-keys.txt` НЕ в Git
- [ ] `volumes/` НЕ в Git
- [ ] Реальный Anon Key НЕ в `constants.dart`
- [ ] README.md создан
- [ ] Все файлы добавлены: `git add .`
- [ ] Коммит создан: `git commit -m "..."`
- [ ] Remote добавлен: `git remote add origin ...`
- [ ] Код запушен: `git push -u origin main`

---

## 📚 Дополнительные ресурсы

- [Git документация](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com/)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)

---

**Готово! Ваш проект теперь на GitHub!** 🎉
