import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/dashboard_provider.dart';

// Screens
import 'views/screens/splash_screen.dart';

// ✅ Admin screen (corrige le chemin selon ton projet)
import 'views/screens/admin/admin_home_screen.dart';

// ✅ User screens (corrige le chemin si nécessaire)
import 'views/screens/login_screen.dart';
import 'views/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const QuizNaYoApp());
  } catch (e) {
    runApp(FirebaseInitErrorApp(error: e.toString()));
  }
}

/// ===============================
/// APP PRINCIPALE
/// ===============================
class QuizNaYoApp extends StatelessWidget {
  const QuizNaYoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth global
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..loadSession(),
        ),

        // Quiz engine
        ChangeNotifierProvider(
          create: (_) => QuizProvider(),
        ),

        // Leaderboard
        ChangeNotifierProvider(
          create: (_) => LeaderboardProvider(),
        ),

        // Dashboard KPI
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Quiz Na Yo',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
          scaffoldBackgroundColor: Colors.grey.shade50,
        ),

        // ✅ Splash décide Login / Home user / Admin panel
        home: const SplashScreen(),

        // ✅ (Optionnel mais utile) routes nommées si tu veux
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/admin': (_) => const AdminHomeScreen(),
        },
      ),
    );
  }
}

/// ===============================
/// FALLBACK SI FIREBASE KO
/// ===============================
class FirebaseInitErrorApp extends StatelessWidget {
  final String error;

  const FirebaseInitErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz Na Yo (Erreur Firebase)',
      theme: ThemeData(useMaterial3: true),
      home: FirebaseInitErrorScreen(error: error),
    );
  }
}

class FirebaseInitErrorScreen extends StatelessWidget {
  final String error;

  const FirebaseInitErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erreur de configuration Firebase')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Firebase n'a pas pu s'initialiser.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Vérifie :\n"
                    "• lib/firebase_options.dart\n"
                    "• flutterfire configure\n"
                    "• google-services.json\n"
                    "• SHA-1 / SHA-256\n",
              ),
              const SizedBox(height: 12),
              const Text(
                "Détail technique :",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SelectableText(error),
            ],
          ),
        ),
      ),
    );
  }
}
