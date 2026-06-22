// MaaCare Doctor Seed Script
// Run: node seed_doctors.js
// Seeds 10 verified doctors into MongoDB

require('dotenv').config();
const { MongoClient } = require('mongodb');
const crypto = require('crypto');

const MONGO_URI = process.env.MONGO_URI;

const doctors = [
  {
    id: crypto.randomUUID(),
    name: 'Dr. Priya Sharma',
    specialization: 'Gynecologist & Obstetrician',
    experience: '12 yrs',
    rating: '4.9',
    fee: '₹500',
    bio: 'Senior Gynecologist with 12+ years in women\'s health, pregnancy care, and laparoscopic surgery. AIIMS Delhi alumna.',
    available_hours: '9:00 AM – 5:00 PM',
    emoji: '👩‍⚕️',
    is_verified: true,
    status: 'verified',
    clinic_location: 'New Delhi / Online',
    available_days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    slot_duration_minutes: 20,
    daily_start_time: '09:00:00',
    daily_end_time: '17:00:00',
    created_at: new Date(),
  },
  {
    id: crypto.randomUUID(),
    name: 'Dr. Anjali Mehta',
    specialization: 'Women\'s Health & GyneCare Specialist',
    experience: '8 yrs',
    rating: '4.8',
    fee: '₹400',
    bio: 'Specializes in PCOS, endometriosis, menstrual disorders, and unmarried women\'s health. Confidential consultations assured.',
    available_hours: '10:00 AM – 6:00 PM',
    emoji: '🩺',
    is_verified: true,
    status: 'verified',
    clinic_location: 'Mumbai / Online',
    available_days: ['Monday', 'Wednesday', 'Friday', 'Saturday'],
    slot_duration_minutes: 20,
    daily_start_time: '10:00:00',
    daily_end_time: '18:00:00',
    created_at: new Date(),
  },
  {
    id: crypto.randomUUID(),
    name: 'Dr. Sunita Rao',
    specialization: 'Obstetrician & Maternal-Fetal Medicine',
    experience: '15 yrs',
    rating: '4.9',
    fee: '₹600',
    bio: 'High-risk pregnancy specialist, fetal medicine expert. 15 years guiding mothers through complicated pregnancies with compassion.',
    available_hours: '8:00 AM – 2:00 PM',
    emoji: '🤰',
    is_verified: true,
    status: 'verified',
    clinic_location: 'Bangalore / Online',
    available_days: ['Monday', 'Tuesday', 'Thursday', 'Friday'],
    slot_duration_minutes: 30,
    daily_start_time: '08:00:00',
    daily_end_time: '14:00:00',
    created_at: new Date(),
  },
  {
    id: crypto.randomUUID(),
    name: 'Dr. Fatima Khan',
    specialization: 'Gynaecologist & Reproductive Health',
    experience: '10 yrs',
    rating: '4.7',
    fee: '₹450',
    bio: 'Expert in reproductive health, fertility, and contraception counselling. Fluent in Hindi, Urdu, and English.',
    available_hours: '11:00 AM – 7:00 PM',
    emoji: '💊',
    is_verified: true,
    status: 'verified',
    clinic_location: 'Hyderabad / Online',
    available_days: ['Tuesday', 'Wednesday', 'Thursday', 'Saturday'],
    slot_duration_minutes: 20,
    daily_start_time: '11:00:00',
    daily_end_time: '19:00:00',
    created_at: new Date(),
  },
  {
    id: crypto.randomUUID(),
    name: 'Dr. Rekha Nair',
    specialization: 'Gynaecologist & Menopause Specialist',
    experience: '18 yrs',
    rating: '5.0',
    fee: '₹700',
    bio: 'Senior consultant specializing in menopause management, hormone therapy, and women\'s wellness at all life stages.',
    available_hours: '9:00 AM – 1:00 PM',
    emoji: '🌸',
    is_verified: true,
    status: 'verified',
    clinic_location: 'Chennai / Online',
    available_days: ['Monday', 'Wednesday', 'Friday'],
    slot_duration_minutes: 30,
    daily_start_time: '09:00:00',
    daily_end_time: '13:00:00',
    created_at: new Date(),
  },
  {
    id: crypto.randomUUID(),
    name: 'Dr. Meera Gupta',
    specialization: 'Obstetrics & Gynecology',
    experience: '6 yrs',
    rating: '4.6',
    fee: '₹350',
    bio: 'Young, empathetic OB-GYN focused on evidence-based care for first-time mothers and teens. Welcoming and non-judgmental.',
    available_hours: '2:00 PM – 8:00 PM',
    emoji: '👶',
    is_verified: true,
    status: 'verified',
    clinic_location: 'Pune / Online',
    available_days: ['Monday', 'Tuesday', 'Thursday', 'Friday', 'Saturday'],
    slot_duration_minutes: 20,
    daily_start_time: '14:00:00',
    daily_end_time: '20:00:00',
    created_at: new Date(),
  },
  {
    id: crypto.randomUUID(),
    name: 'Dr. Lakshmi Iyer',
    specialization: 'Women\'s Health & Adolescent Gynaecology',
    experience: '9 yrs',
    rating: '4.8',
    fee: '₹400',
    bio: 'Specializes in adolescent and young women\'s health, menstrual issues, and safe contraception. Confidential & caring.',
    available_hours: '10:00 AM – 5:00 PM',
    emoji: '🌺',
    is_verified: true,
    status: 'verified',
    clinic_location: 'Kolkata / Online',
    available_days: ['Monday', 'Wednesday', 'Thursday', 'Saturday'],
    slot_duration_minutes: 20,
    daily_start_time: '10:00:00',
    daily_end_time: '17:00:00',
    created_at: new Date(),
  },
  {
    id: crypto.randomUUID(),
    name: 'Dr. Divya Patel',
    specialization: 'Gynecologist & PCOS Expert',
    experience: '11 yrs',
    rating: '4.9',
    fee: '₹500',
    bio: 'PCOS, thyroid, and hormonal imbalance specialist. Holistic approach combining diet, lifestyle, and medical treatment.',
    available_hours: '9:00 AM – 4:00 PM',
    emoji: '🔬',
    is_verified: true,
    status: 'verified',
    clinic_location: 'Ahmedabad / Online',
    available_days: ['Tuesday', 'Thursday', 'Friday', 'Saturday'],
    slot_duration_minutes: 25,
    daily_start_time: '09:00:00',
    daily_end_time: '16:00:00',
    created_at: new Date(),
  },
  {
    id: crypto.randomUUID(),
    name: 'Dr. Nandita Roy',
    specialization: 'Obstetrician & Lactation Consultant',
    experience: '7 yrs',
    rating: '4.7',
    fee: '₹300',
    bio: 'Pregnancy care and breastfeeding specialist. Guides new mothers through postpartum recovery and newborn care.',
    available_hours: '8:00 AM – 12:00 PM',
    emoji: '🤱',
    is_verified: true,
    status: 'verified',
    clinic_location: 'Guwahati / Online',
    available_days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    slot_duration_minutes: 20,
    daily_start_time: '08:00:00',
    daily_end_time: '12:00:00',
    created_at: new Date(),
  },
  {
    id: crypto.randomUUID(),
    name: 'Dr. Rashida Begum',
    specialization: 'Gynecologist & Infertility Specialist',
    experience: '14 yrs',
    rating: '4.8',
    fee: '₹600',
    bio: 'Fertility and IVF specialist with 14 years of experience. Has helped 2000+ couples achieve parenthood.',
    available_hours: '10:00 AM – 6:00 PM',
    emoji: '💝',
    is_verified: true,
    status: 'verified',
    clinic_location: 'Lucknow / Online',
    available_days: ['Monday', 'Tuesday', 'Thursday', 'Friday'],
    slot_duration_minutes: 30,
    daily_start_time: '10:00:00',
    daily_end_time: '18:00:00',
    created_at: new Date(),
  },
];

async function seed() {
  const client = new MongoClient(MONGO_URI);
  try {
    await client.connect();
    const db = client.db('maacare');
    const collection = db.collection('doctors');

    // Check if already seeded
    const existing = await collection.countDocuments();
    if (existing > 0) {
      console.log(`✅ Doctors already seeded (${existing} doctors found). Skipping.`);
      return;
    }

    await collection.insertMany(doctors.map(d => ({ ...d, _id: d.id })));
    console.log(`✅ Successfully seeded ${doctors.length} doctors into MongoDB!`);

    // List them
    const all = await collection.find({}, { projection: { name: 1, specialization: 1, fee: 1 } }).toArray();
    all.forEach(d => console.log(`  👩‍⚕️ ${d.name} — ${d.specialization} — ${d.fee}`));
  } catch (err) {
    console.error('❌ Seeding failed:', err.message);
  } finally {
    await client.close();
  }
}

seed();
