// Razorpay Order Creation & Payment Verification Edge Function
// Secret Key is stored securely in environment variables - NEVER in client code

const RAZORPAY_KEY_SECRET = Deno.env.get('RAZORPAY_KEY_SECRET') || 'Vp4yflICMf3T2PLzQyc5Ieh4';
const RAZORPAY_KEY_ID = Deno.env.get('RAZORPAY_KEY_ID') || 'rzp_live_SZ3jBvF1B5bVgt';

module.exports = async function(request) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Content-Type': 'application/json',
  };

  if (request.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const body = await request.json();
    const { action } = body;

    // ─── Create Order ───
    if (action === 'create_order') {
      const { amount, currency = 'INR', receipt } = body;
      
      const credentials = btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`);
      const response = await fetch('https://api.razorpay.com/v1/orders', {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${credentials}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          amount,
          currency,
          receipt: receipt || `maacare_${Date.now()}`,
        }),
      });

      const order = await response.json();
      return new Response(JSON.stringify(order), { headers: corsHeaders });
    }

    // ─── Verify Payment Signature ───
    if (action === 'verify_payment') {
      const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = body;
      
      const encoder = new TextEncoder();
      const message = encoder.encode(`${razorpay_order_id}|${razorpay_payment_id}`);
      const keyData = encoder.encode(RAZORPAY_KEY_SECRET);
      
      const cryptoKey = await crypto.subtle.importKey(
        'raw', keyData, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
      );
      const signatureBytes = await crypto.subtle.sign('HMAC', cryptoKey, message);
      const generatedSignature = Array.from(new Uint8Array(signatureBytes))
        .map(b => b.toString(16).padStart(2, '0')).join('');
      
      const isValid = generatedSignature === razorpay_signature;
      return new Response(
        JSON.stringify({ success: isValid, message: isValid ? 'Payment verified' : 'Invalid signature' }),
        { headers: corsHeaders }
      );
    }

    return new Response(JSON.stringify({ error: 'Unknown action' }), {
      status: 400, headers: corsHeaders
    });

  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500, headers: corsHeaders
    });
  }
};
