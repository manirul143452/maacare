module.exports = async function(req) {
  // 1. Setup CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
  };

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    // 2. Parse User Input Profile Details
    let bodyText = await req.text();
    let body = {};
    if (bodyText) {
      body = JSON.parse(bodyText);
    }
    
    if (!body.profileType) {
      return new Response(JSON.stringify({ error: 'Profile Type is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // 3. SECURELY read the XAI API key deployed via Insforge environment variables
    const apiKey = typeof process !== 'undefined' && process.env.XAI_API_KEY 
        ? process.env.XAI_API_KEY 
        : Deno.env.get('XAI_API_KEY');

    if (!apiKey) {
       return new Response(JSON.stringify({ error: 'XAI_API_KEY is not configured in the backend.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Prepare prompt
    const systemPrompt = `You are an expert Clinical Nutritionist for 'MaaCare', a platform focused on maternal, child, and family health. 
You are tasked with generating a highly personalized, scientifically accurate, and culturally appropriate (prioritizing Assam/North-East Indian ingredients if requested) nutrition plan.
You must return ONLY a JSON response matching this schema exactly, and nothing else. No markdown wrappers.

{
  "profile_summary": "Short 1-line summary of the profile & goals",
  "calculated_needs": { "calories": number, "protein": "string", "key_nutrient": "string" },
  "daily_plan": {
    "morning_wake_up": "string",
    "breakfast": "string",
    "mid_morning": "string",
    "lunch": "string",
    "evening_snack": "string",
    "dinner": "string",
    "bedtime": "string"
  },
  "shopping_list": ["item1", "item2"],
  "tips": "string"
}`;

    const userPrompt = `Please generate a nutrition plan based on the following profile:\n${JSON.stringify(body, null, 2)}`;

    // 4. Connect to Grok API
    const xaiUrl = 'https://api.x.ai/v1/chat/completions';
    
    const aiResponse = await fetch(xaiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify({
        model: 'grok-4-latest', 
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ],
        temperature: 0.3, // Lower temperature for more structured, consistent JSON
        response_format: { type: "json_object" }
      })
    });

    if (!aiResponse.ok) {
       const textError = await aiResponse.text();
       return new Response(JSON.stringify({ error: `XAI API error: ${aiResponse.status}`, details: textError }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const aiData = await aiResponse.json();
    let planJson = {};
    try {
        planJson = JSON.parse(aiData.choices[0].message.content);
    } catch(e) {
        planJson = { error: "AI failed to return valid JSON", raw: aiData.choices[0].message.content };
    }

    // 5. Send secure cleaned data back to App
    return new Response(JSON.stringify({ data: planJson }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
};
