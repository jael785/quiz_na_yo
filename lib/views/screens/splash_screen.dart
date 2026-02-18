import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

// ✅ Admin
import '../../core/admin_config.dart';

// Screens (adapte si chemins différents)
import 'login_screen.dart';
import 'home_screen.dart';
import 'admin/admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // On attend la fin du "loadSession()" côté AuthProvider.
    // Dès que c'est prêt, on route.
    if (_navigated) return;

    final auth = context.watch<AuthProvider>();

    // Tant que ça charge, on reste sur le splash
    if (auth.isLoading) return;

    _navigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final user = auth.user;

      // 1) Pas connecté => Login
      if (user == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      // 2) Admin => AdminHomeScreen DIRECT
      if (AdminConfig.isAdmin(user.uid)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
        return;
      }

      // 3) User normal => HomeScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6FB),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}
