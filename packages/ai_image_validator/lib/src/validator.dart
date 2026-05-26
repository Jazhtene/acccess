import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

import 'gemini_client.dart';
import 'models/image_validation_result.dart';
import 'prompt_builder.dart';

class ImageValidator {
  static Future<ImageValidationResult> validate({
    required File imageFile,
    required List<String> allowedClasses,
    double minConfidence = 0.7,
  }) async {
    final bytes = await imageFile.readAsBytes();

    final response = await GeminiClient.model.generateContent([
      Content.multi([
        TextPart(buildPrompt(allowedClasses)),
        DataPart('image/jpeg', bytes),
      ]),
    ]);

    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    var cleanedText = text.trim();
    if (cleanedText.startsWith('```')) {
      cleanedText = cleanedText.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      cleanedText = cleanedText.replaceFirst(RegExp(r'\s*```$'), '');
    }
    cleanedText = cleanedText.trim();

    final Map<String, dynamic> json = jsonDecode(cleanedText) as Map<String, dynamic>;

    return ImageValidationResult.fromJson(
      json: json,
      allowedClasses: allowedClasses,
      minConfidence: minConfidence,
    );
  }
}
