// ============================================================
//  MaaCare – App Constants
//  Backend: https://api.maacare.co  (AWS EC2 + MongoDB + NVIDIA AI)
// ============================================================

class AppConstants {
  AppConstants._();

  // ── Backend URL (AWS EC2 via api.maacare.co) ─────────────
  static const String backendUrl = 'https://api.maacare.co';
  // Dummy anon key — auth is handled via JWT (not InsForge SDK)
  static const String backendAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3OC0xMjM0LTU2NzgtOTBhYi1jZGVmMTIzNDU2NzgiLCJlbWFpbCI6ImFub25AbWFhY2FyZS5jbyIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzc1MTA0MDkxfQ.placeholder';

  // ── Razorpay ─────────────────────────────────────────────
  // ✅ Public Key ID only — Secret key is in AWS EC2 environment variables ONLY.
  static const String razorpayKey = 'rzp_live_T4F26avLIUs7xR';

  // ── App Info ─────────────────────────────────────────────
  static const String appName = 'MaaCare';
  static const String tagline = 'You are never alone, Mama 💕';
  static const String appDomain = 'maacare.co';

  // ── Social Proof ─────────────────────────────────────────
  static const String momsOnline = '1,23,456';

  // ── Gamification ─────────────────────────────────────────
  static const int pointsPerMoodCheck = 5;
  static const int pointsPerTask = 10;
  static const int pointsPerPost = 10;
  static const int pointsPerChatMessage = 2;
  static const int pointsForDailyLogin = 15;

  // ── AI System Prompt (sent to NVIDIA NIM / Llama) ────────
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
