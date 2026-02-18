import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle unique côté App (pour UI + Firestore)
class LeaderboardEntryModel {
  final String userId;
  final String userName;
  final String? photoUrl;

  final int score; // points (score d'une partie OU bestScore si depuis leaderboard)
  final int total;
  final int durationSeconds;

  final DateTime createdAt;

  const LeaderboardEntryModel({
    required this.userId,
    required this.userName,
    required this.photoUrl,
    required this.score,
    required this.total,
    required this.durationSeconds,
    required this.createdAt,
  });

  double get percent => total == 0 ? 0.0 : (score / total);

  /// Écriture dans scores/{autoId} (historique)
  Map<String, dynamic> toScoreMap() {
    return {
      'userId': userId,
      'userName': userName,
      'photoUrl': photoUrl ?? '',
      'score': score,
      'total': total,
      'durationSeconds': durationSeconds,
      'percent': percent,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Lecture depuis leaderboard/{uid} (best unique)
  /// On remappe bestScore -> score, bestTotal -> total, bestDurationSeconds -> durationSeconds
  factory LeaderboardEntryModel.fromBestDoc(Map<String, dynamic> data) {
    final ts = data['updatedAt'] ?? data['createdAt'];
    DateTime dt = DateTime.now();
    if (ts is Timestamp) dt = ts.toDate();

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse((v ?? '').toString()) ?? 0;
    }

    final userId = (data['userId'] ?? '').toString();

    return LeaderboardEntryModel(
      userId: userId,
      userName: (data['userName'] ?? 'Utilisateur').toString(),
      photoUrl: (data['photoUrl'] ?? '').toString().trim().isEmpty
          ? null
          : (data['photoUrl'] ?? '').toString(),
      score: asInt(data['bestScore']),
      total: asInt(data['bestTotal']),
      durationSeconds: asInt(data['bestDurationSeconds']),
      createdAt: dt,
    );
  }
}
