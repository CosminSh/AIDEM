import 'package:flutter/foundation.dart';
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
      debugPrint('Speech: Initializing...');
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'notListening' || status == 'done') {
            state = state.copyWith(isListening: false);
          }
        },
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          state = state.copyWith(error: error.errorMsg, isListening: false);
        },
      );
      state = state.copyWith(isAvailable: available);
      debugPrint('Speech: Available = $available');
      return available;
    } catch (e) {
      debugPrint('Speech: Init exception: $e');
      state = state.copyWith(isAvailable: false, error: e.toString());
      return false;
    }
  }

  Future<bool> startListening({required Function(String) onResult}) async {
    if (!state.isAvailable) {
      final ok = await init();
      if (!ok) return false;
    }

    state = state.copyWith(isListening: true, lastWords: '', clearError: true);
    debugPrint('Speech: Starting to listen...');

    try {
      await _speech.listen(
        onResult: (result) {
          debugPrint(
            'Speech result: ${result.recognizedWords} (final: ${result.finalResult})',
          );
          state = state.copyWith(lastWords: result.recognizedWords);
          onResult(result.recognizedWords);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Speech: Listen exception: $e');
      state = state.copyWith(isListening: false, error: e.toString());
      return false;
    }
  }

  Future<void> stopListening() async {
    debugPrint('Speech: Stopping...');
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  void clearWords() {
    state = state.copyWith(lastWords: '');
  }
}
