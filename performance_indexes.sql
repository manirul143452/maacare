-- ============================================================
--  InsForge – MaaCare Performance Indexes Database Migration
--  Run this in your InsForge Project > SQL Tool
-- ============================================================

-- Note: public.menstrual_logs uses user_id as its PRIMARY KEY, 
-- which automatically creates a unique B-Tree index in PostgreSQL.

-- 1. Index conversations by user_id
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON public.conversations(user_id);

-- 2. Index chats by conversation_id and user_id
CREATE INDEX IF NOT EXISTS idx_chats_conversation_id ON public.chats(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chats_user_id ON public.chats(user_id);

-- 3. Index community posts by user_id
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON public.posts(user_id);

-- 4. Index symptoms by user_id
CREATE INDEX IF NOT EXISTS idx_symptoms_user_id ON public.symptoms(user_id);

-- 5. Index vaccinations by user_id
CREATE INDEX IF NOT EXISTS idx_vaccinations_user_id ON public.vaccinations(user_id);

-- 6. Index doctor profiles by user_id
CREATE INDEX IF NOT EXISTS idx_doctors_user_id ON public.doctors(user_id);

-- 7. Index appointments by user_id and doctor_id
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON public.appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON public.appointments(doctor_id);

-- 8. Index consultation sessions by doctor_id and patient_id
CREATE INDEX IF NOT EXISTS idx_consultation_sessions_doctor_id ON public.consultation_sessions(doctor_id);
CREATE INDEX IF NOT EXISTS idx_consultation_sessions_patient_id ON public.consultation_sessions(patient_id);
