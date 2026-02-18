import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../login_screen.dart';

import 'admin_users_screen.dart';
import 'admin_leaderboard_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_questions_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.signOut();

    final err = auth.error;
    if (err != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text("Admin Panel"),
        actions: [
          IconButton(
            tooltip: "Déconnexion",
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _AdminTile(
              icon: Icons.people_alt_outlined,
              title: "Utilisateurs",
              subtitle: "Voir les dernières connexions (lastLoginAt)",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _AdminTile(
              icon: Icons.emoji_events_outlined,
              title: "Classement",
              subtitle: "Voir le leaderboard (best par user)",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminLeaderboardScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _AdminTile(
              icon: Icons.category_outlined,
              title: "Catégories (CRUD)",
              subtitle: "Créer / modifier / supprimer",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _AdminTile(
              icon: Icons.help_outline,
              title: "Questions (CRUD)",
              subtitle: "Créer / modifier / supprimer",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminQuestionsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
