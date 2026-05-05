import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechState {
  final bool isAvailable;
  final bool isListening;
  final String lastWords;
  final String? error;

  SpeechState({
    this.isAvailable = false,
    this.isListening = false,
    this.lastWords = '',
    this.error,
  });

  SpeechState copyWith({
    bool? isAvailable,
    bool? isListening,
    String? lastWords,
    String? error,
    bool clearError = false,
  }) {
    return SpeechState(
      isAvailable: isAvailable ?? this.isAvailable,
      isListening: isListening ?? this.isListening,
      lastWords: lastWords ?? this.lastWords,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SpeechService extends Notifier<SpeechState> {
  final SpeechToText _speech = SpeechToText();

  @override
  SpeechState build() {
    return SpeechState();
  }

  Future<bool> init() async {
    if (state.isAvailable) return true;

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            state = state.copyWith(isListening: false);
          }
        },
        onError: (error) => state = state.copyWith(error: error.errorMsg, isListening: false),
      );
      state = state.copyWith(isAvailable: available);
      return available;
    } catch (e) {
      state = state.copyWith(isAvailable: false, error: e.toString());
      return false;
    }
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (!state.isAvailable) {
      final ok = await init();
      if (!ok) return;
    }

    state = state.copyWith(isListening: true, lastWords: '', clearError: true);

    await _speech.listen(
      onResult: (result) {
        state = state.copyWith(lastWords: result.recognizedWords);
        onResult(result.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      cancelOnError: true,
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  void clearWords() {
    state = state.copyWith(lastWords: '');
  }
}
