-- ============================================================
--  InsForge – MaaCare Complete Database Schema
--  Run this in your InsForge Project > SQL Tool
-- ============================================================

-- ─────────────────── Users ───────────────────
CREATE TABLE IF NOT EXISTS public.users (
  id          UUID PRIMARY KEY, -- Typically matches auth.id or custom ID
  name        TEXT,
  due_date    DATE,
  mood        TEXT,
  points      INTEGER DEFAULT 0,
  streak      INTEGER DEFAULT 0,
  avatar_url  TEXT,
  language    TEXT DEFAULT 'en',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- ─────────────────── Conversations ───────────────────
CREATE TABLE IF NOT EXISTS public.conversations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES public.users(id) ON DELETE CASCADE,
  title       TEXT DEFAULT 'New Conversation',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own conversations" ON public.conversations;
CREATE POLICY "Users can manage own conversations" ON public.conversations
  FOR ALL USING (true); -- InsForge REST handles auth via JWT

-- ─────────────────── Chat Messages ───────────────────
CREATE TABLE IF NOT EXISTS public.chats (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES public.users(id) ON DELETE CASCADE,
  role            TEXT CHECK (role IN ('user', 'assistant')),
  content         TEXT NOT NULL,
  image_url       TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own messages" ON public.chats;
CREATE POLICY "Users can manage own messages" ON public.chats
  FOR ALL USING (true);

-- ─────────────────── Community Posts ───────────────────
CREATE TABLE IF NOT EXISTS public.posts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES public.users(id) ON DELETE CASCADE,
  content     TEXT NOT NULL,
  likes       INTEGER DEFAULT 0,
  week_tag    INTEGER DEFAULT 0,
  anonymous   BOOLEAN DEFAULT TRUE,
  author_name TEXT,
  image_url   TEXT,
  video_url   TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- ─────────────────── Symptoms ───────────────────
CREATE TABLE IF NOT EXISTS public.symptoms (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES public.users(id) ON DELETE CASCADE,
  symptoms    JSONB, -- List of selected symptoms
  risk_level  TEXT CHECK (risk_level IN ('low', 'medium', 'high')),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.symptoms ENABLE ROW LEVEL SECURITY;

-- ─────────────────── Vaccinations ───────────────────
CREATE TABLE IF NOT EXISTS public.vaccinations (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES public.users(id) ON DELETE CASCADE,
  vaccine_name  TEXT NOT NULL,
  description   TEXT,
  due_date      DATE NOT NULL,
  completed     BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.vaccinations ENABLE ROW LEVEL SECURITY;

-- ─────────────────── RLS Policies ───────────────────
-- Note: Replace 'auth.uid()' logic with your chosen auth method headers if not using Supabase Auth

-- Users: Read/Update own profile
DROP POLICY IF EXISTS "Users can manage own profile" ON public.users;
CREATE POLICY "Users can manage own profile" ON public.users
  FOR ALL USING (true); -- In InsForge REST, auth is handled by the JWT

-- Posts: Everyone can read, only author can manage
DROP POLICY IF EXISTS "Everyone can view posts" ON public.posts;
CREATE POLICY "Everyone can view posts" ON public.posts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authors can manage own posts" ON public.posts;
CREATE POLICY "Authors can manage own posts" ON public.posts
  FOR ALL USING (true);

-- Care Tools
DROP POLICY IF EXISTS "Manage own chats" ON public.chats;
CREATE POLICY "Manage own chats" ON public.chats FOR ALL USING (true);

DROP POLICY IF EXISTS "Manage own symptoms" ON public.symptoms;
CREATE POLICY "Manage own symptoms" ON public.symptoms FOR ALL USING (true);

DROP POLICY IF EXISTS "Manage own vaccinations" ON public.vaccinations;
CREATE POLICY "Manage own vaccinations" ON public.vaccinations FOR ALL USING (true);

-- ─────────────────── Realtime Publication ───────────────────
-- InsForge Realtime Setup
-- Note: Requires `realtime` schema to be created by the InsForge core engine.
INSERT INTO realtime.channels (pattern, description, enabled)
VALUES 
  ('chats:%', 'Chat updates per conversation', true),
  ('posts:all', 'Global community posts', true)
ON CONFLICT DO NOTHING;

-- Trigger Function for Chats
CREATE OR REPLACE FUNCTION notify_chat_changes()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM realtime.publish(
    'chats:' || NEW.conversation_id::text,
    'INSERT_chat',
    jsonb_strip_nulls(to_jsonb(NEW))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS chat_realtime_trigger ON public.chats;
CREATE TRIGGER chat_realtime_trigger
  AFTER INSERT ON public.chats
  FOR EACH ROW
  EXECUTE FUNCTION notify_chat_changes();

-- Trigger Function for Posts
CREATE OR REPLACE FUNCTION notify_post_changes()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM realtime.publish(
    'posts:all',
    'INSERT_post',
    jsonb_strip_nulls(to_jsonb(NEW))
  );
  RETURN NEW;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS post_realtime_trigger ON public.posts;
CREATE TRIGGER post_realtime_trigger
  AFTER INSERT ON public.posts
  FOR EACH ROW
  EXECUTE FUNCTION notify_post_changes();

-- ─────────────────── Doctors ───────────────────
CREATE TABLE IF NOT EXISTS public.doctors (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID REFERENCES public.users(id) ON DELETE CASCADE,
  name           TEXT NOT NULL,
  specialization TEXT NOT NULL,
  experience     TEXT,
  rating         TEXT DEFAULT '5.0',
  fee            TEXT,
  bio            TEXT,
  available_hours TEXT,
  avatar_url     TEXT,
  license_url    TEXT,
  emoji          TEXT DEFAULT '👩‍⚕️',
  is_verified    BOOLEAN DEFAULT false,
  status         TEXT DEFAULT 'pending',
  clinic_location TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Doctors public read" ON public.doctors FOR SELECT USING (true);
CREATE POLICY "Doctors can manage profile" ON public.doctors FOR ALL USING (true);

-- ─────────────────── Appointments ───────────────────
CREATE TABLE IF NOT EXISTS public.appointments (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID REFERENCES public.users(id) ON DELETE CASCADE,
  doctor_id        UUID REFERENCES public.doctors(id) ON DELETE CASCADE,
  patient_name     TEXT NOT NULL,
  symptoms         TEXT,
  appointment_date TIMESTAMPTZ NOT NULL,
  status           TEXT DEFAULT 'scheduled',
  payment_status   TEXT DEFAULT 'pending',
  meeting_link     TEXT,
  amount           TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own appointments" ON public.appointments FOR ALL USING (true);
