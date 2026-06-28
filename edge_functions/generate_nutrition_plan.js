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

    // 3. SECURELY read the Google AI API key
    const apiKey = 'AIzaSyBelxMKHhhdeOaO22DzPCPrGD1XKOEiTpc';

    if (!apiKey) {
       return new Response(JSON.stringify({ error: 'GEMINI_API_KEY is not configured in the backend.' }), {
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

    // 4. Connect to Gemini API
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`;
    
    const aiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': apiKey
      },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: systemPrompt }]
        },
        contents: [
          { role: 'user', parts: [{ text: userPrompt }] }
        ],
        generationConfig: {
          temperature: 0.3,
          responseMimeType: "application/json"
        }
      })
    });

    if (!aiResponse.ok) {
       const textError = await aiResponse.text();
       return new Response(JSON.stringify({ error: `Gemini API error: ${aiResponse.status}`, details: textError }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const geminiData = await aiResponse.json();
    let planJson = {};
    try {
        const responseText = geminiData.candidates[0].content.parts[0].text;
        planJson = JSON.parse(responseText);
    } catch(e) {
        planJson = { error: "AI failed to return valid JSON", raw: geminiData.candidates && geminiData.candidates[0] ? geminiData.candidates[0].content : geminiData };
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
