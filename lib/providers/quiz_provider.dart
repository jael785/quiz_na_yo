// quiz_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/question_model.dart';
import '../services/api_service.dart';
import '../services/local_question_service.dart';
import '../services/firestore_service.dart';

enum QuizMode { api, local, firestore }

class QuizProvider extends ChangeNotifier {
  List<QuestionModel> _questions = [];
  int _index = 0;
  int _score = 0;

  int? _selectedIndex;
  bool _answered = false;

  bool _loading = false;
  String? _error;

  Timer? _timer;
  int _remainingSeconds = 15;

  final Stopwatch _stopwatch = Stopwatch();

  QuizMode? _lastMode;

  // Firestore params
  int _lastFsLimit = 30;
  String? _lastFsCategoryId;
  String? _lastFsDifficulty;

  List<QuestionModel> get questions => _questions;
  QuestionModel? get current => (_index < _questions.length) ? _questions[_index] : null;

  int get index => _index;
  int get total => _questions.length;
  int get score => _score;

  int? get selectedIndex => _selectedIndex;
  bool get hasAnswered => _answered;

  bool get isLoading => _loading;
  String? get error => _error;

  int get remainingSeconds => _remainingSeconds;
  int get elapsedSeconds => _stopwatch.elapsed.inSeconds;

  bool get isFinished => _index >= _questions.length;

  // API
  Future<void> startApiQuiz() async {
    _lastMode = QuizMode.api;
    await _startWithLoader(() async {
      final api = ApiService();
      _questions = await api.fetchQuestions();
      _prepareQuiz();
    }, errorMessage: "Impossible de charger les questions via l'API.");
  }

  // Local
  Future<void> startLocalQuiz() async {
    _lastMode = QuizMode.local;
    await _startWithLoader(() async {
      final local = LocalQuestionService();
      _questions = await local.loadQuestions();
      _prepareQuiz();
    }, errorMessage: "Impossible de charger les questions locales.");
  }

  // Firestore
  Future<void> startFirestoreQuiz({
    int limit = 30,
    String? categoryId,
    String? difficulty,
  }) async {
    _lastMode = QuizMode.firestore;
    _lastFsLimit = limit;
    _lastFsCategoryId = categoryId;
    _lastFsDifficulty = difficulty;

    await _startWithLoader(() async {
      final fs = FirestoreService();
      _questions = await fs.fetchActiveQuestions(
        limit: limit,
        categoryId: categoryId,
        difficulty: difficulty,
      );
      _prepareQuiz();
    }, errorMessage: "Impossible de charger les questions Firestore.");
  }

  // Rejouer
  Future<void> restartLastQuiz() async {
    disposeQuiz(clearQuestions: true);
    final mode = _lastMode ?? QuizMode.api;

    switch (mode) {
      case QuizMode.api:
        await startApiQuiz();
        break;
      case QuizMode.local:
        await startLocalQuiz();
        break;
      case QuizMode.firestore:
        await startFirestoreQuiz(
          limit: _lastFsLimit,
          categoryId: _lastFsCategoryId,
          difficulty: _lastFsDifficulty,
        );
        break;
    }
  }

  void chooseAnswer(int i) {
    if (_answered) return;
    if (current == null) return;

    _selectedIndex = i;
    _answered = true;

    if (i == current!.correctIndex) _score++;

    _timer?.cancel();
    notifyListeners();
  }

  void next() {
    if (_questions.isEmpty || isFinished) return;

    if (!_answered) {
      _answered = true;
      _selectedIndex = null;
      _timer?.cancel();
    }

    final lastIndex = _questions.length - 1;

    if (_index < lastIndex) {
      _index++;
      _answered = false;
      _selectedIndex = null;
      _startTimer();
    } else {
      _index = _questions.length;
      _timer?.cancel();
      _stopwatch.stop();
    }

    notifyListeners();
  }

  void disposeQuiz({bool clearQuestions = false}) {
    _timer?.cancel();
    _timer = null;

    _stopwatch.stop();

    _answered = false;
    _selectedIndex = null;
    _remainingSeconds = 15;

    if (clearQuestions) {
      _questions = [];
      _index = 0;
      _score = 0;
    }

    notifyListeners();
  }

  void _prepareQuiz() {
    if (_questions.isEmpty) {
      _error = "Aucune question disponible.";
      return;
    }

    _questions.shuffle();

    _index = 0;
    _score = 0;
    _answered = false;
    _selectedIndex = null;

    _stopwatch
      ..reset()
      ..start();

    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = 15;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _answered = true;
        _selectedIndex = null;
      }

      notifyListeners();
    });
  }

  Future<void> _startWithLoader(
      Future<void> Function() job, {
        required String errorMessage,
      }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await job();
    } catch (e) {
      // ✅ ICI: on garde ton message propre, mais on ajoute le détail technique
      _error = "$errorMessage\nDétail: $e";
      if (kDebugMode) {
        // ignore: avoid_print
        print("QuizProvider error: $e");
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
