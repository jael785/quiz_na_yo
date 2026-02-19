import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/dashboard_provider.dart';

import '../../services/firestore_service.dart';
import '../../models/leaderboard_entry_model.dart';

import '../widgets/loading_overlay.dart';
import '../widgets/shimmer_block.dart' as shimmer;

import 'login_screen.dart';
import 'leaderboard_screen.dart';
import 'quiz_screen.dart';

// ✅ ADMIN
import 'admin/admin_home_screen.dart';

/// HomeScreen complet:
/// - ✅ Admin => AdminHomeScreen direct
/// - ✅ Firestore mode : choix catégorie (optionnel) + active categories/questions
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✅ admin UID (comme dans tes rules)
  static const String _adminUid = "FXwSguoqMaXWdSnORbH2QoI9Atk1";

  int _selectedIndex = 0;

  // Petit boot delay (UX shimmer)
  late final Future<void> _bootFuture =
  Future<void>.delayed(const Duration(milliseconds: 650));

  bool _startedDashboardStream = false;

  void _snackSafe(BuildContext ctx, String msg) {
    if (!ctx.mounted) return;
    ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(SnackBar(content: Text(msg)));
  }

  String _displayName({required String? name, required String? email}) {
    final n = (name ?? '').trim();
    if (n.isNotEmpty) return n;
    final e = (email ?? '').trim();
    if (e.contains('@')) return e.split('@').first;
    return "Utilisateur";
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    // Pas connecté -> Login
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ✅ Admin => direct Admin Panel (sans logique bouton)
    if (user.uid == _adminUid) {
      return const AdminHomeScreen();
    }

    // KPI streams (une seule fois)
    if (!_startedDashboardStream) {
      _startedDashboardStream = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<DashboardProvider>().startForUser(user.uid);
      });
    }

    final name = _displayName(name: user.name, email: user.email);

    return LoadingOverlay(
      isLoading: auth.isLoading,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return Scaffold(
            backgroundColor: const Color(0xFFF4F6FB),

            // Drawer mobile/tablette
            drawer: isWide
                ? null
                : _DashboardDrawer(
              selectedIndex: _selectedIndex,
              userName: name,
              userEmail: user.email ?? "-",
              photoUrl: user.photoUrl,
              onSelect: (i) {
                setState(() => _selectedIndex = i);
                Navigator.of(context).pop();
              },
              onLogout: () => _logout(context),
            ),

            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 12,
              title: Row(
                children: [
                  Image.asset(
                    'assets/images/quiz_na_yo_logo.png',
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Quiz Na Yo",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        "Bonjour, $name",
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _UserAvatar(
                    photoUrl: user.photoUrl,
                    fallbackText: name,
                  ),
                ),
              ],
            ),

            body: Row(
              children: [
                // Rail desktop
                if (isWide)
                  _DashboardRail(
                    selectedIndex: _selectedIndex,
                    userName: name,
                    userEmail: user.email ?? "-",
                    photoUrl: user.photoUrl,
                    onSelect: (i) => setState(() => _selectedIndex = i),
                    onLogout: () => _logout(context),
                  ),

                // Contenu
                Expanded(
                  child: FutureBuilder<void>(
                    future: _bootFuture,
                    builder: (context, snapshot) {
                      final loading =
                          snapshot.connectionState != ConnectionState.done;

                      if (loading) return const _DashboardShimmer();

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _buildPage(
                          key: ValueKey(_selectedIndex),
                          index: _selectedIndex,
                          userName: name,
                          userId: user.uid,
                          userEmail: user.email ?? "-",
                          photoUrl: user.photoUrl,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    final err = context.read<AuthProvider>().error;

    if (!context.mounted) return;

    if (err != null) {
      _snackSafe(context, err);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  Widget _buildPage({
    required Key key,
    required int index,
    required String userName,
    required String userId,
    required String userEmail,
    required String? photoUrl,
  }) {
    switch (index) {
      case 0:
        return _OverviewPage(key: key, userName: userName);
      case 1:
      // ✅ Quiz Hub avec 3 options uniquement
        return const _QuizHubPage(key: ValueKey("quizhub"));
      case 2:
        return _LeaderboardHubPage(key: key, userId: userId);
      case 3:
        return _ProfilePage(
          key: key,
          userName: userName,
          userEmail: userEmail,
          photoUrl: photoUrl,
        );
      default:
        return _OverviewPage(key: key, userName: userName);
    }
  }
}

//////////////////////////////////////////////////////////////
// PAGES
//////////////////////////////////////////////////////////////

class _OverviewPage extends StatelessWidget {
  final String userName;

  const _OverviewPage({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _GradientHero(userName: userName),
          const SizedBox(height: 14),

          if (dash.isLoading) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                shimmer.ShimmerBlock(height: 84, width: 260),
                shimmer.ShimmerBlock(height: 84, width: 260),
                shimmer.ShimmerBlock(height: 84, width: 260),
              ],
            ),
          ] else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _KpiCard(
                  title: "Quiz joués",
                  value: "${dash.totalQuizzes}",
                  icon: Icons.quiz_outlined,
                  accent: Colors.blue,
                ),
                _KpiCard(
                  title: "Meilleur score",
                  value: (dash.bestScore == null || dash.bestTotal == null)
                      ? "—"
                      : "${dash.bestScore}/${dash.bestTotal}",
                  icon: Icons.star_outline,
                  accent: Colors.green,
                ),
                _KpiCard(
                  title: "Votre rang",
                  value: dash.position == null ? "—" : "#${dash.position}",
                  icon: Icons.emoji_events_outlined,
                  accent: Colors.orange,
                ),
              ],
            ),
          ],

          if (dash.error != null) ...[
            const SizedBox(height: 10),
            Text(
              "Erreur KPI: ${dash.error}",
              style: const TextStyle(color: Colors.red),
            ),
          ],

          const SizedBox(height: 18),

          // Raccourci: Quiz API
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text(
                "Lancer un quiz (API)",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text("Questions en ligne via OpenTDB."),
              onTap: () async {
                final quiz = context.read<QuizProvider>();
                await quiz.startApiQuiz();

                if (!context.mounted) return;

                if (quiz.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(quiz.error!)),
                  );
                  return;
                }

                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuizScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Raccourci: Leaderboard
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text(
                "Voir le classement",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text("Top 3 + liste complète"),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizHubPage extends StatefulWidget {
  const _QuizHubPage({super.key});

  @override
  State<_QuizHubPage> createState() => _QuizHubPageState();
}

class _QuizHubPageState extends State<_QuizHubPage> {
  String? _selectedCategoryId; // null => toutes catégories (Firestore)
  String? _selectedCategoryName;

  Future<void> _launchQuiz(
      BuildContext context,
      Future<void> Function() starter,
      ) async {
    final quiz = context.read<QuizProvider>();
    await starter();

    if (!context.mounted) return;

    if (quiz.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(quiz.error!)),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
  }

  Future<void> _pickFirestoreCategory(BuildContext context) async {
    final fs = FirestoreService();

    // ✅ Récupère les catégories actives (fallback active ?? true dans service)
    final cats = await fs.fetchActiveCategories();

    if (!context.mounted) return;

    if (cats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucune catégorie active disponible.")),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: ListView(
            children: [
              const ListTile(
                title: Text(
                  "Choisir une catégorie Firestore",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text("Les questions proviennent de l’admin."),
              ),
              const Divider(),

              // Toutes catégories
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text("Toutes les catégories"),
                onTap: () {
                  setState(() {
                    _selectedCategoryId = null;
                    _selectedCategoryName = null;
                  });
                  Navigator.of(context).pop();
                },
              ),

              const Divider(),

              // Liste catégories
              for (final c in cats)
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text((c['name'] ?? 'Sans nom').toString()),
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = (c['id'] ?? '').toString();
                      _selectedCategoryName = (c['name'] ?? '').toString();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            "Quiz",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text("Choisis un mode de quiz."),
          const SizedBox(height: 14),

          // ✅ 1) API
          _QuizModeCard(
            icon: Icons.cloud_outlined,
            title: "Quiz en ligne (API)",
            subtitle: "Questions OpenTDB via internet",
            loading: quiz.isLoading,
            onTap: () => _launchQuiz(context, () => quiz.startApiQuiz()),
          ),
          const SizedBox(height: 12),

          // ✅ 2) Local
          _QuizModeCard(
            icon: Icons.storage_outlined,
            title: "Quiz hors ligne (Local)",
            subtitle: "Questions depuis JSON local",
            loading: quiz.isLoading,
            onTap: () => _launchQuiz(context, () => quiz.startLocalQuiz()),
          ),
          const SizedBox(height: 12),

          // ✅ 3) Firestore (Admin)
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_done_outlined, size: 28),
                  title: const Text(
                    "Quiz Firestore (Admin)",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    _selectedCategoryId == null
                        ? "Questions créées par l’admin (toutes catégories)"
                        : "Catégorie: ${_selectedCategoryName ?? _selectedCategoryId}",
                  ),
                  trailing: quiz.isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: quiz.isLoading
                      ? null
                      : () => _launchQuiz(
                    context,
                        () => quiz.startFirestoreQuiz(
                      // ✅ tu peux changer limit si tu veux
                      limit: 30,
                      categoryId: _selectedCategoryId,
                      difficulty: null,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text("Choisir la catégorie"),
                  subtitle: const Text("Optionnel (sinon: toutes catégories)"),
                  onTap: quiz.isLoading ? null : () => _pickFirestoreCategory(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardHubPage extends StatelessWidget {
  final String userId;
  const _LeaderboardHubPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LeaderboardEntryModel>>(
      stream: FirestoreService().streamLeaderboard(limit: 50),
      builder: (context, snap) {
        final entries = snap.data ?? const <LeaderboardEntryModel>[];
        final top = entries.isNotEmpty ? entries.first : null;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                "Classement",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                (snap.connectionState == ConnectionState.waiting)
                    ? "Chargement du classement..."
                    : (top == null
                    ? "Aucun score pour le moment."
                    : "Top actuel: ${top.userName} (${top.score}/${top.total})"),
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events),
                  title: const Text(
                    "Ouvrir le classement complet",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text("Temps réel (Firestore)."),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfilePage extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? photoUrl;

  const _ProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            "Profil",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: _UserAvatar(photoUrl: photoUrl, fallbackText: userName),
              title: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(userEmail),
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
// UI COMPONENTS
//////////////////////////////////////////////////////////////

class _QuizModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool loading;

  const _QuizModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.loading,
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
        trailing: loading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: loading ? null : onTap,
      ),
    );
  }
}

class _GradientHero extends StatelessWidget {
  final String userName;
  const _GradientHero({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: Colors.white, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Prêt à jouer, $userName ?\nLance un quiz et vise la 1ère place.",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width >= 900 ? 260 : double.infinity,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withOpacity(0.12),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String fallbackText;
  const _UserAvatar({required this.photoUrl, required this.fallbackText});

  @override
  Widget build(BuildContext context) {
    final initial =
    fallbackText.isNotEmpty ? fallbackText.trim()[0].toUpperCase() : "U";

    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey.shade200,
      foregroundImage: (photoUrl != null && photoUrl!.trim().isNotEmpty)
          ? NetworkImage(photoUrl!.trim())
          : null,
      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

//////////////////////////////////////////////////////////////
// NAV
//////////////////////////////////////////////////////////////

class _DashboardDrawer extends StatelessWidget {
  final int selectedIndex;
  final String userName;
  final String userEmail;
  final String? photoUrl;

  final void Function(int) onSelect;
  final Future<void> Function() onLogout;

  const _DashboardDrawer({
    required this.selectedIndex,
    required this.userName,
    required this.userEmail,
    required this.photoUrl,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: _UserAvatar(photoUrl: photoUrl, fallbackText: userName),
              title: Text(userName,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(
                userEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            _item(Icons.dashboard_outlined, "Aperçu", 0),
            _item(Icons.quiz_outlined, "Quiz", 1),
            _item(Icons.emoji_events_outlined, "Classement", 2),
            _item(Icons.person_outline, "Profil", 3),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Déconnexion"),
              onTap: () async => onLogout(),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: index == selectedIndex,
      onTap: () => onSelect(index),
    );
  }
}

class _DashboardRail extends StatelessWidget {
  final int selectedIndex;
  final String userName;
  final String userEmail;
  final String? photoUrl;

  final void Function(int) onSelect;
  final Future<void> Function() onLogout;

  const _DashboardRail({
    required this.selectedIndex,
    required this.userName,
    required this.userEmail,
    required this.photoUrl,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            _UserAvatar(photoUrl: photoUrl, fallbackText: userName),
            const SizedBox(height: 10),
            SizedBox(
              width: 160,
              child: Text(
                userName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(
              width: 160,
              child: Text(
                userEmail,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: IconButton(
          tooltip: "Déconnexion",
          onPressed: () async => onLogout(),
          icon: const Icon(Icons.logout),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: Text("Aperçu"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.quiz_outlined),
          label: Text("Quiz"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.emoji_events_outlined),
          label: Text("Classement"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          label: Text("Profil"),
        ),
      ],
    );
  }
}

//////////////////////////////////////////////////////////////
// SHIMMER (BOOT)
//////////////////////////////////////////////////////////////

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          shimmer.ShimmerBlock(height: 90, width: double.infinity),
          const SizedBox(height: 14),
          shimmer.ShimmerBlock(height: 90, width: double.infinity),
          const SizedBox(height: 14),
          shimmer.ShimmerBlock(height: 90, width: double.infinity),
          const SizedBox(height: 14),
          shimmer.ShimmerBlock(height: 60, width: double.infinity),
          const SizedBox(height: 10),
          shimmer.ShimmerBlock(height: 60, width: double.infinity),
        ],
      ),
    );
  }
}
