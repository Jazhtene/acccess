import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Replace with your actual Gemini API key
  // In production, load from environment or secure storage
  static const _apiKey = 'YOUR_GEMINI_API_KEY';

  static GenerativeModel? _model;

  static GenerativeModel get _instance {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    return _model!;
  }

  /// Generates photography feedback from Gemini based on rubric scores.
  /// Returns null if the API key is not set or the call fails (falls back to local feedback).
  static Future<String?> generateFeedback({
    required Map<String, int> scores,
    required String title,
    required int totalScore,
    required int maxScore,
  }) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') return null; // not configured

    try {
      final scoreLines = scores.entries
          .map((e) => '- ${e.key}: ${e.value}/5')
          .join('\n');

      final prompt = '''
You are an expert photography coach for ACCESS, a student documentation and photography organization at USTP Oroquieta.

A student submitted event photos titled "$title" and received the following rubric scores (1–5 scale):
$scoreLines

Overall score: $totalScore / $maxScore

Write a concise, encouraging, and actionable feedback paragraph (3–5 sentences) for this student. 
Focus on:
1. What they did well based on their highest scores
2. Specific, practical advice for their lowest-scoring areas
3. A motivating closing sentence

Keep the tone professional but warm. Do not use bullet points — write in flowing prose.
''';

      final response = await _instance.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      return (text != null && text.isNotEmpty) ? text : null;
    } catch (_) {
      return null; // fall back to local feedback on any error
    }
  }
}
