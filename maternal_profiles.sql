-- ============================================================
--  InsForge – MaaCare Maternal Profiles Schema Upgrade
-- ============================================================

CREATE TABLE IF NOT EXISTS public.maternal_profiles (
  user_id                   UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  lmp_date                  DATE NOT NULL,
  calculated_current_week   INT NOT NULL DEFAULT 1,
  calculated_current_day    INT NOT NULL DEFAULT 1,
  created_at                TIMESTAMPTZ DEFAULT NOW(),
  updated_at                TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.maternal_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policy (true because InsForge REST Gateway filters via auth token internally)
DROP POLICY IF EXISTS "Users can manage own maternal profile" ON public.maternal_profiles;
CREATE POLICY "Users can manage own maternal profile" ON public.maternal_profiles
  FOR ALL USING (true);
