// ============================================================
//  InsForge Edge Function: send_push_notification
//  Firebase Cloud Messaging (FCM) REST API push sender
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

  const FCM_PROJECT_ID = getEnv('FCM_PROJECT_ID');
  const FCM_SERVER_KEY = getEnv('FCM_SERVER_KEY'); // Fallback token

  let body;
  try {
    body = await req.json();
  } catch (_) {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const {
    token, // Target FCM registration token
    title,
    body: notifBody,
    data = {},
  } = body;

  if (!token || !title || !notifBody) {
    return new Response(JSON.stringify({ error: 'Missing required fields: token, title, body' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // If FCM credentials are not configured, simulate success (safe fallback for environments)
  if (!FCM_PROJECT_ID && !FCM_SERVER_KEY) {
    console.warn('FCM credentials not configured. Simulating FCM delivery to token:', token);
    return new Response(JSON.stringify({
      success: true,
      simulated: true,
      message_id: `sim_fcm_${Date.now()}`,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    let response;
    if (FCM_SERVER_KEY) {
      // Legacy REST Endpoint
      response = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `key=${FCM_SERVER_KEY}`,
        },
        body: JSON.stringify({
          to: token,
          notification: {
            title: title,
            body: notifBody,
          },
          data: data,
        }),
      });
    } else {
      // HTTP v1 Protocol
      response = await fetch(`https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${getEnv('FCM_OAUTH_TOKEN') || 'mock_oauth_token'}`,
        },
        body: JSON.stringify({
          message: {
            token: token,
            notification: {
              title: title,
              body: notifBody,
            },
            data: data,
          }
        }),
      });
    }

    const resData = await response.json();
    if (!response.ok) {
      console.error('FCM gateway error:', JSON.stringify(resData));
      return new Response(JSON.stringify({ error: 'FCM gateway error', details: resData }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({
      success: true,
      message_id: resData.message_id || resData.name,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (e) {
    console.error('FCM sender failed:', e.message);
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
};
