import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

class AIService {
  Future<String> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyApiKey) ?? '';
  }

  // Generic method to call Gemini API
  Future<String> _callGemini(String prompt, String systemPrompt) async {
    final apiKey = await _getApiKey();
    
    // If no API Key is available, run in premium sandbox simulator mode!
    if (apiKey.trim().isEmpty) {
      return await _simulateAISandbox(prompt, systemPrompt);
    }

    final url = Uri.parse('${AppConstants.geminiEndpoint}${AppConstants.defaultGeminiModel}:generateContent?key=$apiKey');
    
    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': '$systemPrompt\n\nUser Content:\n$prompt'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] ?? 'No text generated.';
          }
        }
        return 'Gemini API response structure parsing failed.';
      } else {
        final errData = json.decode(response.body);
        final errMsg = errData['error']?['message'] ?? 'Unknown API Error';
        throw Exception("Gemini API Error (Status ${response.statusCode}): $errMsg");
      }
    } catch (e) {
      throw Exception("Tizimda AI so'rovida xatolik: $e");
    }
  }

  // Public AI Capabilities
  Future<String> generateText(String topic) async {
    return await _callGemini(
      topic,
      AppConstants.promptGeneralAI + "\n\nUser wants you to generate a full structured professional text about this topic."
    );
  }

  Future<String> checkGrammar(String text) async {
    return await _callGemini(text, AppConstants.promptGrammarCheck);
  }

  Future<String> summarizeText(String text) async {
    return await _callGemini(text, AppConstants.promptSummarize);
  }

  Future<String> changeTone(String text) async {
    return await _callGemini(text, AppConstants.promptPolish);
  }

  Future<String> translate(String text, String fromLang, String toLang) async {
    final translationSystemPrompt = 
        "${AppConstants.promptTranslate}\nSource Language: $fromLang, Target Language: $toLang";
    return await _callGemini(text, translationSystemPrompt);
  }

  Future<String> chatMessage(String message, List<Map<String, String>> chatHistory) async {
    final apiKey = await _getApiKey();
    if (apiKey.trim().isEmpty) {
      return await _simulateAISandbox(message, AppConstants.promptGeneralAI);
    }

    final url = Uri.parse('${AppConstants.geminiEndpoint}${AppConstants.defaultGeminiModel}:generateContent?key=$apiKey');
    
    // Map history to Gemini structure
    final contents = <Map<String, dynamic>>[];
    for (var turn in chatHistory) {
      final role = turn['role'] == 'user' ? 'user' : 'model';
      contents.add({
        'role': role,
        'parts': [{'text': turn['message'] ?? ''}]
      });
    }

    // Add current prompt
    contents.add({
      'role': 'user',
      'parts': [{'text': "${AppConstants.promptGeneralAI}\n\nUser input: $message"}]
    });

    final body = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ?? '';
      } else {
        throw Exception("Chat response error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("AI Chat error: $e");
    }
  }

  // Premium AI Sandbox Simulator
  Future<String> _simulateAISandbox(String prompt, String systemPrompt) async {
    await Future.delayed(const Duration(milliseconds: 1500)); // Mimic API network latency
    
    if (systemPrompt.contains(AppConstants.promptGrammarCheck)) {
      return "Errors Found:\n"
          "- 'intellekt' so'zi noto'g'ri yozilgan bo'lishi mumkin.\n"
          "- Gap oxirida tinish belgilari tushirib qoldirilgan.\n\n"
          "Corrected Text:\n"
          "```\n"
          "${prompt.replaceAll("intelekt", "intellekt").replaceAll("xato", "xatolik")}\n"
          "```\n\n"
          "Explanation:\n"
          "Matn Muharriri Sandbox sizga yordam bermoqda! Matndagi imlo xatolari avtomatik tarzda aniqlandi. "
          "Haqiqiy Gemini API kalitini **Sozlamalar** sahifasida kiritishingiz mumkin.";
    }

    if (systemPrompt.contains(AppConstants.promptSummarize)) {
      return "### Qisqacha Xulosa (Summary)\n"
          "Taqdim etilgan matn Matn Muharriri aqlli muharririda muvaffaqiyatli tahlil qilindi.\n\n"
          "### Asosiy Mavzular:\n"
          "- Matn mazmunining qisqa va lo'nda bayoni.\n"
          "- Foydalanuvchi hujjatlarining intellektual qayta ishlanishi.\n"
          "- Tizimning barqaror va tezkor ishlash prinsiplari.\n\n"
          "> [!NOTE]\n"
          "> Bu Sandbox rejimidagi simulatsiyadir. To'liq AI imkoniyatlari uchun API kalitni sozlang.";
    }

    if (systemPrompt.contains(AppConstants.promptPolish)) {
      return "Hurmatli foydalanuvchi,\n\n"
          "Ushbu hujjat orqali shuni ma'lum qilamizki, Matn Muharriri dasturiy ta'minoti rasmiy "
          "va professional darajada ma'lumotlarni rasmiylashtirish imkoniyatini taqdim etadi. "
          "Taqdim etilgan matn rasmiy-idoraviy uslub talablariga muvofiq ravishda mukammallashtirildi.\n\n"
          "Hurmat bilan,\n"
          "Matn Muharriri Professional Redaktori.";
    }

    if (systemPrompt.contains(AppConstants.promptTranslate)) {
      if (systemPrompt.contains("Uzbek") && systemPrompt.contains("English")) {
        return "[Translated to English]\n"
            "This is a premium smart document editor powered by artificial intelligence, "
            "designed specifically to streamline your professional writing workflow.";
      }
      return "[Translated to Uzbek]\n"
          "Bu sun'iy intellektga asoslangan mukammal aqlli hujjat muharriri bo'lib, "
          "sizning professional yozish ishlaringizni osonlashtirish uchun mo'ljallangan.";
    }

    // General AI chat fallback responses
    final text = prompt.toLowerCase();
    if (text.contains('salom') || text.contains('hello')) {
      return "Salom! Men Matn Muharriri aqlli yordamchisiman. Sizga hujjatlar yozish, grammar xatolarni tuzatish, translation qilish yoki matnlarni professional uslubga keltirishda qanday yordam bera olaman?\n\n*Haqiqiy rejimda ishlash uchun API kalitni o'rnating!*";
    }
    
    return "Men Matn Muharriri aqlli yordamchisi Sandbox rejimidaman.\n\n"
        "Siz kiritgan matn:\n"
        "\"$prompt\"\n\n"
        "Men hozir oflayn sandbox rejimida ishlayapman. Haqiqiy sun'iy intellekt javoblarini olish uchun **Sozlamalar** sahifasiga o'tib, **Gemini API kalitini** faollashtiring. Bu juda oson va mutlaqo xavfsiz!";
  }
}
