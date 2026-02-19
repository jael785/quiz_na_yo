import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

// Screens
import 'login_screen.dart';
import 'home_screen.dart';
import 'admin/admin_home_screen.dart';

/// GateScreen:
/// - si pas connecté => Login
/// - si admin => AdminHomeScreen DIRECT
/// - sinon => HomeScreen
class GateScreen extends StatelessWidget {
  const GateScreen({super.key});

  // ✅ Admin UID (ton UID)
  static const String adminUid = "FXwSguoqMaXWdSnORbH2QoI9Atk1";

  bool _isAdmin(String uid) => uid == adminUid;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const LoginScreen();
    }

    if (_isAdmin(user.uid)) {
      return const AdminHomeScreen();
    }

    return const HomeScreen();
  }
}
