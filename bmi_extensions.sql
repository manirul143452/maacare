-- ============================================================
--  InsForge – MaaCare BMI Database Schema Extensions
-- ============================================================

-- 1. Alter public.users table to add height and weight columns
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS height_cm NUMERIC,
ADD COLUMN IF NOT EXISTS weight_kg NUMERIC;

-- 2. Create public.bmi_logs table to track historical BMI logs
CREATE TABLE IF NOT EXISTS public.bmi_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES public.users(id) ON DELETE CASCADE,
  bmi_score     NUMERIC NOT NULL,
  weight_status VARCHAR NOT NULL,
  recorded_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enable RLS and add public access policies for public.bmi_logs
ALTER TABLE public.bmi_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own bmi logs" ON public.bmi_logs;
CREATE POLICY "Users can manage own bmi logs" ON public.bmi_logs
  FOR ALL USING (true);
