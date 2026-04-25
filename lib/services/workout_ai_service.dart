import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_keys.dart';
import '../models/exercise.dart';

class WorkoutAIService {

  // Try multiple models if one fails
  final _modelNames = [
    'gemini-2.0-flash',
    'gemini-2.5-flash',
    'gemini-2.5-pro',
  ];

  Future<Map<String, dynamic>> generateWorkout({
    required String focusArea,
    required int durationMinutes,
    required String equipment,
    required Map<String, dynamic> userProfile,
    required List<String> recentWorkoutNames,
  }) async {

    final recentSummary = recentWorkoutNames.isEmpty
        ? 'No recent workouts'
        : recentWorkoutNames.join(', ');

    final prompt = '''
You are a certified personal fitness trainer AI.

Create a personalized workout plan based on this profile:

USER PROFILE:
- Age: ${userProfile['age']}, Gender: ${userProfile['gender']}
- Height: ${userProfile['height']}cm, Weight: ${userProfile['weight']}kg
- Fitness Goal: ${userProfile['goal']}
- Activity Level: ${userProfile['activityLevel']}

WORKOUT REQUEST:
- Focus Area: $focusArea
- Duration: $durationMinutes minutes
- Available Equipment: $equipment

RECENT WORKOUTS (last 7 days):
$recentSummary

IMPORTANT RULES:
- Avoid muscle groups heavily worked recently
- Include warm-up and cool-down
- Give realistic rest times
- Match intensity to user profile

Return ONLY valid JSON. No markdown. No explanation.

{
  "workout_name": "Upper Body Strength",
  "type": "strength",
  "estimated_duration": 45,
  "estimated_calories_burned": 300,
  "difficulty": "intermediate",
  "warmup": ["Arm circles - 30sec", "Jumping jacks - 1min", "Arm swings - 30sec"],
  "exercises": [
    {
      "name": "Push Ups",
      "sets": 3,
      "reps": 12,
      "suggested_weight_kg": 0,
      "rest_seconds": 60,
      "notes": "Keep core tight"
    },
    {
      "name": "Dumbbell Rows",
      "sets": 3,
      "reps": 10,
      "suggested_weight_kg": 10,
      "rest_seconds": 90,
      "notes": "Squeeze shoulder blades"
    }
  ],
  "cooldown": ["Chest stretch - 30sec", "Shoulder stretch - 30sec"],
  "trainer_tips": "Focus on form over weight. Stay hydrated."
}
''';

    // Try each model until one works
    for (String modelName in _modelNames) {
      try {
        print('Trying model: $modelName');

        final model = GenerativeModel(
          model: modelName,
          apiKey: ApiKeys.geminiApiKey,
        );

        final response = await model.generateContent([Content.text(prompt)]);
        final responseText = response.text;

        if (responseText == null || responseText.isEmpty) {
          continue; // Try next model
        }

        String cleaned = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final data = jsonDecode(cleaned);
        print('Success with model: $modelName');
        return Map<String, dynamic>.from(data);

      } catch (e) {
        print('Model $modelName failed: $e');
        continue; // Try next model
      }
    }

    throw Exception('All AI models are busy. Please try again in 30 seconds.');
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>> getUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data() ?? {};
  }
}