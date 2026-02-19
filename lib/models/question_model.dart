class QuestionModel {
  final String id;
  final String category;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuestionModel({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });


  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List?) ?? const [];
    final options = rawOptions
        .map((e) => (e ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    int ci = 0;
    final rawCi = json['correctIndex'];
    if (rawCi is int) {
      ci = rawCi;
    } else {
      ci = int.tryParse(rawCi?.toString() ?? '') ?? 0;
    }

    if (options.isEmpty) {
      return QuestionModel(
        id: (json['id'] ?? '').toString(),
        category: (json['category'] ?? "Général").toString(),
        question: (json['question'] ?? "").toString(),
        options: const ["—"],
        correctIndex: 0,
        explanation: (json['explanation'] ?? "").toString(),
      );
    }

    if (ci < 0) ci = 0;
    if (ci > options.length - 1) ci = options.length - 1;

    return QuestionModel(
      id: (json['id'] ?? '').toString(),
      category: (json['category'] ?? "Général").toString(),
      question: (json['question'] ?? "").toString(),
      options: options,
      correctIndex: ci,
      explanation: (json['explanation'] ?? "").toString(),
    );
  }

  /// ✅ Création depuis Firestore (sécurisée + mapping des champs admin)
  /// Admin écrit:
  /// - categoryName, question, options, correctIndex, explanation, active, difficulty...
  /// On map vers:
  /// - id (docId), category (categoryName), etc.
  factory QuestionModel.fromFirestore({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    // options
    final rawOptions = (data['options'] as List?) ?? const [];
    final options = rawOptions
        .map((e) => (e ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // correctIndex
    int ci = 0;
    final rawCi = data['correctIndex'];
    if (rawCi is int) {
      ci = rawCi;
    } else {
      ci = int.tryParse(rawCi?.toString() ?? '') ?? 0;
    }

    // category : on privilégie categoryName (admin)
    final catName = (data['categoryName'] ?? data['category'] ?? "Général").toString();
    final qText = (data['question'] ?? "").toString();
    final exp = (data['explanation'] ?? "").toString();

    if (options.isEmpty) {
      return QuestionModel(
        id: docId,
        category: catName.isEmpty ? "Général" : catName,
        question: qText,
        options: const ["—"],
        correctIndex: 0,
        explanation: exp,
      );
    }

    // clamp
    if (ci < 0) ci = 0;
    if (ci > options.length - 1) ci = options.length - 1;

    return QuestionModel(
      id: docId,
      category: catName.isEmpty ? "Général" : catName,
      question: qText,
      options: options,
      correctIndex: ci,
      explanation: exp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "category": category,
      "question": question,
      "options": options,
      "correctIndex": correctIndex,
      "explanation": explanation,
    };
  }
}
