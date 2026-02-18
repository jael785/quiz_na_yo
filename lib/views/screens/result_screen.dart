import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/leaderboard_entry_model.dart';
import '../../providers/quiz_provider.dart';
import '../../services/firestore_service.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int total;
  final int durationSeconds;

  final String userId;
  final String userName;
  final String? photoUrl;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.durationSeconds,
    required this.userId,
    required this.userName,
    required this.photoUrl,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _saving = false;
  bool _saved = false; // ✅ empêche double envoi (double clic / refresh)

  /// Affiche un SnackBar sans crasher si l'écran est déjà démonté
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  /// Format % score
  String _formatPercent() {
    if (widget.total == 0) return "0%";
    final p = (widget.score / widget.total) * 100;
    return "${p.toStringAsFixed(0)}%";
  }

  @override
  Widget build(BuildContext context) {
    final percent = widget.total == 0 ? 0.0 : (widget.score / widget.total);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text("Résultat"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ----------------------------
            // Résumé score
            // ----------------------------
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Bravo ${widget.userName}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Score: ${widget.score} / ${widget.total}  •  ${_formatPercent()}",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(value: percent),
                    ),
                    const SizedBox(height: 10),
                    Text("Durée: ${widget.durationSeconds}s"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ----------------------------
            // ✅ Enregistrer au classement (Solution A)
            // scores/ (historique) + leaderboard/{uid} (best unique)
            // ----------------------------
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_saving || _saved) ? null : _submitResult,
                icon: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _saved
                      ? "Déjà enregistré"
                      : (_saving ? "Enregistrement..." : "Ajouter au classement"),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ----------------------------
            // Actions
            // ----------------------------
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Rejouer: stop timer + reset local state
                      context.read<QuizProvider>().disposeQuiz();

                      // Remplace l'écran résultat par le quiz
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const QuizScreen()),
                      );
                    },
                    child: const Text("Rejouer"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Retour dashboard (reset stack)
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (_) => false,
                      );
                    },
                    child: const Text("Dashboard"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Enregistre le résultat dans Firestore (Solution A)
  Future<void> _submitResult() async {
    setState(() => _saving = true);

    // 1) Prépare l'entrée
    final entry = LeaderboardEntryModel(
      userId: widget.userId,
      userName: widget.userName,
      photoUrl: widget.photoUrl,
      score: widget.score,
      total: widget.total,
      durationSeconds: widget.durationSeconds,
      createdAt: DateTime.now(),
    );

    try {
      // 2) ✅ Un seul appel : écrit l'historique + met à jour le best unique
      await FirestoreService().submitResult(entry);

      if (!mounted) return;
      setState(() => _saved = true);

      _snack("Résultat ajouté au classement (Firestore).");
    } catch (e) {
      _snack("Erreur Firestore: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
