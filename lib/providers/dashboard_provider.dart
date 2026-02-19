import 'dart:async';
import 'package:flutter/foundation.dart';

import '../services/firestore_service.dart';


class DashboardProvider extends ChangeNotifier {
  final FirestoreService _firestore;

  DashboardProvider({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  bool _loading = true;
  String? _error;

  int _totalQuizzes = 0;
  int? _bestScore;
  int? _bestTotal;
  int? _position;

  StreamSubscription<int>? _subTotal;
  StreamSubscription<Map<String, int>?>? _subBest;
  StreamSubscription<int?>? _subPos;

  bool get isLoading => _loading;
  String? get error => _error;

  int get totalQuizzes => _totalQuizzes;
  int? get bestScore => _bestScore;
  int? get bestTotal => _bestTotal;
  int? get position => _position;

  void startForUser(String uid) {
    disposeStreams();

    _loading = true;
    _error = null;
    notifyListeners();

    _subTotal = _firestore.streamTotalQuizzesCount().listen(
          (v) {
        _totalQuizzes = v;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );

    _subBest = _firestore.streamBestScoreForUser(uid).listen(
          (map) {
        _bestScore = map?['score'];
        _bestTotal = map?['total'];
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );

    _subPos = _firestore.streamUserPosition(uid, scanLimit: 200).listen(
          (pos) {
        _position = pos;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  void disposeStreams() {
    _subTotal?.cancel();
    _subBest?.cancel();
    _subPos?.cancel();
    _subTotal = null;
    _subBest = null;
    _subPos = null;
  }

  @override
  void dispose() {
    disposeStreams();
    super.dispose();
  }
}
