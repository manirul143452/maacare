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
    const systemPrompt = body.system_prompt || 'You are MaaCare AI Companion. A dedicated expert in motherhood, pediatrics, and pregnancy. Keep responses kind, supportive, medically accurate but emphasize talking to a doctor.';
    if (!messages || messages.length === 0) {
      return new Response(JSON.stringify({ error: 'Messages are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // -- Subscription & Paywall Check --
    const authHeader = req.headers.get('Authorization') || '';
    const userToken = authHeader.replace('Bearer ', '').trim();
    
    let userId = null;
    let isPremium = false;
    let messageCount = 0;

    const getEnv = (key) => {
      if (typeof process !== 'undefined' && process.env && process.env[key]) {
        return process.env[key];
      }
      if (typeof Deno !== 'undefined' && Deno.env && Deno.env.get) {
        return Deno.env.get(key);
      }
      return null;
    };

    const INSFORGE_URL = getEnv('INSFORGE_URL') || 'https://96if48kf.ap-southeast.insforge.app';
    const INSFORGE_SERVICE_KEY = getEnv('INSFORGE_SERVICE_KEY');

    const dbHeaders = {
      'Content-Type': 'application/json',
      apikey: INSFORGE_SERVICE_KEY,
      Authorization: `Bearer ${INSFORGE_SERVICE_KEY}`
    };

    if (userToken && userToken !== INSFORGE_SERVICE_KEY) {
      try {
        const sessionRes = await fetch(`${INSFORGE_URL}/api/auth/sessions/current`, {
          headers: {
            Authorization: `Bearer ${userToken}`,
            apikey: INSFORGE_SERVICE_KEY,
          },
        });
        if (sessionRes.ok) {
          const sessionData = await sessionRes.json();
          userId = sessionData?.user?.id || sessionData?.id;
        }
      } catch (e) {
        console.error('Session lookup failed in ai_chat:', e);
      }
    }

    if (userId) {
      try {
        const subRes = await fetch(`${INSFORGE_URL}/api/database/records/user_subscriptions?user_id=eq.${userId}`, {
          headers: dbHeaders
        });
        if (subRes.ok) {
          const subs = await subRes.json();
          if (subs && subs.length > 0) {
            isPremium = subs[0].is_premium === true;
            messageCount = subs[0].free_ai_chat_count || 0;
          } else {
            // Create subscription row if none exists
            const createRes = await fetch(`${INSFORGE_URL}/api/database/records/user_subscriptions`, {
              method: 'POST',
              headers: dbHeaders,
              body: JSON.stringify({
                user_id: userId,
                is_premium: false,
                free_ai_chat_count: 0
              })
            });
            if (createRes.ok) {
              const newSubs = await createRes.json();
              const newSub = Array.isArray(newSubs) ? newSubs[0] : newSubs;
              if (newSub) {
                isPremium = newSub.is_premium === true;
                messageCount = newSub.free_ai_chat_count || 0;
              }
            }
          }
        }
      } catch (e) {
        console.error('Subscription table check failed:', e);
      }
    }

    // Intercept: if (!is_premium && free_ai_chat_count >= 5)
    if (userId && !isPremium && messageCount >= 5) {
      return new Response(JSON.stringify({
        status: "blocked",
        message: "Unlock MaaCare Elite Pass",
        paywall_limit: true,
        data: {
          status: "blocked",
          message: "Unlock MaaCare Elite Pass",
          paywall_limit: true
        }
      }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const incrementCount = async () => {
      if (userId && !isPremium) {
        try {
          await fetch(`${INSFORGE_URL}/api/database/records/user_subscriptions?user_id=eq.${userId}`, {
            method: 'PATCH',
            headers: dbHeaders,
            body: JSON.stringify({
              free_ai_chat_count: messageCount + 1
            })
          });
        } catch (e) {
          console.error('Failed to increment message count:', e);
        }
      }
    };

    // ── Emergency Triage Check (Short-Circuit) ──────────────────────
    let isEmergency = false;
    let triggerSymptom = "";

    const ALL_SYMPTOMS = [
      "morning_sickness_nausea", "heartburn_acidity", "mild_fatigue_tiredness", "frequent_urination", "swollen_ankles_feet", "back_pain",
      "severe_swelling", "blurry_vision_headache", "persistent_vomiting", "high_blood_sugar_thirst", "mild_fever",
      "vaginal_bleeding_spotting", "severe_abdominal_pelvic_pain", "decreased_baby_movement", "fluid_leaking_water_breaking", "chills_high_fever",
      "severe_period_cramps", "normal_white_discharge", "period_fatigue_mood_swings",
      "irregular_delayed_periods", "thick_smelly_white_discharge", "heavy_bleeding_7_days",
      "extreme_pain_fainting_vomiting", "excessive_bleeding_hourly", "missed_period_one_sided_pain"
    ];

    const PREGNANCY_YELLOW_RED = [
      "severe_swelling", "blurry_vision_headache", "persistent_vomiting", "high_blood_sugar_thirst", "mild_fever",
      "vaginal_bleeding_spotting", "severe_abdominal_pelvic_pain", "decreased_baby_movement", "fluid_leaking_water_breaking", "chills_high_fever"
    ];

    const MENSTRUAL_RED = [
      "extreme_pain_fainting_vomiting", "excessive_bleeding_hourly", "missed_period_one_sided_pain"
    ];

    const MENSTRUAL_GREEN_YELLOW = [
      "severe_period_cramps", "normal_white_discharge", "period_fatigue_mood_swings",
      "irregular_delayed_periods", "thick_smelly_white_discharge", "heavy_bleeding_7_days"
    ];

    const MENSTRUAL_CACHE = {
      "severe_period_cramps": "For severe cramps (periods ka tez dard), try these safe home care methods:\n1. Apply a warm heating pad or hot water bottle to your lower abdomen.\n2. Stay well hydrated by drinking warm water or herbal teas (ginger/chamomile).\n3. Try light stretches or a gentle walk to improve blood flow.\n4. Avoid caffeine, cold drinks, and high-sodium foods which can worsen bloating.\nIf the pain is unbearable or causes fainting, seek medical care immediately.",
      "normal_white_discharge": "Normal white discharge (saaf pani aana - bina badboo/khujli ke) is standard and healthy:\n1. It is a natural process for your vagina to clean itself and prevent infections.\n2. Keep the area clean by washing with plain water; avoid scented soaps or vaginal douches.\n3. Wear breathable cotton underwear and change daily.\nIf the discharge becomes thick, clumpy, smelly, or causes itching, consult a doctor.",
      "period_fatigue_mood_swings": "Period fatigue and mood swings (thakan aur chidchidapan) are common hormonal symptoms:\n1. Prioritize resting and aim for 7-8 hours of sleep.\n2. Eat nutrient-rich and iron-rich foods (green leafy veggies, nuts, pulses) to maintain energy levels.\n3. Try gentle exercises like yoga, deep breathing, or meditation to ease irritability.\n4. Stay hydrated and eat small, frequent meals to keep blood sugar stable.",
      "irregular_delayed_periods": "Irregular or delayed periods (periods time par na aana) can happen due to various factors:\n1. Stress, sudden weight changes, poor diet, sleep deprivation, or hormonal imbalances (like PCOS/PCOD) are common causes.\n2. Keep tracking your cycle dates for 2-3 months on a calendar or app.\n3. Maintain a healthy lifestyle with balanced nutrition, daily movement, and stress management.\nConsult a gynecologist if you miss multiple cycles in a row or if your periods are highly unpredictable.",
      "thick_smelly_white_discharge": "Thick, smelly discharge with itching (gaadha, badboodar pani aur khujli) is not normal:\n1. This is a common sign of a vaginal infection (like a yeast or bacterial infection).\n2. Avoid using vaginal washes, douches, or self-medicating with over-the-counter creams as they can worsen the infection.\n3. Wear clean, dry cotton underwear and keep the area dry.\n4. Please consult a gynecologist for a proper examination and prescription of antifungal or antibacterial treatment.",
      "heavy_bleeding_7_days": "Heavy bleeding lasting more than 7 days (7 din se zyada bleeding) needs medical attention:\n1. Ensure you rest and avoid strenuous physical activity.\n2. Eat iron-rich foods (spinach, beetroot, pomegranate) to help prevent anemia (khoon ki kami).\n3. Keep a track of how many pads you change daily.\n4. We highly recommend booking a consultation with a gynecologist to check your blood levels and find the cause."
    };

    // 1. Check symptoms list if provided (list of string IDs)
    const symptomsList = body.symptoms || [];
    if (symptomsList.length > 0) {
      for (const sym of symptomsList) {
        if (PREGNANCY_YELLOW_RED.includes(sym) || MENSTRUAL_RED.includes(sym)) {
          isEmergency = true;
          triggerSymptom = sym;
          break;
        }
      }
    }

    // 2. Check symptom vector if provided (binary matrix vector)
    const symptomVector = body.symptom_vector || [];
    if (!isEmergency && symptomVector.length > 0) {
      for (let i = 0; i < Math.min(symptomVector.length, ALL_SYMPTOMS.length); i++) {
        if (symptomVector[i] === 1 || symptomVector[i] === true) {
          const symName = ALL_SYMPTOMS[i];
          if (PREGNANCY_YELLOW_RED.includes(symName) || MENSTRUAL_RED.includes(symName)) {
            isEmergency = true;
            triggerSymptom = symName;
            break;
          }
        }
      }
    }

    // 3. Scan message text for warning/emergency keywords (support Hinglish and English)
    if (!isEmergency) {
      const textToScan = messages.map(m => (m.content || "").toLowerCase()).join(" ");
      const keywords = {
        "vaginal_bleeding_spotting": ["bleeding", "spotting", "khoon", "dhabbe", "blood coming", "bleeding pregnancy"],
        "severe_abdominal_pelvic_pain": ["abdominal pain", "pelvic pain", "pet dard", "kammar dard", "severe pain", "unending pain"],
        "decreased_baby_movement": ["no movement", "less movement", "decreased movement", "halchal kam", "baby not moving", "fetal movement"],
        "fluid_leaking_water_breaking": ["water breaking", "leaking fluid", "water leaking", "pani nikalna", "gush of fluid"],
        "chills_high_fever": ["high fever", "fever over 101", "chills", "kapkapi", "tez bukhar"],
        "severe_swelling": ["severe swelling", "face swelling", "swelling in face", "achanak soojan", "swelling hand", "swelling eye"],
        "blurry_vision_headache": ["blurry vision", "flashing lights", "severe headache", "dhundhlapan", "roshni chamakna", "tez sir dard", "lagaatar sir dard"],
        "persistent_vomiting": ["persistent vomiting", "lagaatar ultiyan", "cannot keep fluid", "pani bhi na pachtana", "severe vomiting"],
        "high_blood_sugar_thirst": ["blood sugar", "extreme thirst", "pyaas lagna", "high sugar"],
        "mild_fever": ["mild fever", "halka bukhar"],
        
        // Menstrual emergency (Red Zone)
        "extreme_pain_fainting_vomiting": ["extreme pain", "pain fainting", "pain vomiting", "chakkar", "ulti aaye", "chakkar ya ulti", "vomiting pain"],
        "excessive_bleeding_hourly": ["changing 1 pad", "pad every hour", "excessive bleeding", "bahut zyada bleeding", "heavy period flow"],
        "missed_period_one_sided_pain": ["missed period", "period miss", "one sided pain", "one-sided pain", "ek taraf tez dard", "ek taraf dard"]
      };

      for (const [symptom, words] of Object.entries(keywords)) {
        for (const word of words) {
          if (textToScan.includes(word)) {
            isEmergency = true;
            triggerSymptom = symptom;
            break;
          }
        }
        if (isEmergency) break;
      }
    }

    if (isEmergency) {
      console.log(`🚨 Emergency short-circuit triggered by symptom: ${triggerSymptom}`);
      await incrementCount();
      return new Response(JSON.stringify({
        triage_status: "emergency",
        trigger_symptom: triggerSymptom,
        message: "Critical/High-Risk Symptoms Detected. Please contact your doctor or visit the nearest emergency room immediately. Emergency Services: 108, Ambulance: 102",
        data: {
          triage_status: "emergency",
          trigger_symptom: triggerSymptom,
          message: "Critical/High-Risk Symptoms Detected. Please contact your doctor or visit the nearest emergency room immediately. Emergency Services: 108, Ambulance: 102"
        }
      }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // ── Local Cache Checking for Green/Yellow Menstrual Symptoms ───────────
    let cachedResponse = "";
    let matchedCachedSymptoms = [];

    // Check symptoms array
    for (const sym of symptomsList) {
      if (MENSTRUAL_CACHE[sym]) {
        matchedCachedSymptoms.push(sym);
        cachedResponse += `${MENSTRUAL_CACHE[sym]}\n\n`;
      }
    }

    // Check symptom vector
    if (symptomVector.length > 0) {
      for (let i = 0; i < Math.min(symptomVector.length, ALL_SYMPTOMS.length); i++) {
        if (symptomVector[i] === 1 || symptomVector[i] === true) {
          const symName = ALL_SYMPTOMS[i];
          if (MENSTRUAL_CACHE[symName] && !matchedCachedSymptoms.includes(symName)) {
            matchedCachedSymptoms.push(symName);
            cachedResponse += `${MENSTRUAL_CACHE[symName]}\n\n`;
          }
        }
      }
    }

    // Scan messages content for green/yellow keywords to hit cache
    const textToScan = messages.map(m => (m.content || "").toLowerCase()).join(" ");
    const CACHE_KEYWORDS = {
      "severe_period_cramps": ["cramp", "period cramp", "period pain", "lower belly pain", "periods ka tez dard", "periods ka dard", "pet dard"],
      "normal_white_discharge": ["white discharge", "saaf pani", "bina badboo", "discharge normal", "safed pani"],
      "period_fatigue_mood_swings": ["fatigue", "mood swings", "thakan", "chidchidapan", "tiredness", "moody"],
      "irregular_delayed_periods": ["irregular", "delayed", "missed period", "period late", "late period", "time par na aana", "irregular cycle"],
      "thick_smelly_white_discharge": ["smelly discharge", "itching", "khujli", "badboo", "gaadha", "thick white discharge"],
      "heavy_bleeding_7_days": ["heavy bleeding", "7 days bleeding", "bleeding more than 7 days", "long period", "zyada bleeding"]
    };

    for (const [symptom, words] of Object.entries(CACHE_KEYWORDS)) {
      if (!matchedCachedSymptoms.includes(symptom)) {
        for (const word of words) {
          if (textToScan.includes(word)) {
            matchedCachedSymptoms.push(symptom);
            cachedResponse += `${MENSTRUAL_CACHE[symptom]}\n\n`;
            break;
          }
        }
      }
    }

    if (cachedResponse) {
      console.log(`✅ Local Cache HIT for symptoms: ${matchedCachedSymptoms.join(", ")}`);
      await incrementCount();
      return new Response(JSON.stringify({
        data: {
          choices: [
            {
              message: {
                content: cachedResponse.trim()
              }
            }
          ],
          provider: 'local_cache'
        }
      }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // 3. Read API Keys
    const nvidiaKey = getEnv('NVIDIA_API_KEY') || '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';
    const geminiKey = getEnv('GEMINI_API_KEY') || 'AIzaSyBelxMKHhhdeOaO22DzPCPrGD1XKOEiTpc';

    let responseText = '';
    let usedProvider = '';

    // Try Nvidia NIM API first (Fast, Zero-Cost Fallback)
    if (nvidiaKey) {
      try {
        console.log('Routing to Nvidia NIM API...');
        const nvidiaUrl = 'https://integrate.api.nvidia.com/v1/chat/completions';
        
        const nvidiaResponse = await fetch(nvidiaUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${nvidiaKey}`
          },
          body: JSON.stringify({
            model: 'meta/llama-3-8b-instruct',
            messages: [
              {
                role: 'system',
                content: systemPrompt
              },
              ...messages
            ],
            temperature: 0.7,
            max_tokens: 1024
          })
        });

        if (nvidiaResponse.ok) {
          const nvidiaData = await nvidiaResponse.json();
          if (nvidiaData.choices && nvidiaData.choices[0] && nvidiaData.choices[0].message) {
            responseText = nvidiaData.choices[0].message.content;
            usedProvider = 'nvidia';
            console.log('✅ Response from Nvidia NIM API succeeded');
          }
        } else {
          const errText = await nvidiaResponse.text();
          console.warn(`Nvidia API returned non-OK status: ${nvidiaResponse.status}. Error: ${errText}`);
        }
      } catch (err) {
        console.error('Nvidia NIM API call failed, falling back to Gemini:', err);
      }
    }

    // Fallback to Gemini if Nvidia failed or was skipped
    if (!responseText) {
      console.log('Routing to Gemini API...');
      const geminiContents = messages.map(msg => ({
        role: msg.role === 'assistant' ? 'model' : 'user',
        parts: [{ text: msg.content }]
      }));

      const geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
      
      const aiResponse = await fetch(geminiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': geminiKey
        },
        body: JSON.stringify({
          systemInstruction: {
            parts: [{ text: systemPrompt }]
          },
          contents: geminiContents,
          generationConfig: {
            temperature: 0.7
          }
        })
      });

      if (!aiResponse.ok) {
        const textError = await aiResponse.text();
        return new Response(JSON.stringify({ error: `AI Gateway failure: ${aiResponse.status}`, details: textError }), {
          status: 502,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }

      const geminiData = await aiResponse.json();
      if (geminiData.candidates && geminiData.candidates[0].content && geminiData.candidates[0].content.parts) {
        responseText = geminiData.candidates[0].content.parts[0].text;
        usedProvider = 'gemini';
        console.log('✅ Response from Gemini API succeeded');
      }
    }

    // 5. Send data back to App mapped as OpenAI format
    const formattedData = {
      choices: [
        {
          message: {
            content: responseText
          }
        }
      ],
      provider: usedProvider
    };

    await incrementCount();

    return new Response(JSON.stringify({ 
      data: formattedData,
      free_ai_chat_count: !isPremium ? (messageCount + 1) : 0
    }), {
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
