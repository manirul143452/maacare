-- Ensure fcm_token column exists in public.users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
