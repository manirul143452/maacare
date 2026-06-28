-- Create menstrual_logs table
CREATE TABLE IF NOT EXISTS public.menstrual_logs (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  last_period_start_date TIMESTAMP WITH TIME ZONE,
  average_cycle_length INTEGER DEFAULT 28,
  logged_symptoms JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.menstrual_logs ENABLE ROW LEVEL SECURITY;

-- Create policies
DROP POLICY IF EXISTS "Users can manage own menstrual logs" ON public.menstrual_logs;
CREATE POLICY "Users can manage own menstrual logs" ON public.menstrual_logs FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "project_admin_policy" ON public.menstrual_logs;
CREATE POLICY "project_admin_policy" ON public.menstrual_logs FOR ALL TO project_admin USING (true) WITH CHECK (true);

-- Update appointments table
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS user_role VARCHAR DEFAULT 'mother';
