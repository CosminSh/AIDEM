import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceState {
  final bool enabled;
  final bool available;
  final bool isSpeaking;
  final bool isInitializing;
  final String? errorMessage;

  const VoiceState({
    required this.enabled,
    required this.available,
    required this.isSpeaking,
    required this.isInitializing,
    this.errorMessage,
  });

  VoiceState copyWith({
    bool? enabled,
    bool? available,
    bool? isSpeaking,
    bool? isInitializing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VoiceState(
      enabled: enabled ?? this.enabled,
      available: available ?? this.available,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isInitializing: isInitializing ?? this.isInitializing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class VoiceService extends Notifier<VoiceState> {
  static const String _enabledKey = 'aidem_voice_read_aloud_enabled';
  final FlutterTts _tts = FlutterTts();
  bool _didConfigure = false;

  @override
  VoiceState build() {
    _configureHandlers();
    _restorePreference();

    return const VoiceState(
      enabled: false,
      available: true,
      isSpeaking: false,
      isInitializing: true,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      await _ensureReady();
      if (!state.available) {
        state = state.copyWith(enabled: false);
        return;
      }
    } else {
      await stop();
    }

    state = state.copyWith(enabled: enabled, clearError: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<void> toggle() => setEnabled(!state.enabled);

  Future<void> speakAiMessage(String text, {String? language}) async {
    if (!state.enabled || text.trim().isEmpty) {
      return;
    }

    await _ensureReady();
    if (!state.available) {
      return;
    }

    try {
      await _tts.stop();
      await _tts.setLanguage(_localeForLanguage(language));
      await _tts.setSpeechRate(0.46);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.speak(_cleanForSpeech(text));
    } catch (e) {
      state = state.copyWith(
        enabled: false,
        available: false,
        isSpeaking: false,
        errorMessage: 'Voice output is not available on this device.',
      );
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Stop is best-effort; keep the UI responsive even if a platform fails.
    } finally {
      state = state.copyWith(isSpeaking: false);
    }
  }

  Future<void> _restorePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_enabledKey) ?? false;
      state = state.copyWith(enabled: enabled, isInitializing: false);
      if (enabled) {
        await _ensureReady();
      }
    } catch (e) {
      state = state.copyWith(
        enabled: false,
        available: false,
        isInitializing: false,
        errorMessage: 'Voice preference could not be loaded.',
      );
    }
  }

  Future<void> _ensureReady() async {
    if (!state.available) {
      return;
    }

    try {
      await _tts.awaitSpeakCompletion(true);
      final languages = await _tts.getLanguages;
      final hasLanguages = languages is List && languages.isNotEmpty;
      state = state.copyWith(
        available: hasLanguages,
        isInitializing: false,
        errorMessage: hasLanguages
            ? null
            : 'No text-to-speech voices are installed on this device.',
        clearError: hasLanguages,
      );
    } catch (e) {
      state = state.copyWith(
        enabled: false,
        available: false,
        isSpeaking: false,
        isInitializing: false,
        errorMessage: 'Voice output is not available on this device.',
      );
    }
  }

  void _configureHandlers() {
    if (_didConfigure) {
      return;
    }
    _didConfigure = true;

    _tts.setStartHandler(() {
      state = state.copyWith(isSpeaking: true, clearError: true);
    });
    _tts.setCompletionHandler(() {
      state = state.copyWith(isSpeaking: false);
    });
    _tts.setCancelHandler(() {
      state = state.copyWith(isSpeaking: false);
    });
    _tts.setErrorHandler((message) {
      state = state.copyWith(
        enabled: false,
        available: false,
        isSpeaking: false,
        errorMessage: 'Voice output failed: $message',
      );
    });
  }

  String _cleanForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'\[[A-Z ]+\]'), '')
        .replaceAll(RegExp(r'[`*_#>]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _localeForLanguage(String? language) {
    switch ((language ?? 'English').toLowerCase()) {
      case 'spanish':
        return 'es-ES';
      case 'french':
        return 'fr-FR';
      case 'romanian':
        return 'ro-RO';
      case 'german':
        return 'de-DE';
      case 'italian':
        return 'it-IT';
      case 'portuguese':
        return 'pt-PT';
      case 'dutch':
        return 'nl-NL';
      case 'russian':
        return 'ru-RU';
      case 'ukrainian':
        return 'uk-UA';
      case 'polish':
        return 'pl-PL';
      case 'turkish':
        return 'tr-TR';
      case 'arabic':
        return 'ar';
      case 'hindi':
        return 'hi-IN';
      case 'chinese':
        return 'zh-CN';
      case 'japanese':
        return 'ja-JP';
      case 'korean':
        return 'ko-KR';
      default:
        return 'en-US';
    }
  }
}
