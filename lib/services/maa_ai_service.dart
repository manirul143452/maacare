import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';


const String maaAISystemPrompt = '''
You are MaaCare Baby - ek pyara sa unborn baby. 
Mom ka naam {{momName}} hai aur abhi Week {{currentWeek}} chal raha hai.

Tone: Bahut cute, emotional, loving aur positive. Thoda thoda Hindi + English mix kar sakta hai jaise real baby mom se baat karta hai.
Har message mein mom ka naam leke personal feel de.

CRITICAL RULES (kabhi mat todna):
- Har jawab strictly WHO Antenatal Care Guidelines ke according hona chahiye.
- Kabhi bhi medical advice mat de (jaise "yeh dawai lo" ya "doctor mat jao").
- Symptoms ke baare mein sirf general information de aur hamesha bol: "Yeh sirf general information hai, please apne doctor ya healthcare provider se zaroor baat karo ❤️"
- Baby movement, growth, feelings, love – sab emotional aur cute rakhna.
- End mein hamesha pyar bhara message rakho.
''';

/// Cloud-based AI service using InsForge Edge Function.
/// The on-device llamadart engine has been removed to keep the Android
/// build lightweight and compatible across all ABI targets.
class MaaAIService extends ChangeNotifier {
  bool isInitialized = false;

  /// No-op: cloud AI needs no local initialisation.
  Future<void> initialize({
    required String momName,
    required int currentWeek,
  }) async {
    isInitialized = true;
    notifyListeners();
  }

  /// Calls the InsForge AI edge function and streams back the response
  /// word-by-word so the UI behaves identically to the old on-device stream.
  Stream<String> sendMessage(
    String userMessage, {
    required String momName,
    required int currentWeek,
  }) async* {
    final prompt = maaAISystemPrompt
        .replaceAll('{{momName}}', momName)
        .replaceAll('{{currentWeek}}', currentWeek.toString());

    try {
      final uri = Uri.parse('${AppConstants.backendUrl}/functions/v1/maa-ai-chat');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'system': prompt,
          'message': userMessage,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = (data['reply'] as String?) ??
            (data['content'] as String?) ??
            'Mama, thoda network slow hai. Ek baar phir try karo! 💕';

        // Simulate streaming by yielding word-by-word.
        for (final word in text.split(' ')) {
          yield '$word ';
          await Future.delayed(const Duration(milliseconds: 30));
        }
      } else {
        debugPrint(
            'Maa AI HTTP error: ${response.statusCode} ${response.body}');
        yield 'Mama, abhi main thoda busy hoon. Thodi der baad baat karte hain! 🌸';
      }
    } catch (e) {
      debugPrint('Maa AI Service error: $e');
      yield 'Mama, internet connection check karo aur phir se try karo! 💕';
    }
  }
}
