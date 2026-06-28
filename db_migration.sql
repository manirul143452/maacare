-- maaCare Doctor & Reports migration script

-- 1. Alter public.doctor_profiles to support custom admin fields
ALTER TABLE public.doctor_profiles ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.doctor_profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.doctor_profiles ADD COLUMN IF NOT EXISTS password_hash TEXT;
ALTER TABLE public.doctor_profiles ADD COLUMN IF NOT EXISTS consultation_fee NUMERIC;
ALTER TABLE public.doctor_profiles ADD COLUMN IF NOT EXISTS available_slots TEXT[];

-- 2. Create the patient_reports table
CREATE TABLE IF NOT EXISTS public.patient_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES public.doctors(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  submitted_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS and add policies
ALTER TABLE public.patient_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Manage patient reports" ON public.patient_reports;
CREATE POLICY "Manage patient reports" ON public.patient_reports FOR ALL USING (true);

-- 3. Seed Dr. Manirul Hussain (Money) into auth.users
INSERT INTO auth.users (id, email, password, email_verified)
VALUES (
  'd91f5b40-34af-48af-8fc9-442b5e697b9e',
  'manirul@maacare.com',
  'MoneyTest2026!',
  true
)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  password = EXCLUDED.password,
  email_verified = EXCLUDED.email_verified;

-- 4. Seed into public.users
INSERT INTO public.users (id, name, email, user_role, is_premium)
VALUES (
  'd91f5b40-34af-48af-8fc9-442b5e697b9e',
  'Dr. Manirul Hussain (Money) - Senior Gynaecology Specialist',
  'manirul@maacare.com',
  'doctor',
  true
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  user_role = EXCLUDED.user_role,
  is_premium = EXCLUDED.is_premium;

-- 5. Seed into public.doctor_profiles
INSERT INTO public.doctor_profiles (id, user_id, name, email, password_hash, specialization, consultation_fee, available_slots, is_verified)
VALUES (
  'd91f5b40-34af-48af-8fc9-442b5e697b9e',
  'd91f5b40-34af-48af-8fc9-442b5e697b9e',
  'Dr. Manirul Hussain (Money) - Senior Gynaecology Specialist',
  'manirul@maacare.com',
  'MoneyTest2026!',
  'Menstrual Regularity, Clinical Triage & Hormonal Health Architecture',
  1.00,
  ARRAY['09:00 AM', '11:00 AM', '02:30 PM', '05:00 PM'],
  true
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  password_hash = EXCLUDED.password_hash,
  specialization = EXCLUDED.specialization,
  consultation_fee = EXCLUDED.consultation_fee,
  available_slots = EXCLUDED.available_slots,
  is_verified = EXCLUDED.is_verified;

-- 6. Seed into public.doctors
INSERT INTO public.doctors (id, user_id, name, specialization, fee, available_hours, is_verified, status)
VALUES (
  'd91f5b40-34af-48af-8fc9-442b5e697b9e',
  'd91f5b40-34af-48af-8fc9-442b5e697b9e',
  'Dr. Manirul Hussain (Money) - Senior Gynaecology Specialist',
  'Menstrual Regularity, Clinical Triage & Hormonal Health Architecture',
  '₹1',
  '09:00 AM - 05:00 PM',
  true,
  'verified'
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  name = EXCLUDED.name,
  specialization = EXCLUDED.specialization,
  fee = EXCLUDED.fee,
  available_hours = EXCLUDED.available_hours,
  is_verified = EXCLUDED.is_verified,
  status = EXCLUDED.status;
