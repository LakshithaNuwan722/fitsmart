import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/billing_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );

  // Initialize billing
  await BillingService().initialize();

  runApp(
    const ProviderScope(
      child: FitSmartApp(),
    ),
  );
}