import 'package:flutter/material.dart';

import '../../../services/firestore_service.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text("Catégories (CRUD)"),
        actions: [
          IconButton(
            tooltip: "Ajouter",
            icon: const Icon(Icons.add),
            onPressed: () async {
              await _openCategoryDialog(context, fs);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fs.streamCategories(),
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
              title: "Aucune catégorie",
              subtitle: "Clique sur + pour créer une catégorie.",
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = list[i];
              final id = (c['id'] ?? '').toString();
              final name = (c['name'] ?? '').toString();
              final active = (c['active'] == true);

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: Icon(
                    active ? Icons.check_circle_outline : Icons.pause_circle_outline,
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text("id: $id"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await _openCategoryDialog(
                          context,
                          fs,
                          id: id,
                          initialName: name,
                          initialActive: active,
                        );
                      } else if (v == 'toggle') {
                        await fs.upsertCategory(
                          id: id,
                          name: name,
                          active: !active,
                        );
                      } else if (v == 'delete') {
                        final ok = await _confirm(
                          context,
                          title: "Supprimer",
                          message: "Supprimer la catégorie “$name” ?",
                        );
                        if (ok) {
                          await fs.deleteCategory(id);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text("Modifier")),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(active ? "Désactiver" : "Activer"),
                      ),
                      const PopupMenuItem(value: 'delete', child: Text("Supprimer")),
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

Future<void> _openCategoryDialog(
    BuildContext context,
    FirestoreService fs, {
      String? id,
      String? initialName,
      bool initialActive = true,
    }) async {
  final nameCtrl = TextEditingController(text: initialName ?? '');
  bool active = initialActive;

  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(id == null ? "Nouvelle catégorie" : "Modifier catégorie"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Nom",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return "Nom requis";
                  if (s.length < 2) return "Nom trop court";
                  return null;
                },
              ),
              const SizedBox(height: 12),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final name = nameCtrl.text.trim();
              final finalId = (id == null || id.trim().isEmpty)
                  ? _slug(name)
                  : id.trim();

              await fs.upsertCategory(
                id: finalId,
                name: name,
                active: active,
              );

              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text("Enregistrer"),
          ),
        ],
      );
    },
  );
}

String _slug(String s) {
  final out = s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  return out.isEmpty ? "cat_${DateTime.now().millisecondsSinceEpoch}" : out;
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
                const Icon(Icons.category_outlined, size: 36),
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
