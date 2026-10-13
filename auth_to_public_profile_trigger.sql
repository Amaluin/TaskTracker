-- ============================================
-- Синхронизация auth.users -> public.user_profiles
-- ============================================
-- Что делает:
-- 1) Создает/обновляет функцию create_user_profile()
-- 2) Создает AFTER INSERT trigger на auth.users
-- 3) Дозаполняет профили для уже существующих пользователей
-- ============================================

-- Таблица профилей (если еще не создана)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone TEXT,
  display_name TEXT NOT NULL DEFAULT 'Пользователь',
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Функция создания/обновления профиля
CREATE OR REPLACE FUNCTION public.create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, phone, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'phone', NEW.phone, ''),
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'name',
      'Пользователь'
    )
  )
  ON CONFLICT (id) DO UPDATE
  SET
    phone = EXCLUDED.phone,
    display_name = EXCLUDED.display_name,
    updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Триггер: новый пользователь в auth -> профиль в public
DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.create_user_profile();

-- Backfill: создать профили для уже существующих пользователей
INSERT INTO public.user_profiles (id, phone, display_name)
SELECT
  au.id,
  COALESCE(au.raw_user_meta_data->>'phone', au.phone, ''),
  COALESCE(
    au.raw_user_meta_data->>'display_name',
    au.raw_user_meta_data->>'name',
    'Пользователь'
  )
FROM auth.users au
LEFT JOIN public.user_profiles up ON up.id = au.id
WHERE up.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- Права чтения/обновления профиля
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
CREATE POLICY "Users can read own profile"
  ON public.user_profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());
