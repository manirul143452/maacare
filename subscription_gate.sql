-- ============================================================
--  InsForge – MaaCare Freemium Subscription Schema Extensions
-- ============================================================

-- 1. Create public.user_subscriptions table
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  is_premium        BOOLEAN DEFAULT false,
  ai_message_count  INT DEFAULT 0,
  expires_at        TIMESTAMPTZ
);

-- 2. Enable RLS and add public access policies
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can manage own subscriptions" ON public.user_subscriptions
  FOR ALL USING (true);
