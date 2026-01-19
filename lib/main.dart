import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/screens/login_screen.dart';
import 'firebase_options.dart'; // We need to generate this, but for now we might mock or expect it.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: const LoginScreen(),
    );
  }
}
