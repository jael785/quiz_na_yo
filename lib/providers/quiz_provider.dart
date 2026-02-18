import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/question_model.dart';
import '../services/api_service.dart';
import '../services/local_question_service.dart';
import '../services/firestore_service.dart';

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

  // ----------------------------
  // GETTERS
  // ----------------------------
  List<QuestionModel> get questions => _questions;

  QuestionModel? get current =>
      (_index < _questions.length) ? _questions[_index] : null;

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

  // ----------------------------
  // MODE 1: API ONLY
  // ----------------------------
  Future<void> startApiQuiz() async {
    await _startWithLoader(() async {
      final api = ApiService();
      _questions = await api.fetchQuestions();
      _prepareQuiz();
    }, errorMessage: "Impossible de charger les questions via l'API.");
  }

  // ----------------------------
  // MODE 2: LOCAL JSON ONLY
  // ----------------------------
  Future<void> startLocalQuiz() async {
    await _startWithLoader(() async {
      final local = LocalQuestionService();
      _questions = await local.loadQuestions();
      _prepareQuiz();
    }, errorMessage: "Impossible de charger les questions locales.");
  }

  // ----------------------------
  // MODE 3: SMART (API -> fallback JSON)
  // ----------------------------
  Future<void> startSmartQuiz() async {
    await _startWithLoader(() async {
      try {
        final api = ApiService();
        _questions = await api.fetchQuestions();
      } catch (_) {
        final local = LocalQuestionService();
        _questions = await local.loadQuestions();
      }
      _prepareQuiz();
    }, errorMessage: "Impossible de charger les questions (API et local).");
  }

  // ----------------------------
  // ✅ MODE 4: FIRESTORE (admin -> users)
  // ----------------------------
  Future<void> startFirestoreQuiz({
    int limit = 30,
    String? categoryId,
    String? difficulty,
  }) async {
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

  // ----------------------------
  // QUIZ LOGIC
  // ----------------------------
  void chooseAnswer(int i) {
    if (_answered) return;
    if (current == null) return;

    _selectedIndex = i;
    _answered = true;

    if (i == current!.correctIndex) {
      _score++;
    }

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

  void disposeQuiz() {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
  }

  // ----------------------------
  // INTERNAL HELPERS
  // ----------------------------
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
    } catch (_) {
      _error = errorMessage;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
