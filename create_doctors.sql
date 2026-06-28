CREATE TABLE IF NOT EXISTS doctors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    specialization TEXT NOT NULL,
    experience TEXT NOT NULL,
    rating TEXT NOT NULL DEFAULT '5.0',
    fee TEXT NOT NULL,
    bio TEXT NOT NULL,
    available_hours TEXT NOT NULL,
    avatar_url TEXT,
    license_url TEXT,
    emoji TEXT DEFAULT '👩‍⚕️',
    is_verified BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'pending',
    clinic_location TEXT DEFAULT 'Online / Clinic',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "public_read_doctors" ON doctors FOR SELECT USING (true);
CREATE POLICY "owner_write_doctors" ON doctors FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "owner_update_doctors" ON doctors FOR UPDATE USING (auth.uid() = user_id);

-- Insert Sample Data
INSERT INTO doctors (id, name, specialization, experience, rating, fee, bio, available_hours, emoji, is_verified, status, clinic_location)
VALUES 
    (gen_random_uuid(), 'Dr. Aditi Sharma', 'Obstetrician & Gynecologist', '12 yrs', '4.9', '₹800', 'Specialized in high-risk pregnancies and postpartum care.', '10:00 AM - 4:00 PM', '👩‍⚕️', true, 'verified', 'City Hospital, Delhi'),
    (gen_random_uuid(), 'Dr. Rajesh Kumar', 'Pediatrician', '8 yrs', '4.8', '₹600', 'Dedicated to newborn care and early childhood nutrition.', '4:00 PM - 8:00 PM', '👨‍⚕️', true, 'verified', 'Care Clinic, Mumbai');
