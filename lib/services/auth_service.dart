import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  User? getCurrentUser() => _auth.currentUser;

 
  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({"prompt": "select_account"});
        return await _auth.signInWithPopup(provider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          // Annulation utilisateur (pas une erreur technique)
          throw AuthFailure("Connexion Google annulée.");
        }

        final googleAuth = await googleUser.authentication;

        if (googleAuth.idToken == null) {
          throw AuthFailure("Configuration Google invalide (idToken manquant).");
        }

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendlyFirebaseAuthMessage(e));
    } catch (e) {
      // Si on a déjà une AuthFailure, on la relance telle quelle
      if (e is AuthFailure) rethrow;
      throw AuthFailure("Connexion Google échouée. Réessaie.");
    }
  }

  // -------------------------
  // EMAIL/PASSWORD
  // -------------------------
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendlyFirebaseAuthMessage(e));
    } catch (_) {
      throw AuthFailure("Connexion échouée. Réessaie.");
    }
  }

  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendlyFirebaseAuthMessage(e));
    } catch (_) {
      throw AuthFailure("Création du compte échouée. Réessaie.");
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendlyFirebaseAuthMessage(e));
    } catch (_) {
      throw AuthFailure("Impossible d'envoyer l'email de réinitialisation.");
    }
  }

  // -------------------------
  // LOGOUT
  // -------------------------
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
  }

  // -------------------------
  // MESSAGES PROPRES (FR)
  // -------------------------
  String _friendlyFirebaseAuthMessage(FirebaseAuthException e) {
    // Les codes FirebaseAuth sont documentés et stables.
    // On mappe les plus courants pour un UX propre.
    switch (e.code) {
      case 'invalid-email':
        return "Email invalide.";
      case 'user-disabled':
        return "Ce compte a été désactivé.";
      case 'user-not-found':
        return "Aucun compte trouvé avec cet email.";
      case 'wrong-password':
        return "Mot de passe incorrect.";
      case 'invalid-credential':
      // Nouveau code fréquent: identifiants incorrects ou compte inexistant
        return "Identifiants incorrects. Vérifie l'email et le mot de passe.";
      case 'email-already-in-use':
        return "Cet email est déjà utilisé. Connecte-toi ou change d'email.";
      case 'operation-not-allowed':
        return "Méthode de connexion non activée dans Firebase.";
      case 'weak-password':
        return "Mot de passe trop faible (minimum 6 caractères).";
      case 'network-request-failed':
        return "Problème de connexion Internet. Réessaie.";
      case 'too-many-requests':
        return "Trop de tentatives. Réessaie plus tard.";
      case 'popup-closed-by-user':
        return "Connexion Google annulée.";
      case 'account-exists-with-different-credential':
        return "Ce compte existe déjà avec une autre méthode de connexion.";
      default:
      // On évite de montrer un message technique
        return "Authentification échouée. Réessaie.";
    }
  }
}

/// Exception applicative "propre" pour UI
class AuthFailure implements Exception {
  final String message;
  AuthFailure(this.message);

  @override
  String toString() => message;
}
