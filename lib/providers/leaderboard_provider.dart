import 'package:flutter/foundation.dart';
import '../models/leaderboard_entry_model.dart';

class LeaderboardProvider extends ChangeNotifier {
  final List<LeaderboardEntryModel> _entries = [];

  /// -----------------------------
  /// GETTERS
  /// -----------------------------

  /// Liste triée :
  /// 1) Score décroissant
  /// 2) Durée croissante
  /// 3) Date décroissante
  List<LeaderboardEntryModel> get entriesSorted {
    final copy = List<LeaderboardEntryModel>.from(_entries);

    copy.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;

      final durCmp = a.durationSeconds.compareTo(b.durationSeconds);
      if (durCmp != 0) return durCmp;

      return b.createdAt.compareTo(a.createdAt);
    });

    return copy;
  }

  int get count => _entries.length;

  /// Top N joueurs
  List<LeaderboardEntryModel> top(int n) {
    final sorted = entriesSorted;
    if (n >= sorted.length) return sorted;
    return sorted.take(n).toList();
  }

  /// Meilleur score d’un utilisateur
  int bestScoreOf(String userId) {
    final userEntries =
    _entries.where((e) => e.userId == userId).toList();

    if (userEntries.isEmpty) return 0;

    userEntries.sort((a, b) => b.score.compareTo(a.score));
    return userEntries.first.score;
  }

  /// Rang actuel d’un utilisateur (basé sur son meilleur score)
  int? rankOf(String userId) {
    final sorted = entriesSorted;

    final best = bestScoreOf(userId);
    if (best == 0) return null;

    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].userId == userId) {
        return i + 1; // rang commence à 1
      }
    }

    return null;
  }

  /// -----------------------------
  /// ACTIONS
  /// -----------------------------

  void addEntry(LeaderboardEntryModel entry) {
    // 🔒 Anti-duplication basique :
    // même user + même score + même durée dans la même minute
    final exists = _entries.any((e) =>
    e.userId == entry.userId &&
        e.score == entry.score &&
        e.durationSeconds == entry.durationSeconds &&
        (e.createdAt.difference(entry.createdAt).inSeconds).abs() < 60);

    if (exists) return;

    _entries.add(entry);
    notifyListeners();
  }

  /// Supprimer toutes les entrées d’un utilisateur
  void removeUserEntries(String userId) {
    _entries.removeWhere((e) => e.userId == userId);
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
