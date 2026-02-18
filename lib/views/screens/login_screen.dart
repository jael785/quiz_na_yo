import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_button/sign_in_button.dart';

import '../../providers/auth_provider.dart';
import '../widgets/loading_overlay.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  // ✅ Couleur principale (propre, lisible)
  static const Color _primary = Color(0xFF2563EB); // bleu moderne
  static const Color _bg = Color(0xFFF4F6FB);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _goHomeIfOk() async {
    final auth = context.read<AuthProvider>();

    if (auth.error != null) {
      _snack(auth.error!);
      return;
    }

    if (auth.user != null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return LoadingOverlay(
      isLoading: auth.isLoading,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 18),

                    // ✅ Logo seul
                    Image.asset(
                      'assets/images/quiz_na_yo_logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 14),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Se connecter ou créer un compte",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Connecte-toi avec ton email, ou utilise Google.",
                                  style: TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 16),

                                // ✅ Email/Password
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _emailCtrl,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          labelText: 'Adresse email',
                                          hintText: 'Ex: jean@gmail.com',
                                          prefixIcon: Icon(Icons.email_outlined),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (v) {
                                          final s = (v ?? '').trim();
                                          if (s.isEmpty) return 'Email requis';
                                          if (!s.contains('@')) return 'Email invalide';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _passCtrl,
                                        obscureText: _obscure,
                                        decoration: InputDecoration(
                                          labelText: 'Mot de passe',
                                          hintText: 'Ton mot de passe',
                                          prefixIcon: const Icon(Icons.lock_outline),
                                          border: const OutlineInputBorder(),
                                          suffixIcon: IconButton(
                                            onPressed: () =>
                                                setState(() => _obscure = !_obscure),
                                            icon: Icon(
                                              _obscure
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                          ),
                                        ),
                                        validator: (v) {
                                          final s = v ?? '';
                                          if (s.isEmpty) return 'Mot de passe requis';
                                          if (s.length < 6) return 'Minimum 6 caractères';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),

                                      // ✅ Bouton principal
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: _primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                          ),
                                          onPressed: auth.isLoading
                                              ? null
                                              : () async {
                                            if (!_formKey.currentState!.validate()) return;

                                            await context
                                                .read<AuthProvider>()
                                                .signInWithEmailPassword(
                                              email: _emailCtrl.text.trim(),
                                              password: _passCtrl.text,
                                            );

                                            await _goHomeIfOk();
                                          },
                                          child: const Text(
                                            'Continuer avec email',
                                            style: TextStyle(fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: auth.isLoading
                                              ? null
                                              : () async {
                                            final email = _emailCtrl.text.trim();
                                            if (email.isEmpty) {
                                              _snack(
                                                "Entre ton email puis clique sur “Mot de passe oublié ?”.",
                                              );
                                              return;
                                            }

                                            await context
                                                .read<AuthProvider>()
                                                .resetPassword(email);

                                            final err = context.read<AuthProvider>().error;
                                            if (err != null) {
                                              _snack(err);
                                            } else {
                                              _snack("Email de réinitialisation envoyé.");
                                            }
                                          },
                                          child: const Text('Mot de passe oublié ?'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // ✅ Séparateur
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        "ou utiliser cette option",
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // ✅ Google uniquement (carré) - sans mini (évite l'assert)
                                _GoogleSquareButton(
                                  isLoading: auth.isLoading,
                                  onTap: () async {
                                    if (auth.isLoading) return;
                                    await context.read<AuthProvider>().signInWithGoogle();
                                    await _goHomeIfOk();
                                  },
                                ),

                                const SizedBox(height: 14),

                                // ✅ Créer un compte
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Pas de compte ? "),
                                    TextButton(
                                      onPressed: auth.isLoading
                                          ? null
                                          : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const RegisterScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text("Créer un compte"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text(
                      "Quiz Na Yo • 2026",
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSquareButton extends StatelessWidget {
  final bool isLoading;
  final Future<void> Function() onTap;

  const _GoogleSquareButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: isLoading ? 0.6 : 1.0,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoading ? null : () => onTap(),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            alignment: Alignment.center,

            // ✅ SignInButton sans mini: true (sinon assertion sur Buttons.google)
            child: IgnorePointer(
              child: SignInButton(
                Buttons.google,
                text: "", // pas de texte
                onPressed: () {},
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
