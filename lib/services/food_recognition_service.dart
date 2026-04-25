import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_keys.dart';
import '../models/food_item.dart';

class FoodRecognitionService {

  final _modelNames = [
    'gemini-2.0-flash',
    'gemini-2.5-flash',
    'gemini-2.5-pro',
  ];

  Future<List<FoodItem>> recognizeFood(File imageFile) async {
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

    // Try each model until one works
    for (String modelName in _modelNames) {
      try {
        print('Trying model: $modelName');

        final model = GenerativeModel(
          model: modelName,
          apiKey: ApiKeys.geminiApiKey,
        );

        final response = await model.generateContent([
          Content.multi([prompt, imagePart])
        ]);

        final responseText = response.text;

        if (responseText == null || responseText.isEmpty) {
          continue;
        }

        String cleaned = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final data = jsonDecode(cleaned);

        if (data['foods'] == null) {
          continue;
        }

        print('Success with model: $modelName');
        return (data['foods'] as List)
            .map((f) => FoodItem.fromJson(Map<String, dynamic>.from(f)))
            .toList();

      } catch (e) {
        print('Model $modelName failed: $e');
        continue;
      }
    }

    throw Exception('All AI models are busy. Please try again in 30 seconds.');
  }
}