import 'package:flutter_test/flutter_test.dart';
import 'package:nibble_note/features/summarization/application/heuristic_summarization_service.dart';

void main() {
  const service = HeuristicSummarizationService();

  test('empty input yields empty summary', () async {
    expect(await service.summarize(''), '');
    expect(await service.summarize('   \n  '), '');
  });

  test('short input is returned as-is', () async {
    const input = 'Only one sentence here.';
    expect(await service.summarize(input), input);
  });

  test('picks salient sentences from a longer note', () async {
    const input = '''
      Nibble the pet loves to eat notes.
      The weather in Tokyo was rainy today.
      Nibble ate three notes about the Tokyo trip.
      I need to buy groceries later.
      Nibble is happy when Nibble gets notes.
    ''';
    final summary = await service.summarize(input);
    // Sentences mentioning "Nibble" or "notes" should score higher than the
    // groceries throwaway.
    expect(summary, contains('Nibble'));
    expect(summary, isNot(contains('groceries')));
  });
}
