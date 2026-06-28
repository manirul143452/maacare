// update_user_role – MaaCare Edge Function
// Updates the user_role in the users table after Google OAuth sign-in.
// Also creates a doctor_profiles row if the role is 'doctor'.

module.exports = async function (req) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, PUT, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, apikey, Authorization',
  };

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== 'POST' && req.method !== 'PUT') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const getEnv = (key) =>
    typeof process !== 'undefined' && process.env[key]
      ? process.env[key]
      : Deno.env.get(key);

  const INSFORGE_URL =
    getEnv('INSFORGE_URL') || 'https://96if48kf.ap-southeast.insforge.app';
  const INSFORGE_SERVICE_KEY =
    getEnv('INSFORGE_SERVICE_KEY') ||
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3OC0xMjM0LTU2NzgtOTBhYi1jZGVmMTIzNDU2NzgiLCJlbWFpbCI6ImFub25AaW5zZm9yZ2UuY29tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMDQwOTF9.VaMaOGNQNj8XlUFSiBCxaOmxjTcfxc6Bxkb6LDLY0J0';

  // ── 1. Validate Authorization header (user's access token) ──────────────────
  const authHeader = req.headers.get('Authorization') || '';
  const userToken = authHeader.replace('Bearer ', '').trim();
  if (!userToken) {
    return new Response(JSON.stringify({ error: 'Missing Authorization token' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ── 2. Identify the caller via /api/auth/sessions/current ──────────────────
  let userId;
  try {
    const sessionRes = await fetch(`${INSFORGE_URL}/api/auth/sessions/current`, {
      headers: {
        Authorization: `Bearer ${userToken}`,
        apikey: INSFORGE_SERVICE_KEY,
      },
    });
    if (!sessionRes.ok) {
      return new Response(JSON.stringify({ error: 'Invalid or expired token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    const sessionData = await sessionRes.json();
    userId = sessionData?.user?.id || sessionData?.id;
    if (!userId) throw new Error('No user id in session response');
  } catch (e) {
    return new Response(JSON.stringify({ error: `Session lookup failed: ${e.message}` }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ── 3. Parse body ──────────────────────────────────────────────────────────
  let body;
  try {
    body = await req.json();
  } catch (_) {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const {
    user_role,
    name,
    medical_registration_no,
    specialization,
    hospital_affiliation,
    trimester,
    age_bracket,
  } = body;

  const validRoles = ['mother', 'unmarried_girl', 'doctor'];
  if (!user_role || !validRoles.includes(user_role)) {
    return new Response(
      JSON.stringify({ error: `Invalid user_role. Must be one of: ${validRoles.join(', ')}` }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  const dbHeaders = {
    'Content-Type': 'application/json',
    apikey: INSFORGE_SERVICE_KEY,
    Authorization: `Bearer ${INSFORGE_SERVICE_KEY}`,
    Prefer: 'return=representation',
  };

  // ── 4. Check if user row exists already ────────────────────────────────────
  const checkRes = await fetch(
    `${INSFORGE_URL}/api/database/records/users?id=eq.${userId}&select=id,user_role`,
    { headers: dbHeaders }
  );
  const existingUsers = await checkRes.json();

  // Compute due_date if mother is selected
  let computedDueDate = null;
  if (user_role === 'mother' && trimester) {
    const trimesterNum = parseInt(trimester);
    const days = trimesterNum === 1 ? 210 : trimesterNum === 2 ? 126 : 42;
    const targetDate = new Date();
    targetDate.setDate(targetDate.getDate() + days);
    computedDueDate = targetDate.toISOString().split('T')[0];
  }

  if (!Array.isArray(existingUsers) || existingUsers.length === 0) {
    // User row missing – create it (can happen for Google OAuth first-timers)
    const insertBody = {
      id: userId,
      user_role,
      points: 0,
      streak: 0,
      language: 'hi',
      trimester: trimester ? parseInt(trimester) : null,
      age_bracket: age_bracket || null,
      due_date: computedDueDate,
    };
    if (name) insertBody.name = name;

    const insertRes = await fetch(`${INSFORGE_URL}/api/database/records/users`, {
      method: 'POST',
      headers: dbHeaders,
      body: JSON.stringify([insertBody]),
    });
    if (!insertRes.ok) {
      const errText = await insertRes.text();
      return new Response(JSON.stringify({ error: `Failed to create user row: ${errText}` }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  } else {
    // Update existing user row
    const patchBody = {
      user_role,
      trimester: trimester ? parseInt(trimester) : null,
      age_bracket: age_bracket || null,
      due_date: computedDueDate,
    };
    if (name) patchBody.name = name;

    const patchRes = await fetch(
      `${INSFORGE_URL}/api/database/records/users?id=eq.${userId}`,
      {
        method: 'PATCH',
        headers: dbHeaders,
        body: JSON.stringify(patchBody),
      }
    );
    if (!patchRes.ok) {
      const errText = await patchRes.text();
      return new Response(JSON.stringify({ error: `Failed to update user_role: ${errText}` }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  }

  // ── 5. If doctor, upsert doctor_profiles ──────────────────────────────────
  if (user_role === 'doctor') {
    // Check if doctor_profile already exists
    const dpCheckRes = await fetch(
      `${INSFORGE_URL}/api/database/records/doctor_profiles?user_id=eq.${userId}&select=user_id`,
      { headers: dbHeaders }
    );
    const existingDp = await dpCheckRes.json();

    const dpBody = {
      user_id: userId,
      medical_registration_no: medical_registration_no || '',
      specialization: specialization || '',
      hospital_affiliation: hospital_affiliation || '',
      is_verified: false,
    };

    if (!Array.isArray(existingDp) || existingDp.length === 0) {
      // Insert
      await fetch(`${INSFORGE_URL}/api/database/records/doctor_profiles`, {
        method: 'POST',
        headers: dbHeaders,
        body: JSON.stringify([dpBody]),
      });
    } else {
      // Update
      await fetch(
        `${INSFORGE_URL}/api/database/records/doctor_profiles?user_id=eq.${userId}`,
        {
          method: 'PATCH',
          headers: dbHeaders,
          body: JSON.stringify({
            medical_registration_no: medical_registration_no || '',
            specialization: specialization || '',
            hospital_affiliation: hospital_affiliation || '',
          }),
        }
      );
    }
  }

  return new Response(
    JSON.stringify({
      success: true,
      user_role,
      message: 'User role updated successfully',
    }),
    { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
};
