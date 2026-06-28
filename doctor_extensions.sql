-- ============================================================
--  InsForge – MaaCare Doctor Dashboard Database Schema Extensions
-- ============================================================

-- 1. Alter public.doctors table to add scheduling configurations
ALTER TABLE public.doctors
ADD COLUMN IF NOT EXISTS available_days JSONB DEFAULT '["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]'::jsonb,
ADD COLUMN IF NOT EXISTS slot_duration_minutes INT DEFAULT 20,
ADD COLUMN IF NOT EXISTS daily_start_time TIME DEFAULT '09:00:00',
ADD COLUMN IF NOT EXISTS daily_end_time TIME DEFAULT '17:00:00';

-- 2. Create public.consultation_sessions table
CREATE TABLE IF NOT EXISTS public.consultation_sessions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id         UUID REFERENCES public.doctors(id) ON DELETE CASCADE,
  patient_id        UUID REFERENCES public.users(id) ON DELETE CASCADE,
  patient_role      TEXT CHECK (patient_role IN ('mother', 'unmarried_girl')),
  scheduled_time    TIMESTAMPTZ NOT NULL,
  status            TEXT CHECK (status IN ('pending', 'active', 'completed')) DEFAULT 'pending',
  prescription_text TEXT,
  room_id           TEXT, -- 100ms Dynamic Room ID
  auth_token        TEXT, -- 100ms Dynamic Auth Token
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enable RLS and add policies for public.consultation_sessions
ALTER TABLE public.consultation_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Manage consultation sessions" ON public.consultation_sessions;
CREATE POLICY "Manage consultation sessions" ON public.consultation_sessions
  FOR ALL USING (true);
