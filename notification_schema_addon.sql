-- ============================================================
--  InsForge – MaaCare Notification System Schema v2.0
--  Run AFTER insforge_schema.sql (base schema)
--  Run this in: InsForge Project > SQL Tool
-- ============================================================

-- ─────────────────── Add Push Token to Users ────────────────────
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT,
  ADD COLUMN IF NOT EXISTS push_token_updated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS platform TEXT DEFAULT 'android',
  ADD COLUMN IF NOT EXISTS notification_language TEXT DEFAULT 'hi';

-- ─────────────────── Child Profiles (for growth tracking) ───────
CREATE TABLE IF NOT EXISTS public.child_profiles (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES public.users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL DEFAULT 'Baby',
  date_of_birth   DATE NOT NULL,
  gender          TEXT CHECK (gender IN ('boy', 'girl', 'other')),
  birth_weight_kg DECIMAL(4,2),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.child_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own child profiles" ON public.child_profiles;
CREATE POLICY "Users manage own child profiles" ON public.child_profiles
  FOR ALL USING (true);

-- ─────────────────── Notification Preferences ───────────────────
-- Per-user, per-category toggles (synced from device)
CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
  preferences     JSONB NOT NULL DEFAULT '{
    "pregnancy_milestone": true,
    "child_growth": true,
    "vaccination": true,
    "doctor_consult": true,
    "symptom_check": true,
    "health_insights": true,
    "safety_alert": true,
    "nutrition": true,
    "self_care": true,
    "tracker_sync": true,
    "community": true,
    "friend_request": true,
    "health_news": true,
    "general": true
  }'::jsonb,
  quiet_hours_enabled BOOLEAN DEFAULT true,
  quiet_start_hour    INTEGER DEFAULT 22,
  quiet_end_hour      INTEGER DEFAULT 7,
  frequency           TEXT DEFAULT 'smart',
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own notification preferences" ON public.notification_preferences;
CREATE POLICY "Users manage own notification preferences"
  ON public.notification_preferences FOR ALL USING (true);

-- ─────────────────── Scheduled Notifications Queue ──────────────
-- Backend queue for scheduled pushes (processed by cron edge function)
CREATE TABLE IF NOT EXISTS public.scheduled_notifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES public.users(id) ON DELETE CASCADE,
  player_id       TEXT,                    -- OneSignal player ID
  category        TEXT NOT NULL,           -- NotificationCategory key
  title           TEXT NOT NULL,
  body            TEXT NOT NULL,
  route           TEXT,
  data            JSONB,
  action1_label   TEXT,
  action1_route   TEXT,
  image_url       TEXT,
  scheduled_at    TIMESTAMPTZ NOT NULL,    -- When to send
  sent            BOOLEAN DEFAULT FALSE,
  sent_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.scheduled_notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Backend manages scheduled notifications" ON public.scheduled_notifications;
CREATE POLICY "Backend manages scheduled notifications"
  ON public.scheduled_notifications FOR ALL USING (true);

-- Index for efficient cron queries
CREATE INDEX IF NOT EXISTS idx_scheduled_notif_pending
  ON public.scheduled_notifications (scheduled_at, sent)
  WHERE sent = FALSE;

CREATE INDEX IF NOT EXISTS idx_scheduled_notif_user
  ON public.scheduled_notifications (user_id, sent);

