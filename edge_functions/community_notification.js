// ============================================================
//  InsForge Edge Function: community-notification
//  Community event push notifications
//
//  POST /functions/community-notification
//  Body: { event_type, from_user_id, to_user_id,
//          post_id, post_preview, from_name, from_week,
//          achievement_name }
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

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const getEnv = (key) =>
    typeof process !== 'undefined' && process.env[key]
      ? process.env[key]
      : Deno.env.get(key);

  const INSFORGE_URL = getEnv('INSFORGE_URL') || 'https://96if48kf.ap-southeast.insforge.app';
  const INSFORGE_SERVICE_KEY = getEnv('INSFORGE_SERVICE_KEY') || getEnv('ANON_KEY');
  const SEND_URL = `${INSFORGE_URL}/functions/send-notification`;

  let body;
  try {
    body = await req.json();
  } catch (_) {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const {
    event_type,
    from_user_id,
    to_user_id,
    post_id,
    post_preview,
    achievement_name,
    from_name,
    from_week,
  } = body;

  if (!event_type || !to_user_id) {
    return new Response(
      JSON.stringify({ error: 'Missing required: event_type, to_user_id' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // ── Get recipient push token + prefs ──────────────────────
  let recipient;
  try {
    const rows = await dbQuery(INSFORGE_URL, INSFORGE_SERVICE_KEY, `
      SELECT u.onesignal_player_id, u.name,
             np.preferences
      FROM public.users u
      LEFT JOIN public.notification_preferences np ON np.user_id = u.id
      WHERE u.id = $1 AND u.onesignal_player_id IS NOT NULL
    `, [to_user_id]);

    if (rows.length === 0) {
      return new Response(
        JSON.stringify({ success: false, reason: 'No push token for recipient' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    recipient = rows[0];
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `DB error: ${err.message}` }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  const prefs = recipient.preferences || {};

  // ── Build content by event type ───────────────────────────
  let title, notifBody, categoryKey = 'community', route = '/community';
  let action1_label = 'Dekho';
  const data = { event_type, post_id, from_user_id };

  switch (event_type) {
    case 'friend_request':
      if (prefs.friend_request === false) {
        return ok(corsHeaders, { success: false, reason: 'friend_request disabled' });
      }
      categoryKey = 'friend_request';
      title = '🤝 Friend Request Aaya!';
      notifBody = `${from_name || 'Ek Mama'} (${from_week ? `Week ${from_week}` : 'nayi mama'}) ne connect karna chahti hai! Accept karo?`;
      action1_label = 'Accept Karo ✅';
      data.from_name = from_name;
      data.from_week = from_week;
      break;

    case 'friend_request_accepted':
      if (prefs.friend_request === false) return ok(corsHeaders, { success: false, reason: 'disabled' });
      categoryKey = 'friend_request';
      title = '✅ Friend Request Accept Hua!';
      notifBody = `${from_name || 'Ek Mama'} ab aapki friend hai! Parents Park mein connect karo 💕`;
      action1_label = 'Profile Dekho';
      break;

    case 'post_reply':
      if (prefs.community === false) return ok(corsHeaders, { success: false, reason: 'community disabled' });
      title = '💬 Aapke Post Pe Reply!';
      notifBody = `${from_name || 'Ek Mama'} ne reply kiya: "${(post_preview || '').substring(0, 50)}"`;
      action1_label = 'Reply Dekho';
      break;

    case 'post_like':
      if (prefs.community === false) return ok(corsHeaders, { success: false, reason: 'community disabled' });
      title = '❤️ Aapka Post Like Hua!';
      notifBody = `${from_name || 'Kisi Mama'} ne aapka post like kiya. Community love! 🌸`;
      action1_label = 'Post Dekho';
      break;

    case 'achievement':
      if (prefs.community === false) return ok(corsHeaders, { success: false, reason: 'community disabled' });
      title = '🏆 Achievement Unlock!';
      notifBody = achievement_name
        ? `Badhaaiyan! "${achievement_name}" badge mila! Share karo 🎉`
        : 'Ek naya badge mila hai! Profile mein check karo 🎉';
      action1_label = 'Badge Dekho';
      route = '/profile';
      break;

    case 'new_mama_nearby':
      if (prefs.community === false) return ok(corsHeaders, { success: false, reason: 'community disabled' });
      title = '👥 Nayi Mama Aas-paas!';
      notifBody = `${from_name || 'Ek nayi mama'} aapke area mein join huin! Connect karo 🌸`;
      action1_label = 'Connect Karo';
      break;

    case 'support_group_message':
      if (prefs.community === false) return ok(corsHeaders, { success: false, reason: 'community disabled' });
      title = '💌 Support Group Mein Sandesh!';
      notifBody = `${from_name || 'Ek member'}: "${(post_preview || '').substring(0, 60)}"`;
      action1_label = 'Group Mein Jaao';
      break;

    default:
      title = '💬 MaaCare Community';
      notifBody = 'Parents Park mein kuch naya hai! Dekho 🌸';
  }

  // ── Send via send-notification function ───────────────────
  try {
    const res = await fetch(SEND_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': INSFORGE_SERVICE_KEY,
      },
      body: JSON.stringify({
        player_ids: [recipient.onesignal_player_id],
        user_ids: [to_user_id],
        title,
        body: notifBody,
        type: categoryKey,
        route,
        data,
        action1_label,
      }),
    });

    const result = await res.json();
    console.log(`✅ community-notification | ${event_type} → ${to_user_id}`);

    return new Response(
      JSON.stringify({ success: true, event_type, onesignal_result: result }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('Send error:', err.message);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
};

// ── Helpers ──────────────────────────────────────────────────
async function dbQuery(baseUrl, apiKey, sql, params = []) {
  const res = await fetch(`${baseUrl}/api/database/query`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'apikey': apiKey },
    body: JSON.stringify({ sql, params }),
  });
  const json = await res.json();
  return json.data || [];
}

function ok(corsHeaders, body) {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
