// Custom Multi-Role Signup Edge Function
// Handles creating the user account and linking roles/profiles

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

  // \u26a0\ufe0f  LEGACY edge function (InsForge format) \u2014 main logic is now in Railway /functions/auth_signup
  // All env vars must be set \u2014 no hardcoded fallbacks allowed
  const INSFORGE_URL = getEnv('INSFORGE_URL');
  const INSFORGE_SERVICE_KEY = getEnv('INSFORGE_SERVICE_KEY');
  const INSFORGE_ANON_KEY = getEnv('ANON_KEY');

  if (!INSFORGE_URL || !INSFORGE_SERVICE_KEY) {
    return new Response(JSON.stringify({ error: 'Server misconfiguration: environment variables not set' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }


  let body;
  try {
    body = await req.json();
  } catch (_) {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const {
    email,
    password,
    name,
    user_role = '',
    medical_registration_no,
    specialization,
    hospital_affiliation
  } = body;

  if (!email || !password) {
    return new Response(JSON.stringify({ error: 'Email and password are required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    // 1. Call InsForge Auth User Creation Endpoint
    console.log(`Creating auth user account for: ${email}`);
    const authUrl = `${INSFORGE_URL}/api/auth/users`;
    const authResponse = await fetch(authUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${INSFORGE_ANON_KEY}`
      },
      body: JSON.stringify({
        email: email.trim(),
        password: password.trim(),
        name: name ? name.trim() : undefined
      })
    });

    const result = await authResponse.json();

    if (!authResponse.ok || result.error) {
      const errorMsg = result.error ? (result.error.message || result.error) : 'Failed to register auth user';
      console.error(`Auth creation failed: ${errorMsg}`);
      return new Response(JSON.stringify({ error: errorMsg }), {
        status: authResponse.status || 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const user = result.data?.user;
    if (!user || !user.id) {
      return new Response(JSON.stringify({ error: 'User creation succeeded but no ID returned' }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const userId = user.id;
    console.log(`Auth user created successfully. User ID: ${userId}. Linking role: ${user_role}`);

    // 2. Insert/Update public.users with the chosen user_role
    await dbQuery(INSFORGE_URL, INSFORGE_SERVICE_KEY, `
      INSERT INTO public.users (id, name, user_role, points, streak, language)
      VALUES ($1, $2, $3, 0, 0, 'en')
      ON CONFLICT (id) DO UPDATE SET user_role = EXCLUDED.user_role, name = EXCLUDED.name;
    `, [userId, name ? name.trim() : '', user_role]);

    // 3. Conditional initialization based on role
    if (user_role === 'doctor') {
      console.log(`Saving doctor profile details for user: ${userId}`);
      await dbQuery(INSFORGE_URL, INSFORGE_SERVICE_KEY, `
        INSERT INTO public.doctor_profiles (user_id, medical_registration_no, specialization, hospital_affiliation, is_verified)
        VALUES ($1, $2, $3, $4, false)
        ON CONFLICT (user_id) DO UPDATE SET
          medical_registration_no = EXCLUDED.medical_registration_no,
          specialization = EXCLUDED.specialization,
          hospital_affiliation = EXCLUDED.hospital_affiliation;
      `, [
        userId,
        medical_registration_no ? medical_registration_no.trim() : '',
        specialization ? specialization.trim() : '',
        hospital_affiliation ? hospital_affiliation.trim() : ''
      ]);
    } else {
      console.log(`Initializing empty symptoms check for: ${userId}`);
      await dbQuery(INSFORGE_URL, INSFORGE_SERVICE_KEY, `
        INSERT INTO public.symptoms (user_id, symptoms, risk_level)
        VALUES ($1, '[]'::jsonb, 'low');
      `, [userId]);
    }

    return new Response(JSON.stringify(result), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (err) {
    console.error('Sign-up handler exception:', err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
};

// ── Database Query Helper ────────────────────────────────────
async function dbQuery(baseUrl, apiKey, sql, params = []) {
  const res = await fetch(`${baseUrl}/api/database/query`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'apikey': apiKey },
    body: JSON.stringify({ sql, params }),
  });
  const json = await res.json();
  if (json.error) {
    throw new Error(`Database error: ${json.error.message || json.error}`);
  }
  return json.data || [];
}
