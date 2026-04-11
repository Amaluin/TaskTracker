# ✅ Проект готов к публикации на GitHub!

## 🔒 Безопасность проверена

- ✅ `.gitignore` настроен правильно
- ✅ Anon Key заменен на шаблон в `constants.dart`
- ✅ `.env` файлы исключены
- ✅ `jwt-keys.txt` исключен
- ✅ `volumes/` исключены
- ✅ `backups/` исключены

---

## 🚀 Команды для публикации

### Скопируйте и выполните по порядку:

```bash
# 1. Перейдите в директорию проекта
cd C:\path\to\task_tracker

# 2. Инициализируйте Git
git init

# 3. Добавьте все файлы
git add .

# 4. Создайте первый коммит
git commit -m "Initial commit: Task Tracker with Supabase backend"

# 5. Создайте репозиторий на GitHub
# Откройте: https://github.com/new
# Name: task-tracker
# Description: Task Tracker Flutter app with Supabase backend
# Visibility: Public или Private
# НЕ добавляйте README, .gitignore, license
# Нажмите: Create repository

# 6. Добавьте remote (замените YOUR_USERNAME на ваш GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/task-tracker.git

# 7. Переименуйте ветку в main
git branch -M main

# 8. Запушьте код
git push -u origin main
```

---

## ✅ Готово!

Ваш проект теперь на GitHub: `https://github.com/YOUR_USERNAME/task-tracker`

---

## 📝 После публикации

### 1. Сохраните реальный Anon Key локально

Создайте файл `.env` (он НЕ попадет в Git):

```env
SUPABASE_URL=https://api.bike53.ru
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc1NDIyODAwLCJleHAiOjE5MzMxODkyMDB9.9Hsb4zE3uIMR3sXjAPVqdx82-ewpdw2eJTDxE1D_z0Q
```

### 2. Или верните ключ в constants.dart локально

```dart
// lib/core/constants.dart (только локально, НЕ коммитьте!)
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

**ВАЖНО:** Не коммитьте этот файл с реальным ключом!

---

## 🔄 Регулярные обновления

После изменений в коде:

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

## 📚 Документация

- **GIT_SETUP.md** - Подробная инструкция
- **GIT_КОМАНДЫ.txt** - Шпаргалка команд

---

## 🎉 Поздравляю!

Ваш проект Task Tracker теперь на GitHub и готов к совместной разработке!
