// ============================================================
//  AIService – MaaCare AI Companion (InsForge AI)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AIService {
  AIService._();
  static final AIService instance = AIService._();

  static const String _model = 'openai/gpt-4o-mini'; // Using a stable model from metadata

  Future<String> getChatResponse(List<Map<String, String>> messages) async {
    final url = Uri.parse('${AppConstants.insForgeUrl}/api/ai/chat/completion');
    
    // InsForge headers (using anon key or user token if available)
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AppConstants.insForgeAnonKey}',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'systemPrompt': AppConstants.aiSystemPrompt,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['content'];
        }
      }
      return "I'm sorry, Mama. I'm having a little trouble connecting right now. 🌸";
    } catch (e) {
      return "I'm here for you, but my connection is weak. Let's try again in a moment. 💕";
    }
  }

  // Suggest mood based on user input
  Future<String?> suggestMood(String userInput) async {
    final prompt = "Based on this journal entry, suggest one of these moods: Happy, Tired, Anxious, Excited, Sad. Entry: \"$userInput\". Return only the mood name.";
    
    final response = await getChatResponse([
      {'role': 'user', 'content': prompt}
    ]);

    final moods = ['Happy', 'Tired', 'Anxious', 'Excited', 'Sad'];
    for (var mood in moods) {
      if (response.contains(mood)) return mood;
    }
    return null;
  }

  // Get conversation starter suggestions based on mood
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
