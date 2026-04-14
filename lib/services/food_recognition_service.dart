import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_keys.dart';
import '../models/food_item.dart';

class FoodRecognitionService {

  Future<List<FoodItem>> recognizeFood(File imageFile) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',    // ✅ Available in your account
        apiKey: ApiKeys.geminiApiKey,
      );

      final imageBytes = await imageFile.readAsBytes();

      final prompt = TextPart('''
Analyze this food image and identify ALL food items visible.
For each item, estimate nutritional information per serving shown.

IMPORTANT: Return ONLY valid JSON. No markdown. No explanation.

Format:
{
  "foods": [
    {
      "name": "food name",
      "quantity": 1,
      "unit": "plate/bowl/piece/cup/serving",
      "calories": 350,
      "protein": 20,
      "carbs": 40,
      "fat": 12
    }
  ]
}
''');

      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from AI');
      }

      String cleaned = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final data = jsonDecode(cleaned);

      if (data['foods'] == null) {
        throw Exception('No foods detected');
      }

      return (data['foods'] as List)
          .map((f) => FoodItem.fromJson(Map<String, dynamic>.from(f)))
          .toList();
    } catch (e) {
      print('AI Error: $e');
      throw Exception('Failed to recognize food: $e');
    }
  }
}