// ============================================================
//  InsForge Edge Function: schedule-notifications
//  Cron scheduler – run every 30 minutes
//  POST /functions/schedule-notifications
//  Body: { "dry_run": true }  (optional)
// ============================================================

module.exports = async function (req) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, apikey, Authorization',
  };

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const getEnv = (key) =>
    typeof process !== 'undefined' && process.env[key]
      ? process.env[key]
      : Deno.env.get(key);

  const INSFORGE_URL = getEnv('INSFORGE_URL') || 'https://96if48kf.ap-southeast.insforge.app';
  const INSFORGE_SERVICE_KEY = getEnv('INSFORGE_SERVICE_KEY') || getEnv('ANON_KEY');
  const SEND_URL = `${INSFORGE_URL}/functions/send-notification`;

  let dryRun = false;
  try {
    const b = await req.json();
    dryRun = b.dry_run === true;
  } catch (_) {}

  const log = [];
  const now = new Date();
  const istNow = new Date(now.getTime() + 5.5 * 60 * 60 * 1000);
  const istHour = istNow.getUTCHours();
  const isMonday = istNow.getDay() === 1;

  console.log(`Scheduler | IST hour: ${istHour} | dry_run: ${dryRun}`);

  // ── DB helper ─────────────────────────────────────────────
  async function dbQuery(sql, params = []) {
    const res = await fetch(`${INSFORGE_URL}/api/database/query`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': INSFORGE_SERVICE_KEY,
      },
      body: JSON.stringify({ sql, params }),
    });
    if (!res.ok) {
      const t = await res.text();
      throw new Error(`DB error: ${t}`);
    }
    const json = await res.json();
    return json.data || [];
  }

  // ── Send helper ───────────────────────────────────────────
  async function send(payload) {
    if (dryRun) { console.log('DRY RUN:', payload.title, '->', payload.type); return; }
    await fetch(SEND_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'apikey': INSFORGE_SERVICE_KEY },
      body: JSON.stringify(payload),
    });
  }

  // ── Duplicate check ───────────────────────────────────────
  async function sentToday(userId, category) {
    const rows = await dbQuery(
      `SELECT 1 FROM public.notification_history
       WHERE user_id=$1 AND category=$2 AND sent_at > NOW() - INTERVAL '20 hours' LIMIT 1`,
      [userId, category]
    );
    return rows.length > 0;
  }

  async function sentThisWeek(userId, category) {
    const rows = await dbQuery(
      `SELECT 1 FROM public.notification_history
       WHERE user_id=$1 AND category=$2 AND sent_at > NOW() - INTERVAL '6 days' LIMIT 1`,
      [userId, category]
    );
    return rows.length > 0;
  }

  try {
    // ── 1. Pregnancy Milestones ───────────────────────────
    const milestoneWeeks = [4, 8, 12, 16, 20, 24, 28, 32, 36, 40];
    const pregnancyUsers = await dbQuery(`
      SELECT u.id, u.name, u.onesignal_player_id, u.due_date,
             np.preferences->>'pregnancy_milestone' AS pref
      FROM public.users u
      LEFT JOIN public.notification_preferences np ON np.user_id = u.id
      WHERE u.onesignal_player_id IS NOT NULL
        AND u.due_date IS NOT NULL
        AND u.due_date > CURRENT_DATE
        AND COALESCE(np.preferences->>'pregnancy_milestone','true') != 'false'
    `);

    for (const u of pregnancyUsers) {
      const dueDate = new Date(u.due_date);
      const daysLeft = Math.floor((dueDate - now) / 86400000);
      const week = Math.max(0, Math.min(42, Math.floor((280 - daysLeft) / 7)));
      if (!milestoneWeeks.includes(week)) continue;
      if (await sentToday(u.id, 'pregnancy_milestone')) continue;
      const c = pregnancyContent(week, u.name);
      await send({
        player_ids: [u.onesignal_player_id], user_ids: [u.id],
        title: c.title, body: c.body,
        type: 'pregnancy_milestone', route: '/tracker',
        data: { week }, action1_label: 'Tracker Dekho',
      });
      log.push(`pregnancy_w${week} → ${u.name}`);
    }

    // ── 2. Child Growth Milestones ────────────────────────
    const growthMonths = [1, 2, 4, 6, 9, 12, 15, 18, 24, 36, 48, 60, 72, 84, 96];
    let children = [];
    try {
      children = await dbQuery(`
        SELECT cp.user_id, cp.name AS child_name, cp.date_of_birth,
               u.onesignal_player_id,
               COALESCE(np.preferences->>'child_growth','true') AS pref
        FROM public.child_profiles cp
        JOIN public.users u ON u.id = cp.user_id
        LEFT JOIN public.notification_preferences np ON np.user_id = cp.user_id
        WHERE u.onesignal_player_id IS NOT NULL
          AND COALESCE(np.preferences->>'child_growth','true') != 'false'
      `);
    } catch (_) { /* table may not exist yet */ }

    for (const child of children) {
      const dob = new Date(child.date_of_birth);
      const ageMonths = Math.floor((now - dob) / (30.44 * 86400000));
      if (!growthMonths.includes(ageMonths)) continue;
      if (await sentToday(child.user_id, 'child_growth')) continue;
      const c = childContent(ageMonths, child.child_name);
      await send({
        player_ids: [child.onesignal_player_id], user_ids: [child.user_id],
        title: c.title, body: c.body,
        type: 'child_growth', route: '/child-growth',
        data: { age_months: ageMonths, child_name: child.child_name },
        action1_label: 'Milestones Dekho',
      });
      log.push(`child_growth_${ageMonths}m → ${child.user_id}`);
    }

    // ── 3. Vaccination Reminders ──────────────────────────
    let vaccinations = [];
    try {
      vaccinations = await dbQuery(`
        SELECT v.id, v.user_id, v.vaccine_name, v.due_date,
               u.onesignal_player_id
        FROM public.vaccinations v
        JOIN public.users u ON u.id = v.user_id
        LEFT JOIN public.notification_preferences np ON np.user_id = v.user_id
        WHERE v.completed = FALSE
          AND u.onesignal_player_id IS NOT NULL
          AND COALESCE(np.preferences->>'vaccination','true') != 'false'
          AND v.due_date BETWEEN CURRENT_DATE - INTERVAL '5 days'
                             AND CURRENT_DATE + INTERVAL '8 days'
      `);
    } catch (_) {}

    for (const vax of vaccinations) {
      const daysUntil = Math.floor((new Date(vax.due_date) - now) / 86400000);
      let rtype = daysUntil === 7 ? '7d' : daysUntil === 1 ? '1d'
                : daysUntil === 0 ? 'today' : (daysUntil < 0 && daysUntil >= -5) ? 'overdue' : null;
      if (!rtype) continue;
      if (await sentToday(vax.user_id, 'vaccination')) continue;
      const c = vaccinationContent(vax.vaccine_name, rtype);
      await send({
        player_ids: [vax.onesignal_player_id], user_ids: [vax.user_id],
        title: c.title, body: c.body,
        type: 'vaccination', route: '/vaccinations',
        data: { vaccination_id: vax.id, vaccine_name: vax.vaccine_name },
        action1_label: 'Schedule Karo',
      });
      log.push(`vax_${rtype} → ${vax.vaccine_name}`);
    }

    // ── 4. Doctor Appointment Reminders ──────────────────
    let appointments = [];
    try {
      appointments = await dbQuery(`
        SELECT a.id, a.user_id, a.appointment_date,
               d.name AS doctor_name, u.onesignal_player_id
        FROM public.appointments a
        JOIN public.doctors d ON d.id = a.doctor_id
        JOIN public.users u ON u.id = a.user_id
        LEFT JOIN public.notification_preferences np ON np.user_id = a.user_id
        WHERE a.status = 'scheduled'
          AND u.onesignal_player_id IS NOT NULL
          AND COALESCE(np.preferences->>'doctor_consult','true') != 'false'
          AND a.appointment_date BETWEEN NOW() AND NOW() + INTERVAL '49 hours'
      `);
    } catch (_) {}

    for (const appt of appointments) {
      const hoursUntil = (new Date(appt.appointment_date) - now) / 3600000;
      const rtype = hoursUntil <= 48 && hoursUntil > 47 ? '48h'
                  : hoursUntil <= 24 && hoursUntil > 23 ? '24h'
                  : hoursUntil <= 0.25 && hoursUntil > 0 ? '15min' : null;
      if (!rtype) continue;
      if (await sentToday(appt.user_id, `doctor_consult_${rtype}`)) continue;
      const c = doctorContent(appt.doctor_name, rtype);
      await send({
        player_ids: [appt.onesignal_player_id], user_ids: [appt.user_id],
        title: c.title, body: c.body,
        type: 'doctor_consult', route: '/consult',
        data: { appointment_id: appt.id },
        action1_label: rtype === '48h' ? 'Tayaari Karo' : 'Join Karo',
      });
      log.push(`doctor_${rtype} → ${appt.doctor_name}`);
    }

    // ── 5. Daily Nutrition Tip (9 AM IST) ────────────────
    if (istHour === 9) {
      const tips = nutritionTips();
      const tip = tips[istNow.getDay() % tips.length];
      const users = await dbQuery(`
        SELECT u.id, u.onesignal_player_id
        FROM public.users u
        LEFT JOIN public.notification_preferences np ON np.user_id = u.id
        WHERE u.onesignal_player_id IS NOT NULL
          AND COALESCE(np.preferences->>'nutrition','true') != 'false'
        LIMIT 500
      `);
      for (const u of users) {
        await send({
          player_ids: [u.onesignal_player_id], user_ids: [u.id],
          title: `🥗 ${tip.title}`, body: tip.body,
          type: 'nutrition', route: '/nutrition', action1_label: 'Recipe Dekho',
        });
      }
      log.push(`nutrition → ${users.length} users`);
    }

    // ── 6. Self-Care Reminder (7 PM IST) ─────────────────
    if (istHour === 19) {
      const users = await dbQuery(`
        SELECT u.id, u.onesignal_player_id
        FROM public.users u
        LEFT JOIN public.notification_preferences np ON np.user_id = u.id
        WHERE u.onesignal_player_id IS NOT NULL
          AND COALESCE(np.preferences->>'self_care','true') != 'false'
        LIMIT 500
      `);
      for (const u of users) {
        await send({
          player_ids: [u.onesignal_player_id], user_ids: [u.id],
          title: '🧘 Shaam Ki Self-Care!',
          body: 'Aaj 10 min yoga ya meditation karo. Mama ki care zaroori hai! 💕',
          type: 'self_care', route: '/self-care', action1_label: 'Session Shuru Karo',
        });
      }
      log.push(`self_care → ${users.length} users`);
    }

    // ── 7. Weekly Health Insights (Monday 10 AM IST) ─────
    if (isMonday && istHour === 10) {
      const users = await dbQuery(`
        SELECT u.id, u.name, u.onesignal_player_id
        FROM public.users u
        LEFT JOIN public.notification_preferences np ON np.user_id = u.id
        WHERE u.onesignal_player_id IS NOT NULL
          AND COALESCE(np.preferences->>'health_insights','true') != 'false'
        LIMIT 500
      `);
      for (const u of users) {
        const firstName = (u.name || 'Mama').split(' ')[0];
        await send({
          player_ids: [u.onesignal_player_id], user_ids: [u.id],
          title: '📊 Is Hafte Ki Health Report!',
          body: `${firstName}, aapki weekly health summary ready hai. Progress dekho! 🌟`,
          type: 'health_insights', route: '/health-insights', action1_label: 'Report Dekho',
        });
      }
      log.push(`health_insights → ${users.length} users`);
    }

    // ── 8. Tracker Sync Reminder ──────────────────────────
    let staleUsers = [];
    try {
      staleUsers = await dbQuery(`
        SELECT u.id, u.onesignal_player_id
        FROM public.users u
        LEFT JOIN public.notification_preferences np ON np.user_id = u.id
        WHERE u.onesignal_player_id IS NOT NULL
          AND COALESCE(np.preferences->>'tracker_sync','true') != 'false'
          AND u.updated_at < NOW() - INTERVAL '2 days'
        LIMIT 200
      `);
    } catch (_) {}
    for (const u of staleUsers) {
      if (await sentThisWeek(u.id, 'tracker_sync')) continue;
      await send({
        player_ids: [u.onesignal_player_id], user_ids: [u.id],
        title: '📈 Tracker Update Karo!',
        body: '2 din ho gaye update kiye bina. Progress track karna zaruri hai 💕',
        type: 'tracker_sync', route: '/tracker', action1_label: 'Abhi Update Karo',
      });
      log.push(`tracker_sync → ${u.id}`);
    }

    // ── 9. Scheduled Notifications Queue ─────────────────
    let pending = [];
    try {
      pending = await dbQuery(`
        SELECT * FROM public.scheduled_notifications
        WHERE sent = FALSE AND scheduled_at <= NOW()
        LIMIT 100
      `);
    } catch (_) {}
    for (const notif of pending) {
      await send({
        player_ids: [notif.player_id], user_ids: [notif.user_id],
        title: notif.title, body: notif.body,
        type: notif.category, route: notif.route, data: notif.data,
        action1_label: notif.action1_label,
      });
      if (!dryRun) {
        await dbQuery(
          `UPDATE public.scheduled_notifications SET sent=TRUE, sent_at=NOW() WHERE id=$1`,
          [notif.id]
        );
      }
      log.push(`queue → ${notif.category}`);
    }

    console.log(`✅ Scheduler done | ${log.length} actions`);
    return new Response(
      JSON.stringify({ success: true, dry_run: dryRun, actions: log }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('Scheduler error:', err.message);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
};

// ── Content Generators ────────────────────────────────────────
function pregnancyContent(week, name) {
  const n = (name || 'Mama').split(' ')[0];
  const map = {
    4:  { title: '🌱 Week 4 – Safar Shuru!', body: `Badhaaiyan ${n}! Pehla appointment book karein 💕` },
    8:  { title: '🫐 Week 8 – Baby Ka Dil!', body: 'Baby ki heartbeat check karwao! 💗' },
    12: { title: '🍋 Week 12 – Pehla Trimester!', body: 'NT scan aur blood tests schedule karo 🌟' },
    16: { title: '🥑 Week 16 – Pehli Kick?', body: 'Shayad pehli kicks mehsoos hon! 💝' },
    20: { title: '🍌 Week 20 – Aadha Safar!', body: 'Anatomy scan ka time! Baby banana jitna bada hai 🎉' },
    24: { title: '🌽 Week 24 – Baby Sun Raha Hai!', body: 'Baby ab awaazein sun sakta hai – lori sunao! 🎵' },
    28: { title: '🍆 Week 28 – Third Trimester!', body: `Badhaayi ${n}! Hospital bag list banao 🏥` },
    32: { title: '🥥 Week 32 – Almost Ready!', body: 'Breathing exercises shuru karo 🧘' },
    36: { title: '🍈 Week 36 – Sirf 4 Hafte!', body: `Hospital bag pack kiya ${n}? 💪` },
    40: { title: '🍉 Week 40 – Due Date!', body: `${n}, aap itni brave ho! Doctor ke saath connected raho 💕` },
  };
  return map[week] || { title: `🤰 Week ${week}!`, body: 'Tracker mein naya update dekho 💗' };
}

function childContent(months, childName) {
  const n = childName || 'Baby';
  const map = {
    1:  { title: `🎉 ${n} Ka Pehla Mahina!`, body: 'Doctor routine checkup schedule karein 👶' },
    2:  { title: `😊 2 Maheene – Pehli Muskaan!`, body: 'Camera ready rakho! 📸' },
    4:  { title: `🎵 ${n} – 4 Maheene!`, body: `${n} ab awaazein recognise karta hai 🎵` },
    6:  { title: `🥣 6 Maheene – Solid Foods!`, body: 'Rice cereal ya banana try karo! 🍌' },
    9:  { title: `🚶 ${n} – 9 Maheene!`, body: 'Crawling shuru? Standing ka wait karo! 🚀' },
    12: { title: `🎂 Happy Birthday ${n}!`, body: 'Pehla saal! Pehle kadam ka wait karo 🎉' },
    15: { title: `💬 ${n} – 15 Maheene!`, body: 'Vocabulary badhao – zyada baat karo 📢' },
    18: { title: `🗣️ 18 Maheene – Words!`, body: `${n} ab 10-20 words bol sakta hai 🗣️` },
    24: { title: `🎒 ${n} – 2 Saal!`, body: 'Preschool ki taiyaari shuru karo 🌈' },
    36: { title: `🎨 ${n} – 3 Saal!`, body: 'Independence aur curiosity badh rahi hai 🌟' },
    48: { title: `📖 ${n} – 4 Saal!`, body: 'Reading readiness check karo 📚' },
    60: { title: `🏫 ${n} – 5 Saal!`, body: 'School readiness check karo 🎒' },
  };
  return map[months] || {
    title: `👶 ${n} – ${months < 24 ? `${months} Maheene` : `${Math.floor(months/12)} Saal`}!`,
    body: 'Growth chart update karo aur doctor se milein 💕',
  };
}

function vaccinationContent(vaccineName, type) {
  const map = {
    '7d':     { title: `💉 ${vaccineName} – 7 Din Mein!`, body: `Nearest center book karein 🏥` },
    '1d':     { title: `⚠️ ${vaccineName} – Kal Due!`, body: `Center confirm karo 📍` },
    'today':  { title: `🔴 ${vaccineName} – Aaj Due!`, body: `${vaccineName} aaj due hai! Center pe jaayein 🏥` },
    'overdue':{ title: `❗ ${vaccineName} – Overdue!`, body: `Aaj hi schedule karein ⚠️` },
  };
  return map[type] || { title: `💉 ${vaccineName} Reminder`, body: 'Vaccine schedule karo!' };
}

function doctorContent(doctorName, type) {
  const map = {
    '48h':   { title: '📅 Kal Consultation Hai!', body: `Dr. ${doctorName} ke saath kal appointment. Questions tayaar karo 📋` },
    '24h':   { title: '⏰ Kal Doctor Appointment!', body: `Dr. ${doctorName} – kal appointment. Symptom list ready? 💙` },
    '15min': { title: '🚀 15 Min Mein Consult!', body: `Dr. ${doctorName} ka wait kar rahe hain! Join karo 👩‍⚕️` },
  };
  return map[type] || { title: '👩‍⚕️ Doctor Reminder', body: `Dr. ${doctorName} appointment. 💙` };
}

function nutritionTips() {
  return [
    { title: 'Iron-Rich Khana Aaj!', body: 'Palak dal chawal banao – iron ke liye best combo 💚' },
    { title: 'Calcium Time!', body: 'Doodh, dahi, paneer – baby ki bones ke liye zaruri 🥛' },
    { title: 'Folate Foods!', body: 'Leafy greens, lentils – neural tube development ke liye 🥬' },
    { title: 'Hydration Alert!', body: 'Roz 8-10 glass pani pio. Coconut water bhi acha hai 💧' },
    { title: 'Protein Power!', body: 'Dal, eggs, paneer – aaj protein zarur lo 🥚' },
    { title: 'Omega-3 Day!', body: 'Akhrot aur flaxseeds – baby ke brain growth ke liye 🧠' },
    { title: 'Vitamin C Boost!', body: 'Amla, orange, guava – immunity strong karo! 🍊' },
  ];
}
