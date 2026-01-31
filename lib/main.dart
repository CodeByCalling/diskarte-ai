import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/screens/login_screen.dart'; // Keep for reference if needed
import 'features/landing/screens/landing_page_screen.dart';
import 'firebase_options.dart'; // We need to generate this, but for now we might mock or expect it.

import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const DiskarteApp());
}

class DiskarteApp extends StatelessWidget {
  const DiskarteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diskarte AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF002D72), // Navy Blue
          primary: const Color(0xFF002D72),
          secondary: const Color(0xFFFFFFFF), // Clean White
          surface: const Color(0xFFF5F5F5),   // Light Grey Background
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme(), // Standard readable font
      ),
      home: const LandingPageScreen(),
    );
  }
}
