import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController {
  final AuthService _service;

  AuthController({AuthService? service}) : _service = service ?? AuthService();

  UserModel? currentUserModel() {
    final u = _service.getCurrentUser();
    if (u == null) return null;

    return UserModel(
      uid: u.uid,
      name: u.displayName,
      email: u.email,
      photoUrl: u.photoURL,
    );
  }

  Future<UserModel> loginWithGoogle() async {
    final cred = await _service.signInWithGoogle();
    final u = cred.user;
    if (u == null) throw StateError("User Firebase null après Google login.");

    return UserModel(uid: u.uid, name: u.displayName, email: u.email, photoUrl: u.photoURL);
  }

  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _service.signInWithEmailPassword(email: email, password: password);
    final u = cred.user;
    if (u == null) throw StateError("User Firebase null après login.");
    return UserModel(uid: u.uid, name: u.displayName, email: u.email, photoUrl: u.photoURL);
  }

  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _service.registerWithEmailPassword(email: email, password: password);
    final u = cred.user;
    if (u == null) throw StateError("User Firebase null après register.");
    return UserModel(uid: u.uid, name: u.displayName, email: u.email, photoUrl: u.photoURL);
  }

  Future<void> resetPassword(String email) => _service.sendPasswordResetEmail(email);

  Future<void> logout() => _service.signOut();
}
