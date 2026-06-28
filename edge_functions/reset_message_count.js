// ============================================================
//  reset_message_count – Midnight AI message count reset function
// ============================================================

module.exports = async function(req) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
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
  const INSFORGE_SERVICE_KEY = getEnv('INSFORGE_SERVICE_KEY');

  const dbHeaders = {
    'Content-Type': 'application/json',
    apikey: INSFORGE_SERVICE_KEY,
    Authorization: `Bearer ${INSFORGE_SERVICE_KEY}`
  };

  try {
    // Reset all users' message counts back to 0
    const res = await fetch(`${INSFORGE_URL}/api/database/records/user_subscriptions`, {
      method: 'PATCH',
      headers: dbHeaders,
      body: JSON.stringify({ ai_message_count: 0 })
    });

    if (!res.ok) {
      const errText = await res.text();
      return new Response(JSON.stringify({ error: `DB reset failed: ${errText}` }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({ success: true, message: 'Message counts reset to 0' }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
};
