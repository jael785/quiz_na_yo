import 'dart:async';
import 'package:flutter/foundation.dart';

import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthController _controller;
  final FirestoreService _firestore;

  AuthProvider({AuthController? controller, FirestoreService? firestore})
      : _controller = controller ?? AuthController(),
        _firestore = firestore ?? FirestoreService();

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _loading;
  String? get error => _error;

  void loadSession() {
    _user = _controller.currentUserModel();
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    await _run(
          () async {
        _user = await _controller.loginWithGoogle();

        // ✅ Firestore: users/{uid} (auto-création/merge)
        if (_user != null) {
          await _firestore.upsertUser(_user!);
        }
      },
      timeout: const Duration(seconds: 45),
    );
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _run(() async {
      _user = await _controller.loginWithEmailPassword(
        email: email,
        password: password,
      );


      if (_user != null) {
        await _firestore.upsertUser(_user!);
      }
    });
  }

  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _run(() async {
      _user = await _controller.registerWithEmailPassword(
        email: email,
        password: password,
      );
      if (_user != null) {
        await _firestore.upsertUser(_user!);
      }
    });
  }

  Future<void> resetPassword(String email) async {
    await _run(() async {
      await _controller.resetPassword(email);
    });
  }

  Future<void> signOut() async {
    await _run(() async {
      await _controller.logout();
      _user = null;
    });
  }

  void forceStopLoading({String? message}) {
    _loading = false;
    _error = message ?? _error;
    notifyListeners();
  }

  Future<void> _run(
      Future<void> Function() job, {
        Duration timeout = const Duration(seconds: 25),
      }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await job().timeout(timeout);
    } on TimeoutException {
      _error = "Connexion trop longue. Réessaie (vérifie Internet).";
    } catch (e) {
      _error = _cleanError(e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _cleanError(String raw) {
    final s = raw.toLowerCase();

    if (s.contains('wrong-password') || s.contains('invalid-credential')) {
      return "Mot de passe incorrect ou compte invalide.";
    }
    if (s.contains('user-not-found')) {
      return "Aucun compte trouvé avec cet email.";
    }
    if (s.contains('invalid-email')) {
      return "Email invalide.";
    }
    if (s.contains('network-request-failed')) {
      return "Problème réseau. Vérifie ta connexion Internet.";
    }
    if (s.contains('too-many-requests')) {
      return "Trop de tentatives. Réessaie plus tard.";
    }

    // fallback générique propre (sans stack)
    return raw.replaceAll('Exception:', '').trim();
  }
}
