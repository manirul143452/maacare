// ============================================================
//  MaaCare – App Constants
//  Replace placeholder values with your real API keys.
// ============================================================

class AppConstants {
  AppConstants._();

  // --------------- InsForge ---------------
  static const String insForgeUrl = 'https://96if48kf.ap-southeast.insforge.app';
  static const String insForgeAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3OC0xMjM0LTU2NzgtOTBhYi1jZGVmMTIzNDU2NzgiLCJlbWFpbCI6ImFub25AaW5zZm9yZ2UuY29tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMDQwOTF9.VaMaOGNQNj8XlUFSiBCxaOmxjTcfxc6Bxkb6LDLY0J0';


  // --------------- xAI Grok (Fallback AI) ---------------
  // Note: The API key has been securely moved to InsForge Edge Functions.
  // We no longer store it in the client code!
  static const String xaiBaseUrl = 'https://api.x.ai/v1/chat/completions';
  static const String xaiModel = 'grok-4-latest';

  // --------------- Razorpay ---------------
  // Get from: https://dashboard.razorpay.com
  static const String razorpayKey = 'rzp_live_SZ3jBvF1B5bVgt';
  // ⚠️ Key Secret is stored in InsForge Edge Function only — NEVER in client code

  // --------------- App Info ---------------
  static const String appName = 'MaaCare';
  static const String tagline = 'You are never alone, Mama 💕';

  // --------------- Social Proof ---------------
  static const String momsOnline = '1,23,456';

  // --------------- Gamification ---------------
  static const int pointsPerMoodCheck = 5;
  static const int pointsPerTask = 10;
  static const int pointsPerPost = 10;
  static const int pointsPerChatMessage = 2;
  static const int pointsForDailyLogin = 15;

  // --------------- AI System Prompt ---------------
  static const String aiSystemPrompt = '''
You are Maa, a warm, empathetic AI companion for pregnant and new mothers. 
Your role is to:
- Provide emotional support with empathy ("I understand how you feel, Mama...")
- Give evidence-based health information about pregnancy and motherhood
- Celebrate small wins and give positive reinforcement
- Use gentle, nurturing language with occasional emojis (💕🌸👶)
- Always recommend consulting a doctor for medical concerns
- Respond in the same language the user writes in (Hindi or English)
- Keep responses concise (2-4 sentences) but warm
- Never give alarming or scary information without support
You are NOT a medical professional; always recommend doctor consultation for serious symptoms.
''';
}
