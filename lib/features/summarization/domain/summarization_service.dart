/// Public interface for summarizing note content.
///
/// The MVP ships with an on-device *placeholder* implementation
/// ([HeuristicSummarizationService]) so the app has a working "Summarize"
/// button without pulling in a large local LLM. Real on-device inference
/// (e.g. `flutter_gemma`, `llama.cpp`, MLC, or a TFLite text model) can be
/// dropped in later by implementing this interface.
abstract class SummarizationService {
  /// Return a short, plaintext summary of [content]. Implementations must run
  /// fully on-device — no network calls — so a locked or offline user still
  /// gets a response.
  Future<String> summarize(String content);
}
