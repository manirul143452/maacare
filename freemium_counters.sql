-- ============================================================
--  InsForge – MaaCare Freemium Subscription Schema Extension
-- ============================================================

-- 1. Add precise telemetry counters to public.user_subscriptions table
ALTER TABLE public.user_subscriptions ADD COLUMN IF NOT EXISTS free_cycle_generation_count INT DEFAULT 0;
ALTER TABLE public.user_subscriptions ADD COLUMN IF NOT EXISTS free_pregnancy_generation_count INT DEFAULT 0;
ALTER TABLE public.user_subscriptions ADD COLUMN IF NOT EXISTS free_ai_chat_count INT DEFAULT 0;
