import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/question_model.dart';


class ApiService {
  static const String _baseUrl = "https://opentdb.com/api.php";

  final Duration timeout;
  final int defaultAmount;

  ApiService({
    this.timeout = const Duration(seconds: 15),
    this.defaultAmount = 10,
  });

  Future<List<QuestionModel>> fetchQuestions({
    int? amount,
    int? category,
    String? difficulty, 
  }) async {
    final a = amount ?? defaultAmount;

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: <String, String>{
        "amount": a.toString(),
        "type": "multiple",
        if (category != null) "category": category.toString(),
        if (difficulty != null && difficulty.trim().isNotEmpty)
          "difficulty": difficulty.trim().toLowerCase(),
      },
    );

    try {
      final res = await http.get(uri).timeout(timeout);

      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}");
      }

      final decoded = jsonDecode(res.body);
      final int code = decoded["response_code"] ?? -1;

      if (code != 0) {
        throw Exception("OpenTDB response_code=$code");
      }

      final List<dynamic> results = decoded["results"] ?? const [];
      if (results.isEmpty) return const [];

      final out = <QuestionModel>[];

      for (int i = 0; i < results.length; i++) {
        final raw = results[i];
        if (raw is! Map) continue;

        final q = Map<String, dynamic>.from(raw);

        final categoryName =
        _decodeHtml((q["category"] ?? "Général").toString()).trim();
 
        final questionText =
        _decodeHtml((q["question"] ?? "").toString()).trim();

        final correct =
        _decodeHtml((q["correct_answer"] ?? "").toString()).trim();

     
        if (questionText.isEmpty || correct.isEmpty) {
          continue;
        }

        final incorrectRaw = (q["incorrect_answers"] as List?) ?? const [];
        final incorrect = incorrectRaw
            .map((e) => _decodeHtml((e ?? '').toString()).trim())
            .where((s) => s.isNotEmpty)
            .toList();

        final options = <String>[...incorrect, correct]
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        final unique = <String>[];
        for (final o in options) {
          if (!unique.contains(o)) unique.add(o);
        }

        if (unique.length < 2) {
          continue;
        }

        //  mélanger (mais garder correctIndex cohérent) jndijidj
        // JNDCJVKJ JNVJRI 
        //RJVNJVRNKR
        //HJCNJIRJKOR
        //JNVJNKV
        //JEJFHUIHE EGFUIEHFUIHU
        // VGDRYTYRT

        unique.shuffle();

        final correctIndex = unique.indexOf(correct);
        if (correctIndex < 0) {
          // bizarre: correct disparu (ex: doublon nettoyé)
          continue;
        }

        out.add(
          QuestionModel(
            id: "api_${DateTime.now().millisecondsSinceEpoch}_$i",
            category: categoryName.isEmpty ? "Général" : categoryName,
            question: questionText,
            options: unique,
            correctIndex: correctIndex,
            explanation: "Réponse correcte : $correct",
          ),
        );
      }

      // ✅ si après nettoyage on n’a rien -> renvoyer []
      return out;
    } on TimeoutException {
      throw Exception("Connexion trop lente (timeout). Vérifie Internet.");
    } catch (e) {
      throw Exception("Erreur API: ${e.toString()}");
    }
  }

  /// Decode HTML entities (OpenTDB renvoie des entités)
  String _decodeHtml(String s) {
    if (s.isEmpty) return s;

    return s
        .replaceAll("&quot;", '"')
        .replaceAll("&#039;", "'")
        .replaceAll("&apos;", "'")
        .replaceAll("&amp;", "&")
        .replaceAll("&lt;", "<")
        .replaceAll("&gt;", ">")
        .replaceAll("&nbsp;", " ")
        .replaceAll("&uuml;", "ü")
        .replaceAll("&eacute;", "é")
        .replaceAll("&rsquo;", "’")
        .replaceAll("&ldquo;", "“")
        .replaceAll("&rdquo;", "”")
        .replaceAll("&shy;", "");
  }
}
