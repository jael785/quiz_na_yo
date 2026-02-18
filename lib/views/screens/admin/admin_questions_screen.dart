import 'package:flutter/material.dart';

import '../../../services/firestore_service.dart';

class AdminQuestionsScreen extends StatelessWidget {
  const AdminQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text("Questions (CRUD)"),
        actions: [
          IconButton(
            tooltip: "Ajouter",
            icon: const Icon(Icons.add),
            onPressed: () async {
              await _openQuestionDialog(context, fs);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fs.streamQuestions(limit: 300),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorBox(message: snap.error.toString());
          }

          final list = snap.data ?? const <Map<String, dynamic>>[];
          if (list.isEmpty) {
            return const _EmptyBox(
              title: "Aucune question",
              subtitle: "Clique sur + pour créer une question.",
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final q = list[i];

              final id = (q['id'] ?? '').toString();
              final question = (q['question'] ?? '').toString();
              final categoryName = (q['categoryName'] ?? '').toString();
              final difficulty = (q['difficulty'] ?? 'easy').toString();
              final active = (q['active'] == true);

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: Icon(active ? Icons.check_circle_outline : Icons.pause_circle_outline),
                  title: Text(
                    question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text("Cat: $categoryName • $difficulty\nid: $id"),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await _openQuestionDialog(
                          context,
                          fs,
                          existing: q,
                        );
                      } else if (v == 'delete') {
                        final ok = await _confirm(
                          context,
                          title: "Supprimer",
                          message: "Supprimer cette question ?",
                        );
                        if (ok) {
                          await fs.deleteQuestion(id);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text("Modifier")),
                      PopupMenuItem(value: 'delete', child: Text("Supprimer")),
                    ],
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

Future<void> _openQuestionDialog(
    BuildContext context,
    FirestoreService fs, {
      Map<String, dynamic>? existing,
    }) async {
  final formKey = GlobalKey<FormState>();

  // Champs
  final questionCtrl = TextEditingController(text: (existing?['question'] ?? '').toString());
  final explanationCtrl =
  TextEditingController(text: (existing?['explanation'] ?? '').toString());

  // Options (4)
  List<String> opts = [];
  final rawOpts = existing?['options'];
  if (rawOpts is List) {
    opts = rawOpts.map((e) => (e ?? '').toString()).toList();
  }
  while (opts.length < 4) {
    opts.add("");
  }
  if (opts.length > 4) {
    opts = opts.take(4).toList();
  }

  final optCtrls = List.generate(4, (i) => TextEditingController(text: opts[i]));

  int correctIndex = 0;
  final rawCi = existing?['correctIndex'];
  if (rawCi is int) correctIndex = rawCi;
  if (correctIndex < 0) correctIndex = 0;
  if (correctIndex > 3) correctIndex = 3;

  bool active = (existing?['active'] == true);
  String difficulty = (existing?['difficulty'] ?? 'easy').toString();
  String? categoryId = (existing?['categoryId'] ?? '').toString().trim();
  String? categoryName = (existing?['categoryName'] ?? '').toString().trim();

  // Charger catégories pour dropdown
  final cats = await fs.streamCategories().first;

  // Si aucune catégorie, on bloque (sinon tu vas écrire une question invalide)
  if (cats.isEmpty) {
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Catégories manquantes"),
          content: const Text("Crée d’abord une catégorie dans Catégories (CRUD)."),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
    return;
  }

  // Si pas encore choisi, on prend la 1ère
  if (categoryId == null || categoryId.isEmpty) {
    categoryId = (cats.first['id'] ?? '').toString();
    categoryName = (cats.first['name'] ?? '').toString();
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(existing == null ? "Nouvelle question" : "Modifier question"),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  // Catégorie
                  DropdownButtonFormField<String>(
                    value: categoryId,
                    decoration: const InputDecoration(
                      labelText: "Catégorie",
                      border: OutlineInputBorder(),
                    ),
                    items: cats.map((c) {
                      final id = (c['id'] ?? '').toString();
                      final name = (c['name'] ?? '').toString();
                      return DropdownMenuItem(
                        value: id,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      categoryId = v;
                      final found = cats.firstWhere((c) => (c['id'] ?? '').toString() == v);
                      categoryName = (found['name'] ?? '').toString();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Difficulty
                  DropdownButtonFormField<String>(
                    value: difficulty,
                    decoration: const InputDecoration(
                      labelText: "Difficulté",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text("easy")),
                      DropdownMenuItem(value: 'medium', child: Text("medium")),
                      DropdownMenuItem(value: 'hard', child: Text("hard")),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      difficulty = v;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Question
                  TextFormField(
                    controller: questionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Question",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return "Question requise";
                      if (s.length < 5) return "Question trop courte";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Options
                  for (int i = 0; i < 4; i++) ...[
                    TextFormField(
                      controller: optCtrls[i],
                      decoration: InputDecoration(
                        labelText: "Option ${i + 1}",
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return "Option ${i + 1} requise";
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Correct index
                  DropdownButtonFormField<int>(
                    value: correctIndex,
                    decoration: const InputDecoration(
                      labelText: "Bonne réponse",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text("Option 1")),
                      DropdownMenuItem(value: 1, child: Text("Option 2")),
                      DropdownMenuItem(value: 2, child: Text("Option 3")),
                      DropdownMenuItem(value: 3, child: Text("Option 4")),
                    ],
                    onChanged: (v) => correctIndex = v ?? 0,
                  ),
                  const SizedBox(height: 12),

                  // Explanation
                  TextFormField(
                    controller: explanationCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Explication",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Active
                  StatefulBuilder(
                    builder: (context, setState) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Active"),
                        value: active,
                        onChanged: (v) => setState(() => active = v),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final options = optCtrls.map((c) => c.text.trim()).toList();

              // garde-fou: pas de doublons vides
              if (options.toSet().length != options.length) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Options dupliquées. Corrige-les.")),
                );
                return;
              }

              final qText = questionCtrl.text.trim();
              final exp = explanationCtrl.text.trim();

              // add ou update
              if (existing == null) {
                await fs.addQuestion(
                  categoryId: categoryId!,
                  categoryName: categoryName ?? "",
                  question: qText,
                  options: options,
                  correctIndex: correctIndex,
                  explanation: exp,
                  difficulty: difficulty,
                  active: active,
                );
              } else {
                final id = (existing['id'] ?? '').toString();
                await fs.updateQuestion(
                  id: id,
                  categoryId: categoryId!,
                  categoryName: categoryName ?? "",
                  question: qText,
                  options: options,
                  correctIndex: correctIndex,
                  explanation: exp,
                  difficulty: difficulty,
                  active: active,
                );
              }

              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text("Enregistrer"),
          ),
        ],
      );
    },
  );

  // cleanup controllers
  questionCtrl.dispose();
  explanationCtrl.dispose();
  for (final c in optCtrls) {
    c.dispose();
  }
}

Future<bool> _confirm(
    BuildContext context, {
      required String title,
      required String message,
    }) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Non")),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Oui")),
      ],
    ),
  );
  return res == true;
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
                const Icon(Icons.help_outline, size: 36),
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
