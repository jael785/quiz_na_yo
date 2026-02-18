import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../widgets/shimmer_block.dart';
import 'result_screen.dart';

// ✅ Admin guard
import '../../core/admin_config.dart';
import 'admin/admin_home_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _didStart = false;
  bool _navigatedToResult = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    // OK: stop timer/stopwatch
    context.read<QuizProvider>().disposeQuiz();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    // =========================================================
    // ✅ GARDE-FOU ADMIN : l'admin ne doit jamais jouer
    // =========================================================
    final auth = context.watch<AuthProvider>();
    final u = auth.user;

    if (u != null && AdminConfig.isAdmin(u.uid)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
              (_) => false,
        );
      });

      return const Scaffold(
        backgroundColor: Color(0xFFF4F6FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Démarrage 1 seule fois (et seulement si nécessaire)
    if (!_didStart) {
      _didStart = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final qp = context.read<QuizProvider>();

        // IMPORTANT: si HomeScreen a déjà lancé startXxxQuiz(),
        // alors questions ne seront pas vides.
        if (!qp.isLoading && qp.questions.isEmpty) {
          await qp.startApiQuiz();
        }

        final err = qp.error;
        if (err != null) _snack(err);
      });
    }

    // ✅ Loading -> Shimmer
    if (quiz.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        appBar: AppBar(
          title: const Text("Quiz Na Yo"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              ShimmerBlock(height: 24, width: 220),
              SizedBox(height: 12),
              ShimmerBlock(height: 90, width: double.infinity),
              SizedBox(height: 18),
              ShimmerBlock(height: 54, width: double.infinity),
              SizedBox(height: 10),
              ShimmerBlock(height: 54, width: double.infinity),
              SizedBox(height: 10),
              ShimmerBlock(height: 54, width: double.infinity),
              SizedBox(height: 10),
              ShimmerBlock(height: 54, width: double.infinity),
            ],
          ),
        ),
      );
    }

    // ✅ Erreur API (pas d'écran blanc)
    if (quiz.error != null && quiz.current == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        appBar: AppBar(
          title: const Text("Quiz Na Yo"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 44),
                const SizedBox(height: 10),
                Text(
                  quiz.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await context.read<QuizProvider>().startApiQuiz();
                    final err = context.read<QuizProvider>().error;
                    if (err != null) _snack(err);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Réessayer"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ FIN: naviguer vers ResultScreen (au lieu d'afficher "Quiz terminé.")
    if ((quiz.current == null || quiz.index >= quiz.total) && !_navigatedToResult) {
      _navigatedToResult = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final qp = context.read<QuizProvider>();
        final auth = context.read<AuthProvider>();
        final u = auth.user;

        if (u == null) {
          _snack("Session expirée. Reconnecte-toi.");
          Navigator.of(context).pop();
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              score: qp.score,
              total: qp.total,
              durationSeconds: qp.elapsedSeconds,
              userId: u.uid,
              userName: u.name ?? u.email ?? "Utilisateur",
              photoUrl: u.photoUrl,
            ),
          ),
        );
      });

      // petite page neutre pendant le frame
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Ici on est sûr d’avoir une question
    final q = quiz.current!;
    final progress = (quiz.total == 0) ? 0.0 : ((quiz.index + 1) / quiz.total);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Quiz Na Yo"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(value: progress),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, anim) {
            final fade = FadeTransition(opacity: anim, child: child);
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(anim),
              child: fade,
            );
          },
          child: _QuestionView(
            // ✅ key safe (ne dépend pas de q.id)
            key: ValueKey("q_${quiz.index}"),
            questionTitle: q.question,
            category: q.category,
            options: q.options,
            correctIndex: q.correctIndex,
            explanation: q.explanation,
            selectedIndex: quiz.selectedIndex,
            hasAnswered: quiz.hasAnswered,
            remainingSeconds: quiz.remainingSeconds,
            index: quiz.index,
            total: quiz.total,
            onPick: (i) => context.read<QuizProvider>().chooseAnswer(i),
            onNext: () => _handleNext(context),
          ),
        ),
      ),
    );
  }

  void _handleNext(BuildContext context) {
    final qp = context.read<QuizProvider>();

    // ✅ si tu veux forcer réponse obligatoire, garde ça.
    // Sinon, tu peux retirer et autoriser "skip".
    if (!qp.hasAnswered) {
      _snack("Choisis une réponse d'abord.");
      return;
    }

    qp.next();

    // ⚠️ Plus besoin de naviguer ici obligatoirement,
    // car on a la navigation auto dans build() quand quiz fini.
  }
}

class _QuestionView extends StatelessWidget {
  final String questionTitle;
  final String category;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  final int? selectedIndex;
  final bool hasAnswered;

  final int remainingSeconds;
  final int index;
  final int total;

  final void Function(int) onPick;
  final VoidCallback onNext;

  const _QuestionView({
    super.key,
    required this.questionTitle,
    required this.category,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.selectedIndex,
    required this.hasAnswered,
    required this.remainingSeconds,
    required this.index,
    required this.total,
    required this.onPick,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final danger = remainingSeconds <= 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Question ${index + 1}/$total",
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Chip(
              label: Text("$remainingSeconds s"),
              avatar: Icon(danger ? Icons.timer_off : Icons.timer),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          category,
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              questionTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final text = options[i];

              final isSelected = selectedIndex == i;
              final isCorrect = i == correctIndex;

              Color? bg;
              Color border = Colors.grey.shade300;

              if (hasAnswered) {
                if (isCorrect) {
                  bg = Colors.green.withOpacity(0.12);
                  border = Colors.green.withOpacity(0.35);
                }
                if (isSelected && !isCorrect) {
                  bg = Colors.red.withOpacity(0.12);
                  border = Colors.red.withOpacity(0.35);
                }
              }

              return InkWell(
                onTap: hasAnswered ? null : () => onPick(i),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: bg ?? Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasAnswered
                            ? (isCorrect
                            ? Icons.check_circle
                            : (isSelected ? Icons.cancel : Icons.circle_outlined))
                            : Icons.circle_outlined,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        if (hasAnswered)
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "💡 $explanation",
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: FilledButton(
            onPressed: hasAnswered ? onNext : null,
            child: Text(index + 1 == total ? "Terminer" : "Suivant"),
          ),
        ),
      ],
    );
  }
}
