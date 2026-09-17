import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/summarization_service.dart';

/// Local, no-dependency placeholder summarizer.
///
/// It performs a naive extractive summary:
///   * splits [content] into sentences,
///   * scores each sentence by word frequency (ignoring stop-words),
///   * returns the top few sentences in their original order.
///
/// This is intentionally simple. When a proper on-device LLM lands, replace
/// this class with a new [SummarizationService] implementation and swap the
/// Riverpod override — the UI never has to change.
///
/// TODO(ai): Replace with an on-device inference backend. Suggested paths:
///  * `flutter_gemma` for Gemma nano
///  * `flutter_llama_cpp` for GGUF models
///  * a TFLite text-summarization model via `tflite_flutter`
class HeuristicSummarizationService implements SummarizationService {
  const HeuristicSummarizationService();

  static const Set<String> _stopWords = {
    'the', 'a', 'an', 'and', 'or', 'but', 'if', 'while', 'of', 'at', 'by',
    'for', 'with', 'about', 'against', 'between', 'into', 'through', 'during',
    'before', 'after', 'above', 'below', 'to', 'from', 'up', 'down', 'in',
    'out', 'on', 'off', 'over', 'under', 'again', 'further', 'then', 'once',
    'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
    'do', 'does', 'did', 'will', 'would', 'shall', 'should', 'can', 'could',
    'may', 'might', 'must', 'this', 'that', 'these', 'those', 'i', 'you',
    'he', 'she', 'it', 'we', 'they', 'my', 'your', 'his', 'her', 'its',
    'our', 'their', 'not', 'no', 'so', 'as', 'just', 'than',
  };

  @override
  Future<String> summarize(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return '';

    // Split into sentences on ., !, ?, or newlines.
    final sentences = trimmed
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (sentences.length <= 2) return sentences.join(' ');

    final frequency = <String, int>{};
    for (final sentence in sentences) {
      for (final word in _tokenize(sentence)) {
        frequency[word] = (frequency[word] ?? 0) + 1;
      }
    }

    final scored = <_ScoredSentence>[];
    for (var i = 0; i < sentences.length; i++) {
      final words = _tokenize(sentences[i]);
      if (words.isEmpty) continue;
      final score =
          words.fold<int>(0, (a, w) => a + (frequency[w] ?? 0)) / words.length;
      scored.add(_ScoredSentence(index: i, sentence: sentences[i], score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final take = scored.take(3).toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return take.map((s) => s.sentence).join(' ');
  }

  Iterable<String> _tokenize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !_stopWords.contains(w));
  }
}

class _ScoredSentence {
  const _ScoredSentence({
    required this.index,
    required this.sentence,
    required this.score,
  });
  final int index;
  final String sentence;
  final double score;
}

final summarizationServiceProvider = Provider<SummarizationService>(
  (ref) => const HeuristicSummarizationService(),
);
