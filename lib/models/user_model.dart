/// Modèle utilisateur minimal pour l'app (Firestore viendra après)
class UserModel {
  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;

  const UserModel({
    required this.uid,
    this.name,
    this.email,
    this.photoUrl,
  });

  /// Construction depuis un user Firebase
  factory UserModel.fromFirebase({
    required String uid,
    String? name,
    String? email,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      photoUrl: photoUrl,
    );
  }
}
