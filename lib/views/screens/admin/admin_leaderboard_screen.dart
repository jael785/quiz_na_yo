import 'package:flutter/material.dart';

import '../../../services/firestore_service.dart';
import '../../../models/leaderboard_entry_model.dart';

class AdminLeaderboardScreen extends StatelessWidget {
  const AdminLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: const Text("Classement (Admin)")),
      body: StreamBuilder<List<LeaderboardEntryModel>>(
        stream: fs.streamLeaderboard(limit: 200),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorBox(message: snap.error.toString());
          }

          final list = snap.data ?? const <LeaderboardEntryModel>[];
          if (list.isEmpty) {
            return const _EmptyBox(
              title: "Aucun score",
              subtitle: "Les scores apparaissent après submitResult().",
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final e = list[i];
              final rank = i + 1;
              final score = "${e.score}/${e.total}";
              final time = "${e.durationSeconds}s";

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF4F6FB),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      "#$rank",
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  title: Text(e.userName, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text("UID: ${e.userId}\nScore: $score • Durée: $time"),
                  isThreeLine: true,
                  trailing: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    foregroundImage: (e.photoUrl != null && e.photoUrl!.trim().isNotEmpty)
                        ? NetworkImage(e.photoUrl!.trim())
                        : null,
                    child: Text(e.userName.isNotEmpty ? e.userName[0].toUpperCase() : "U"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

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
                const Text("Erreur Firestore", style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyBox({required this.title, required this.subtitle});

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
                const Icon(Icons.emoji_events_outlined, size: 36),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(subtitle, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
