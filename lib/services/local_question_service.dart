import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question_model.dart';

class LocalQuestionService {

  /// Charge toutes les questions depuis le fichier JSON
  Future<List<QuestionModel>> loadQuestions() async {
    try {
      // 1️⃣ Charger le fichier
      final jsonString =
      await rootBundle.loadString('assets/data/questions.json');

      // 2️⃣ Décoder
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // 3️⃣ Extraire la liste
      final List<dynamic> list = data['questions'];

      // 4️⃣ Mapper vers QuestionModel
      final questions = list
          .map((e) => QuestionModel.fromJson(e))
          .toList();

      return questions;
    } catch (e) {
      throw Exception("Erreur chargement JSON local");
    }
  }
}
