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
    // 2. Parse User Input
    let bodyText = await req.text();
    let body = {};
    if (bodyText) {
      body = JSON.parse(bodyText);
    }
    
    const messages = body.messages || [];
    if (!messages || messages.length === 0) {
      return new Response(JSON.stringify({ error: 'Messages are required' }), {
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

    // 4. Connect to Grok API correctly
    const xaiUrl = 'https://api.x.ai/v1/chat/completions';
    
    const aiResponse = await fetch(xaiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify({
        model: 'grok-4-latest', // Fallback to a stable standard grok model if required or let them customize
        messages: [
          {
             role: 'system',
             content: 'You are MaaCare AI Companion. A dedicated expert in motherhood, pediatrics, and pregnancy. Keep responses kind, supportive, medically accurate but emphasize talking to a doctor.'
          },
          ...messages
        ],
        temperature: 0.7
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

    // 5. Send secure cleaned data back to App
    return new Response(JSON.stringify({ data: aiData }), {
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
