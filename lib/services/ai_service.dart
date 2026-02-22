// ============================================================
//  AIService – MaaCare AI Companion
//  Primary: InsForge AI  |  Fallback: xAI Grok
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AIService {
  AIService._();
  static final AIService instance = AIService._();

  // ── Primary: InsForge AI ──
  static const String _insForgeModel = 'openai/gpt-4o-mini';

  /// Main method – tries InsForge first, falls back to xAI Grok
  Future<String> getChatResponse(List<Map<String, String>> messages) async {
    // ─── Try InsForge AI (primary, free) ───
    try {
      final response = await _callInsForgeAI(messages);
      if (response != null) return response;
    } catch (_) {}

    // ─── Try xAI Grok (fallback) ───
    try {
      final response = await _callGrokAI(messages);
      if (response != null) return response;
    } catch (_) {}

    // ─── Both failed ───
    return "I'm here for you, Mama 💕 My connection is a bit weak right now. Let's try again in a moment! 🌸";
  }

  // ─────────────────── InsForge AI ───────────────────

  Future<String?> _callInsForgeAI(List<Map<String, String>> messages) async {
    final url = Uri.parse('${AppConstants.insForgeUrl}/api/ai/chat/completion');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConstants.insForgeAnonKey}',
      },
      body: jsonEncode({
        'model': _insForgeModel,
        'messages': messages,
        'systemPrompt': AppConstants.aiSystemPrompt,
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['content'] != null) {
        return data['content'] as String;
      }
    }
    return null;
  }

  // ─────────────────── xAI Grok (Fallback) ───────────────────

  Future<String?> _callGrokAI(List<Map<String, String>> messages) async {
    // Prepend system prompt for Grok
    final grokMessages = <Map<String, String>>[
      {'role': 'system', 'content': AppConstants.aiSystemPrompt},
      ...messages,
    ];

    final response = await http.post(
      Uri.parse(AppConstants.xaiBaseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConstants.xaiApiKey}',
      },
      body: jsonEncode({
        'model': AppConstants.xaiModel,
        'messages': grokMessages,
        'stream': false,
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        return choices[0]['message']['content'] as String;
      }
    }
    return null;
  }

  // ─────────────────── Utility Methods ───────────────────

  /// Suggest mood from journal entry
  Future<String?> suggestMood(String userInput) async {
    final prompt =
        "Based on this journal entry, suggest one of these moods: Happy, Tired, Anxious, Excited, Sad. Entry: \"$userInput\". Return only the mood name.";

    final response = await getChatResponse([
      {'role': 'user', 'content': prompt}
    ]);

    final moods = ['Happy', 'Tired', 'Anxious', 'Excited', 'Sad'];
    for (var mood in moods) {
      if (response.contains(mood)) return mood;
    }
    return null;
  }

  /// Get conversation starters based on mood
  List<String> getMoodSuggestions(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return ['Fun activities with baby', 'Capturing memories', 'Energy tips'];
      case 'tired':
        return ['Quick nap hacks', 'Relaxation techniques', 'Self-care tips'];
      case 'anxious':
        return ['Calming exercises', 'Expert advice', 'Community support'];
      case 'sad':
        return ['Emotional support', 'Warming recipes', 'Daily affirmations'];
      case 'excited':
        return ['Baby milestones', 'Sharing the joy', 'Preparation tips'];
      default:
        return ['Baby care basics', 'Motherhood tips', 'Health advice'];
    }
  }
}
