// ============================================================
//  InsForge Edge Function: send-notification
//  Unified OneSignal push notification sender
//
//  POST /functions/send-notification
//  Body: { player_ids[], title, body, type, route, data,
//          image_url, action1_label, action1_route,
//          user_ids[], segment, scheduled_at }
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

  // ── Read secrets ──────────────────────────────────────────
  const getEnv = (key) =>
    typeof process !== 'undefined' && process.env[key]
      ? process.env[key]
      : Deno.env.get(key);

  const ONESIGNAL_APP_ID   = getEnv('ONESIGNAL_APP_ID');
  const ONESIGNAL_API_KEY  = getEnv('ONESIGNAL_API_KEY');
  const INSFORGE_URL       = getEnv('INSFORGE_URL') || 'https://96if48kf.ap-southeast.insforge.app';
  const INSFORGE_SERVICE_KEY = getEnv('INSFORGE_SERVICE_KEY') || getEnv('ANON_KEY');

  let body;
  try {
    body = await req.json();
  } catch (_) {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const {
    player_ids,
    title,
    body: notifBody,
    type = 'general',
    route,
    data = {},
    image_url,
    action1_label,
    action1_route,
    user_ids,
    segment,
    scheduled_at,
  } = body;

  if (!title || !notifBody) {
    return new Response(JSON.stringify({ error: 'Missing required fields: title, body' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ── Resolve player IDs from user_ids if needed ────────────
  let resolvedPlayerIds = player_ids || [];
  if (user_ids && user_ids.length > 0 && resolvedPlayerIds.length === 0) {
    try {
      resolvedPlayerIds = await getPlayerIdsByUserIds(user_ids, INSFORGE_URL, INSFORGE_SERVICE_KEY);
    } catch (e) {
      console.error('Error fetching player IDs:', e.message);
    }
  }

  if (!segment && resolvedPlayerIds.length === 0) {
    return new Response(
      JSON.stringify({ error: 'No recipients: provide player_ids, user_ids, or segment' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  if (!ONESIGNAL_APP_ID || !ONESIGNAL_API_KEY) {
    // Fallback: log and return success if OneSignal not configured yet
    console.warn('OneSignal not configured – notification skipped:', title);
    return new Response(
      JSON.stringify({ success: true, warning: 'OneSignal not configured', title, type }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // ── Build OneSignal payload ───────────────────────────────
  const osPayload = {
    app_id: ONESIGNAL_APP_ID,
    headings: { en: title },
    contents: { en: notifBody },
    data: {
      type,
      route: route || getDefaultRoute(type),
      data,
      action1_label,
      action1_route,
    },
    ios_badgeType: 'Increase',
    ios_badgeCount: 1,
    android_accent_color: 'FFFF69B4',
  };

  if (resolvedPlayerIds.length > 0) {
    osPayload.include_subscription_ids = resolvedPlayerIds;
  } else if (segment) {
    osPayload.included_segments = [segment];
  }

  if (image_url) {
    osPayload.big_picture = image_url;
    osPayload.ios_attachments = { id1: image_url };
  }

  if (scheduled_at) {
    osPayload.send_after = scheduled_at;
  }

  // ── Send via OneSignal REST API ───────────────────────────
  try {
    const osRes = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Key ${ONESIGNAL_API_KEY}`,
      },
      body: JSON.stringify(osPayload),
    });

    const osData = await osRes.json();

    if (!osRes.ok) {
      console.error('OneSignal error:', JSON.stringify(osData));
      return new Response(
        JSON.stringify({ error: 'OneSignal error', details: osData }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ── Log to notification_history ───────────────────────
    if (user_ids && user_ids.length > 0) {
      await logHistory(user_ids, type, title, INSFORGE_URL, INSFORGE_SERVICE_KEY);
    }

    console.log(`✅ Sent | type:${type} | recipients:${resolvedPlayerIds.length || segment} | os_id:${osData.id}`);

    return new Response(
      JSON.stringify({ success: true, onesignal_id: osData.id, recipients: osData.recipients }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('Unexpected error:', err.message);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
};

// ── Helpers ──────────────────────────────────────────────────

function getDefaultRoute(type) {
  const routes = {
    pregnancy_milestone: '/tracker',
    child_growth: '/child-growth',
    vaccination: '/vaccinations',
    doctor_consult: '/consult',
    symptom_check: '/symptoms',
    health_insights: '/health-insights',
    safety_alert: '/symptoms',
    nutrition: '/nutrition',
    self_care: '/self-care',
    tracker_sync: '/tracker',
    community: '/community',
    friend_request: '/community',
    health_news: '/nutrition',
    general: '/home',
  };
  return routes[type] || '/home';
}

async function getPlayerIdsByUserIds(userIds, baseUrl, apiKey) {
  const res = await fetch(`${baseUrl}/api/database/query`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'apikey': apiKey },
    body: JSON.stringify({
      sql: `SELECT onesignal_player_id FROM public.users
            WHERE id = ANY($1::uuid[]) AND onesignal_player_id IS NOT NULL`,
      params: [userIds],
    }),
  });
  if (!res.ok) throw new Error('Failed to fetch player IDs');
  const json = await res.json();
  return (json.data || []).map((r) => r.onesignal_player_id);
}

async function logHistory(userIds, category, title, baseUrl, apiKey) {
  try {
    const records = userIds.map((uid) => ({
      user_id: uid,
      category,
      title,
      sent_at: new Date().toISOString(),
    }));
    await fetch(`${baseUrl}/api/database/records/notification_history`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'apikey': apiKey },
      body: JSON.stringify(records),
    });
  } catch (e) {
    console.warn('History log failed:', e.message);
  }
}
