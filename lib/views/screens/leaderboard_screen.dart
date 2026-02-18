import 'package:flutter/material.dart';

import '../../models/leaderboard_entry_model.dart';
import '../../services/firestore_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text("Classement"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: _LiveChip()),
          ),
        ],
      ),
      body: StreamBuilder<List<LeaderboardEntryModel>>(
        stream: FirestoreService().streamLeaderboard(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString());
          }

          final entries = snapshot.data ?? const <LeaderboardEntryModel>[];
          final top3 = entries.take(3).toList();
          final rest = entries.length > 3 ? entries.sublist(3) : <LeaderboardEntryModel>[];

          return LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 900;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? Row(
                  children: [
                    Expanded(flex: 4, child: _Top3Panel(top3: top3)),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: _ListPanel(rest: rest, emptyAll: entries.isEmpty),
                    ),
                  ],
                )
                    : ListView(
                  children: [
                    _Top3Panel(top3: top3),
                    const SizedBox(height: 16),
                    _ListPanel(rest: rest, emptyAll: entries.isEmpty),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Petit badge "LIVE"
class _LiveChip extends StatelessWidget {
  const _LiveChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF22C55E).withOpacity(0.12),
        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: Color(0xFF22C55E)),
          SizedBox(width: 6),
          Text(
            "LIVE",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 36),
                const SizedBox(height: 10),
                const Text(
                  "Erreur Firestore",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ----------------------------
/// TOP 3 PANEL
/// ----------------------------
class _Top3Panel extends StatelessWidget {
  final List<LeaderboardEntryModel> top3;
  const _Top3Panel({required this.top3});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Top 3",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              top3.isEmpty ? "Aucun score pour le moment." : "Les meilleurs joueurs actuels.",
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            if (top3.isEmpty)
              _emptyTop3()
            else
              Column(
                children: [
                  if (top3.length >= 1) _TopCard(rank: 1, entry: top3[0], badgeLabel: "OR", badgeIcon: Icons.emoji_events),
                  if (top3.length >= 2) const SizedBox(height: 10),
                  if (top3.length >= 2) _TopCard(rank: 2, entry: top3[1], badgeLabel: "ARGENT", badgeIcon: Icons.emoji_events_outlined),
                  if (top3.length >= 3) const SizedBox(height: 10),
                  if (top3.length >= 3) _TopCard(rank: 3, entry: top3[2], badgeLabel: "BRONZE", badgeIcon: Icons.workspace_premium_outlined),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTop3() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF4F6FB),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Text("Joue un quiz et clique “Ajouter au classement”."),
    );
  }
}

class _TopCard extends StatelessWidget {
  final int rank;
  final LeaderboardEntryModel entry;
  final String badgeLabel;
  final IconData badgeIcon;

  const _TopCard({
    required this.rank,
    required this.entry,
    required this.badgeLabel,
    required this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final title = entry.userName;
    final scoreText = "${entry.score}/${entry.total}";
    final timeText = "${entry.durationSeconds}s";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF8FAFF),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _RankBadge(rank: rank, label: badgeLabel, icon: badgeIcon),
          const SizedBox(width: 12),
          _Avatar(photoUrl: entry.photoUrl, fallbackText: title),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text("Score: $scoreText • Durée: $timeText",
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final String label;
  final IconData icon;

  const _RankBadge({
    required this.rank,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color accent;
    if (rank == 1) {
      accent = const Color(0xFFDAA520);
    } else if (rank == 2) {
      accent = const Color(0xFF94A3B8);
    } else {
      accent = const Color(0xFFB87333);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accent.withOpacity(0.12),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 6),
          Text("#$rank $label", style: TextStyle(fontWeight: FontWeight.w900, color: accent)),
        ],
      ),
    );
  }
}

/// ----------------------------
/// LIST PANEL
/// ----------------------------
class _ListPanel extends StatelessWidget {
  final List<LeaderboardEntryModel> rest;
  final bool emptyAll;

  const _ListPanel({required this.rest, required this.emptyAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Classement complet",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(emptyAll ? "Aucun score." : "Tous les joueurs",
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
            const SizedBox(height: 12),
            if (emptyAll)
              _emptyList()
            else if (rest.isEmpty)
              _onlyTop3Hint()
            else
              Expanded(
                child: ListView.separated(
                  itemCount: rest.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200),
                  itemBuilder: (context, i) {
                    final e = rest[i];
                    final rank = i + 4;

                    return ListTile(
                      leading: Container(
                        width: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF4F6FB),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text("#$rank",
                            style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      title: Row(
                        children: [
                          _Avatar(photoUrl: e.photoUrl, fallbackText: e.userName),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text("Score ${e.score}/${e.total} • ${e.durationSeconds}s"),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF4F6FB),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Text("Joue un quiz puis clique “Ajouter au classement”."),
    );
  }

  Widget _onlyTop3Hint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF4F6FB),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Text("Il n’y a que 3 joueurs pour le moment."),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String fallbackText;

  const _Avatar({required this.photoUrl, required this.fallbackText});

  @override
  Widget build(BuildContext context) {
    final initial = fallbackText.trim().isNotEmpty ? fallbackText.trim()[0].toUpperCase() : "U";
    final url = (photoUrl ?? '').trim();

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey.shade200,
      foregroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}
