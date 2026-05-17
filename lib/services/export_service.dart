import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import '../models/meal.dart';
import '../models/workout.dart';
import '../services/meal_service.dart';
import '../services/progress_service.dart';

class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  // ─── Export Weekly PDF Report ─────────────────────────────────
  Future<void> exportWeeklyReport() async {
    try {
      // Fetch data
      final progressService = ProgressService();
      final weeklyLogs = await progressService.getWeeklyLogsFromMeals();
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      final userData = userDoc.data() ?? {};

      // Calculate stats
      int totalCalories = 0;
      int totalWorkouts = 0;
      double totalWater = 0;

      for (var log in weeklyLogs) {
        totalCalories += log.caloriesConsumed;
        totalWorkouts += log.workoutsCompleted;
        totalWater += log.waterIntake;
      }

      final avgCalories = weeklyLogs.isNotEmpty
          ? totalCalories ~/ weeklyLogs.length
          : 0;

      // Create PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.purple700,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FitSmart Weekly Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Name: ${userData['name'] ?? 'User'}',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 14),
                  ),
                  pw.Text(
                    'Week: ${DateFormat('MMM d').format(DateTime.now().subtract(const Duration(days: 6)))} - ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 14),
                  ),
                  pw.Text(
                    'Generated: ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())}',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // Summary Stats
            pw.Text(
              'Weekly Summary',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),

            pw.Row(
              children: [
                _buildPDFStatCard('Total Calories', '$totalCalories kcal', PdfColors.orange300),
                pw.SizedBox(width: 12),
                _buildPDFStatCard('Avg/Day', '$avgCalories kcal', PdfColors.blue300),
                pw.SizedBox(width: 12),
                _buildPDFStatCard('Workouts', '$totalWorkouts sessions', PdfColors.purple300),
                pw.SizedBox(width: 12),
                _buildPDFStatCard('Avg Water', '${(totalWater / 7).toStringAsFixed(1)} L', PdfColors.cyan300),
              ],
            ),

            pw.SizedBox(height: 24),

            // User Profile
            pw.Text(
              'Profile',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPDFInfoRow('Goal', _getGoalName(userData['goal'] ?? 'maintain')),
                        _buildPDFInfoRow('Daily Target', '${userData['dailyCalorieTarget'] ?? 2000} kcal'),
                        _buildPDFInfoRow('Activity Level', userData['activityLevel'] ?? 'moderate'),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPDFInfoRow('Age', '${userData['age'] ?? '-'} years'),
                        _buildPDFInfoRow('Height', '${userData['height'] ?? '-'} cm'),
                        _buildPDFInfoRow('Weight', '${userData['weight'] ?? '-'} kg'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // Daily Breakdown
            pw.Text(
              'Daily Breakdown',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),

            // Table Header
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: PdfColors.purple700,
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text('Date', style: const pw.TextStyle(color: PdfColors.white))),
                  pw.Expanded(child: pw.Text('Calories', style: const pw.TextStyle(color: PdfColors.white))),
                  pw.Expanded(child: pw.Text('Water', style: const pw.TextStyle(color: PdfColors.white))),
                  pw.Expanded(child: pw.Text('Workouts', style: const pw.TextStyle(color: PdfColors.white))),
                ],
              ),
            ),

            // Table Rows
            ...weeklyLogs.asMap().entries.map((entry) {
              final index = entry.key;
              final log = entry.value;
              final date = DateTime.parse(log.date);
              final isEven = index % 2 == 0;

              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: isEven ? PdfColors.grey50 : PdfColors.white,
                child: pw.Row(
                  children: [
                    pw.Expanded(child: pw.Text(DateFormat('EEE, MMM d').format(date))),
                    pw.Expanded(child: pw.Text('${log.caloriesConsumed} kcal')),
                    pw.Expanded(child: pw.Text('${log.waterIntake.toStringAsFixed(1)} L')),
                    pw.Expanded(child: pw.Text('${log.workoutsCompleted} workout(s)')),
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 24),

            // Footer
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated by FitSmart - AI-Powered Fitness Planner',
              style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
            ),
          ],
        ),
      );

      // Save and share PDF
      await _savePDFAndShare(pdf, 'FitSmart_Weekly_Report');
    } catch (e) {
      throw Exception('Failed to export report: $e');
    }
  }

  // ─── Export Meals CSV ─────────────────────────────────────────
  Future<void> exportMealsCSV() async {
    try {
      // Fetch meals from last 30 days
      final thirtyDaysAgo = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 30)));

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('meals')
          .where('date', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .orderBy('date', descending: true)
          .get();

      // Build CSV data
      final List<List<dynamic>> csvData = [
        // Header
        ['Date', 'Meal Type', 'Food Items', 'Calories', 'Protein (g)', 'Carbs (g)', 'Fat (g)'],
      ];

      for (var doc in snapshot.docs) {
        final meal = Meal.fromMap(doc.data(), doc.id);
        final foodNames = meal.foodItems.map((f) => f.name).join(', ');

        csvData.add([
          meal.date,
          meal.mealType,
          foodNames,
          meal.totalCalories,
          meal.totalProtein.toStringAsFixed(1),
          meal.totalCarbs.toStringAsFixed(1),
          meal.totalFat.toStringAsFixed(1),
        ]);
      }

      await _saveCSVAndShare(csvData, 'FitSmart_Meals');
    } catch (e) {
      throw Exception('Failed to export meals: $e');
    }
  }

  // ─── Export Workouts CSV ──────────────────────────────────────
  Future<void> exportWorkoutsCSV() async {
    try {
      // Fetch workouts from last 30 days
      final thirtyDaysAgo = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 30)));

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('workouts')
          .where('date', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .orderBy('date', descending: true)
          .get();

      // Build CSV data
      final List<List<dynamic>> csvData = [
        // Header
        ['Date', 'Workout Name', 'Type', 'Duration (min)', 'Calories Burned', 'Exercises', 'AI Generated', 'Completed'],
      ];

      for (var doc in snapshot.docs) {
        final workout = Workout.fromMap(doc.data(), doc.id);
        final exerciseNames = workout.exercises.map((e) => e.name).join(', ');

        csvData.add([
          workout.date,
          workout.name,
          workout.type,
          workout.duration,
          workout.caloriesBurned,
          exerciseNames,
          workout.isAIGenerated ? 'Yes' : 'No',
          workout.completed ? 'Yes' : 'No',
        ]);
      }

      await _saveCSVAndShare(csvData, 'FitSmart_Workouts');
    } catch (e) {
      throw Exception('Failed to export workouts: $e');
    }
  }

  // ─── Export Progress CSV ──────────────────────────────────────
  Future<void> exportProgressCSV() async {
    try {
      final progressService = ProgressService();
      final weeklyLogs = await progressService.getWeeklyLogsFromMeals();
      final weightHistory = await progressService.getWeightHistory();

      // Build CSV data
      final List<List<dynamic>> csvData = [
        // Header
        ['Date', 'Calories Consumed', 'Calories Burned', 'Water (L)', 'Weight (kg)', 'Workouts'],
      ];

      for (var log in weeklyLogs) {
        final weightEntry = weightHistory.firstWhere(
              (w) => w['date'] == log.date,
          orElse: () => {'weight': null},
        );

        csvData.add([
          log.date,
          log.caloriesConsumed,
          log.caloriesBurned,
          log.waterIntake.toStringAsFixed(1),
          weightEntry['weight']?.toString() ?? '-',
          log.workoutsCompleted,
        ]);
      }

      await _saveCSVAndShare(csvData, 'FitSmart_Progress');
    } catch (e) {
      throw Exception('Failed to export progress: $e');
    }
  }

  // ─── Helper Methods ───────────────────────────────────────────

  Future<void> _savePDFAndShare(pw.Document pdf, String fileName) async {
    final Uint8List bytes = await pdf.save();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '$fileName - FitSmart Export',
      subject: '$fileName',
    );
  }

  Future<void> _saveCSVAndShare(List<List<dynamic>> data, String fileName) async {
    final String csvString = const ListToCsvConverter().convert(data);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.csv');
    await file.writeAsString(csvString);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '$fileName - FitSmart Export',
      subject: '$fileName',
    );
  }

  pw.Widget _buildPDFStatCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 4),
            pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPDFInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }

  String _getGoalName(String goal) {
    switch (goal) {
      case 'lose_weight': return 'Lose Weight';
      case 'gain_muscle': return 'Gain Muscle';
      case 'maintain': return 'Maintain Weight';
      default: return goal;
    }
  }
}