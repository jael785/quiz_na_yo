import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/leaderboard_entry_model.dart';
import '../models/question_model.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _scores => _db.collection('scores');
  CollectionReference<Map<String, dynamic>> get _leaderboard => _db.collection('leaderboard');
  CollectionReference<Map<String, dynamic>> get _questions => _db.collection('questions');
  CollectionReference<Map<String, dynamic>> get _categories => _db.collection('categories');

  
  Future<void> upsertUser(UserModel user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    final exists = snap.exists;

    final payload = <String, dynamic>{
      'uid': user.uid,
      'name': user.name ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoUrl ?? '',
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    if (!exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(payload, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> streamUsers({int limit = 200}) {
    return _users
        .orderBy('lastLoginAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ---------------------------------------------------------------------------
  // SCORES (HISTORIQUE)
  // ---------------------------------------------------------------------------
  Future<void> addScore(LeaderboardEntryModel entry) async {
    await _scores.add(entry.toScoreMap());
  }

  // ---------------------------------------------------------------------------
  // LEADERBOARD (BEST UNIQUE)
  // ---------------------------------------------------------------------------
  Future<void> upsertLeaderboardBest(LeaderboardEntryModel entry) async {
    final ref = _leaderboard.doc(entry.userId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      final newScore = entry.score;
      final newTotal = entry.total;
      final newDur = entry.durationSeconds;
      final newPercent = newTotal == 0 ? 0.0 : (newScore / newTotal);

      if (!snap.exists) {
        tx.set(ref, {
          'userId': entry.userId,
          'userName': entry.userName,
          'photoUrl': entry.photoUrl ?? '',
          'bestScore': newScore,
          'bestTotal': newTotal,
          'bestDurationSeconds': newDur,
          'bestPercent': newPercent,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }

      final data = snap.data() as Map<String, dynamic>;
      final oldScore = _asInt(data['bestScore']);
      final oldDur = _asInt(data['bestDurationSeconds']);

      final isBetter =
          (newScore > oldScore) || (newScore == oldScore && newDur < oldDur);

      if (isBetter) {
        tx.set(ref, {
          'userId': entry.userId,
          'userName': entry.userName,
          'photoUrl': entry.photoUrl ?? '',
          'bestScore': newScore,
          'bestTotal': newTotal,
          'bestDurationSeconds': newDur,
          'bestPercent': newPercent,
          'updatedAt': FieldValue.serverTimestamp(),
          if (data['createdAt'] == null) 'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        tx.set(ref, {
          'userName': entry.userName,
          'photoUrl': entry.photoUrl ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
          if (data['createdAt'] == null) 'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Stream<List<LeaderboardEntryModel>> streamLeaderboard({int limit = 50}) {
    return _leaderboard
        .orderBy('bestScore', descending: true)
        .orderBy('bestDurationSeconds', descending: false)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        return LeaderboardEntryModel.fromBestDoc(data);
      }).toList();
    });
  }

  Stream<int> streamTotalQuizzesCount() {
    return _scores.snapshots().map((snap) => snap.size);
  }

  Stream<Map<String, int>?> streamBestScoreForUser(String uid) {
    return _leaderboard.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return {
        'score': _asInt(data['bestScore']),
        'total': _asInt(data['bestTotal']),
      };
    });
  }

  Stream<int?> streamUserPosition(String uid, {int scanLimit = 200}) {
    return _leaderboard
        .orderBy('bestScore', descending: true)
        .orderBy('bestDurationSeconds', descending: false)
        .orderBy('updatedAt', descending: true)
        .limit(scanLimit)
        .snapshots()
        .map((snap) {
      for (int i = 0; i < snap.docs.length; i++) {
        final data = snap.docs[i].data();
        if ((data['userId'] ?? '').toString() == uid) return i + 1;
      }
      return null;
    });
  }

  Future<void> submitResult(LeaderboardEntryModel entry) async {
    await addScore(entry);
    await upsertLeaderboardBest(entry);
  }


  Stream<List<Map<String, dynamic>>> streamCategories() {
    return _categories
        .orderBy('name', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> upsertCategory({
    required String id,
    required String name,
    required bool active,
  }) async {
    final ref = _categories.doc(id);
    final snap = await ref.get();
    final exists = snap.exists;

    await ref.set({
      'name': name.trim(),
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete();
  }

  // ---------------------------------------------------------------------------
  // ✅ USER: CATEGORIES visibles (actives)
  // ---------------------------------------------------------------------------
  /// IMPORTANT:
  /// - Certains anciens docs peuvent ne pas avoir "active"
  /// - Donc on fait un fallback: (active ?? true)
  Stream<List<Map<String, dynamic>>> streamActiveCategories() {
    return _categories
        .orderBy('name', descending: false)
        .snapshots()
        .map((snap) {
      final out = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = d.data();
        final isActive = (data['active'] ?? true) as bool;
        if (!isActive) continue;
        out.add({'id': d.id, ...data});
      }
      return out;
    });
  }

  Future<List<Map<String, dynamic>>> fetchActiveCategories() async {
    final snap = await _categories.orderBy('name', descending: false).get();
    final out = <Map<String, dynamic>>[];
    for (final d in snap.docs) {
      final data = d.data();
      final isActive = (data['active'] ?? true) as bool;
      if (!isActive) continue;
      out.add({'id': d.id, ...data});
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // ADMIN CRUD: QUESTIONS
  // ---------------------------------------------------------------------------
  Stream<List<Map<String, dynamic>>> streamQuestions({int limit = 300}) {
    return _questions
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> addQuestion({
    required String categoryId,
    required String categoryName,
    required String question,
    required List<String> options,
    required int correctIndex,
    required String explanation,
    String difficulty = "easy",
    bool active = true,
  }) async {
    await _questions.add({
      'categoryId': categoryId,
      'categoryName': categoryName,
      'question': question.trim(),
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation.trim(),
      'difficulty': difficulty,
      'active': active,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateQuestion({
    required String id,
    required String categoryId,
    required String categoryName,
    required String question,
    required List<String> options,
    required int correctIndex,
    required String explanation,
    String difficulty = "easy",
    bool active = true,
  }) async {
    await _questions.doc(id).set({
      'categoryId': categoryId,
      'categoryName': categoryName,
      'question': question.trim(),
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation.trim(),
      'difficulty': difficulty,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteQuestion(String id) async {
    await _questions.doc(id).delete();
  }

  // ---------------------------------------------------------------------------
  // ✅ USER QUIZ: lire les questions créées par l'admin
  // ---------------------------------------------------------------------------
  Future<List<QuestionModel>> fetchActiveQuestions({
    int limit = 30,
    String? categoryId,
    String? difficulty,
  }) async {
    // ⚠️ Problème classique : si certains docs n'ont pas "active",
    // where(active==true) retourne 0 résultats pour ces docs.
    // -> On garde ta logique, mais on la rend robuste:
    //    On n'utilise PAS where('active'==true) et on filtre côté client.
    Query<Map<String, dynamic>> q = _questions;

    if (categoryId != null && categoryId.trim().isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId.trim());
    }

    if (difficulty != null && difficulty.trim().isNotEmpty) {
      q = q.where('difficulty', isEqualTo: difficulty.trim());
    }

    // Tri + limit
    q = q.orderBy('updatedAt', descending: true).limit(limit);

    final snap = await q.get();
    final out = <QuestionModel>[];

    for (final doc in snap.docs) {
      final data = doc.data();

      // ✅ fallback si champ absent
      final isActive = (data['active'] ?? true) as bool;
      if (!isActive) continue;

      out.add(
        QuestionModel.fromFirestore(
          docId: doc.id,
          data: data,
        ),
      );
    }

    return out;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