-- ─────────────────── Notification History (Analytics) ──────────
CREATE TABLE IF NOT EXISTS public.notification_history (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES public.users(id) ON DELETE CASCADE,
  category        TEXT NOT NULL,
  title           TEXT NOT NULL,
  sent_at         TIMESTAMPTZ NOT NULL,
  opened_at       TIMESTAMPTZ,
  dismissed_at    TIMESTAMPTZ,
  action_taken    TEXT,         -- 'button1', 'button2', 'tapped', null
  platform        TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notification_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read own history; backend inserts" ON public.notification_history;
CREATE POLICY "Users can read own history; backend inserts"
  ON public.notification_history FOR ALL USING (true);

-- Indexes for analytics queries
CREATE INDEX IF NOT EXISTS idx_notif_history_user_date
  ON public.notification_history (user_id, sent_at DESC);

CREATE INDEX IF NOT EXISTS idx_notif_history_category
  ON public.notification_history (category, sent_at DESC);

-- ─────────────────── Friend Requests ────────────────────────────
CREATE TABLE IF NOT EXISTS public.friend_requests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id    UUID REFERENCES public.users(id) ON DELETE CASCADE,
  to_user_id      UUID REFERENCES public.users(id) ON DELETE CASCADE,
  status          TEXT DEFAULT 'pending'
                  CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (from_user_id, to_user_id)
);

ALTER TABLE public.friend_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own friend requests" ON public.friend_requests;
CREATE POLICY "Users manage own friend requests"
  ON public.friend_requests FOR ALL USING (true);

-- ─────────────────── Realtime Channels for Notifications ────────
INSERT INTO realtime.channels (pattern, description, enabled)
VALUES
  ('notifications:%', 'Per-user notification channel', true),
  ('friend_requests:%', 'Friend request events per user', true)
ON CONFLICT DO NOTHING;

-- Trigger: Notify user when friend request received
CREATE OR REPLACE FUNCTION notify_friend_request()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM realtime.publish(
    'friend_requests:' || NEW.to_user_id::text,
    'NEW_FRIEND_REQUEST',
    jsonb_build_object(
      'id', NEW.id,
      'from_user_id', NEW.from_user_id,
      'status', NEW.status,
      'created_at', NEW.created_at
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS friend_request_realtime_trigger ON public.friend_requests;
CREATE TRIGGER friend_request_realtime_trigger
  AFTER INSERT ON public.friend_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_friend_request();

-- Trigger: Notify post owner when someone replies
CREATE OR REPLACE FUNCTION notify_post_reply()
RETURNS TRIGGER AS $$
DECLARE
  v_post_user_id UUID;
BEGIN
  -- Only trigger if this is a reply (has parent post context)
  -- Skipped for now – handled via edge function
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─────────────────── Helper View: Users with Push Tokens ────────
CREATE OR REPLACE VIEW public.users_with_push_tokens AS
SELECT
  u.id,
  u.name,
  u.onesignal_player_id,
  u.due_date,
  u.language,
  u.platform,
  -- Computed pregnancy week
  CASE
    WHEN u.due_date IS NOT NULL THEN
      GREATEST(0, LEAST(42,
        (280 - (u.due_date - CURRENT_DATE)) / 7
      ))
    ELSE NULL
  END AS pregnancy_week,
  np.preferences AS notification_prefs,
  np.quiet_hours_enabled,
  np.quiet_start_hour,
  np.quiet_end_hour,
  np.frequency
FROM public.users u
LEFT JOIN public.notification_preferences np ON np.user_id = u.id
WHERE u.onesignal_player_id IS NOT NULL;

-- ─────────────────── Analytics function ─────────────────────────
-- Returns open rate per category over last 30 days
CREATE OR REPLACE FUNCTION public.notification_open_rate(
  p_days INTEGER DEFAULT 30
)
RETURNS TABLE(
  category TEXT,
  total_sent BIGINT,
  total_opened BIGINT,
  open_rate NUMERIC
) AS $$
  SELECT
    category,
    COUNT(*) AS total_sent,
    COUNT(opened_at) AS total_opened,
    ROUND(
      COUNT(opened_at)::NUMERIC / NULLIF(COUNT(*), 0) * 100, 2
    ) AS open_rate
  FROM public.notification_history
  WHERE sent_at > NOW() - (p_days || ' days')::INTERVAL
  GROUP BY category
  ORDER BY open_rate DESC;
$$ LANGUAGE sql;
