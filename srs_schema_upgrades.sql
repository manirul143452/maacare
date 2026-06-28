-- ============================================================
--  InsForge – MaaCare SRS Schema Upgrades Database Migration
--  Run this in your InsForge Project > SQL Tool
-- ============================================================

-- 1. Ensure public.users has profile_photo_url column
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- 2. Ensure public.menstrual_logs has profile_photo_url column
ALTER TABLE public.menstrual_logs ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- 3. Create or Upgrade public.doctor_profiles table
CREATE TABLE IF NOT EXISTS public.doctor_profiles (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 UUID REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
  medical_registration_no TEXT,
  specialization          TEXT,
  hospital_affiliation    TEXT,
  is_verified             BOOLEAN DEFAULT false,
  profile_photo_url       TEXT,
  created_at              TIMESTAMPTZ DEFAULT NOW()
);

-- Force is_verified default to false and add profile_photo_url if it already existed
ALTER TABLE public.doctor_profiles ALTER COLUMN is_verified SET DEFAULT false;
ALTER TABLE public.doctor_profiles ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- 4. Also add profile_photo_url to public.doctors as compatibility fallback
ALTER TABLE public.doctors ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;
