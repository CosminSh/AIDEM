import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
  FlutterTts? _tts;
  Process? _windowsSpeechProcess;
  bool _didConfigure = false;
  int _speechRun = 0;

  @override
  VoiceState build() {
    if (_isWindows) {
      _disablePersistedVoice();
      return const VoiceState(
        enabled: false,
        available: true,
        isSpeaking: false,
        isInitializing: false,
      );
    }

    _restorePreference();

    return const VoiceState(
      enabled: false,
      available: true,
      isSpeaking: false,
      isInitializing: true,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    if (_isWindows) {
      if (!enabled) {
        await stop();
      }
      await _saveEnabled(false);
      state = state.copyWith(
        enabled: enabled,
        available: true,
        isSpeaking: false,
        isInitializing: false,
        clearError: true,
      );
      return;
    }

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
    await _saveEnabled(enabled);
  }

  Future<void> toggle() => setEnabled(!state.enabled);

  Future<void> speakAiMessage(String text, {String? language}) async {
    if (!state.enabled || text.trim().isEmpty) {
      return;
    }

    if (_isWindows) {
      if (!state.available) {
        return;
      }
      await _speakWithWindowsFallback(text);
      return;
    }

    await _ensureReady();
    if (!state.available) {
      return;
    }

    try {
      final tts = _tts;
      if (tts == null) {
        return;
      }
      await tts.stop();
      await tts.setLanguage(_localeForLanguage(language));
      await tts.setSpeechRate(0.46);
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);
      await tts.speak(_cleanForSpeech(text));
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
    _speechRun++;
    final windowsProcess = _windowsSpeechProcess;
    _windowsSpeechProcess = null;
    if (windowsProcess != null) {
      windowsProcess.kill();
    }

    try {
      await _tts?.stop();
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
      if (_isWindows) {
        await prefs.setBool(_enabledKey, false);
        state = state.copyWith(
          enabled: false,
          available: true,
          isInitializing: false,
          clearError: true,
        );
        return;
      }
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
      final tts = _ensureEngine();
      await tts.awaitSpeakCompletion(true);
      final languages = await tts.getLanguages;
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

  Future<void> _speakWithWindowsFallback(String text) async {
    final spokenText = _cleanForSpeech(text);
    if (spokenText.isEmpty) {
      return;
    }

    await stop();
    final runId = ++_speechRun;
    state = state.copyWith(isSpeaking: true, clearError: true);

    final encodedCommand = _buildWindowsSpeechCommand(
      _limitWindowsSpeechText(spokenText),
    );

    try {
      final process = await Process.start('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-WindowStyle',
        'Hidden',
        '-ExecutionPolicy',
        'Bypass',
        '-EncodedCommand',
        encodedCommand,
      ]);
      _windowsSpeechProcess = process;
      final stderrBuffer = StringBuffer();
      unawaited(process.stdout.drain<void>());
      unawaited(
        process.stderr
            .transform(utf8.decoder)
            .listen((chunk) => stderrBuffer.write(chunk))
            .asFuture<void>(),
      );

      unawaited(
        process.exitCode
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                process.kill();
                return -1;
              },
            )
            .then((code) {
              if (runId != _speechRun) {
                return;
              }
              _windowsSpeechProcess = null;
              final errorDetails = stderrBuffer.toString().trim();
              state = state.copyWith(
                isSpeaking: false,
                available: true,
                enabled: code == 0 && state.enabled,
                errorMessage: code == 0
                    ? null
                    : errorDetails.isEmpty
                    ? 'Windows voice output failed and was disabled.'
                    : 'Windows voice output failed: $errorDetails',
                clearError: code == 0,
              );
            })
            .catchError((_) {
              if (runId != _speechRun) {
                return;
              }
              _windowsSpeechProcess = null;
              state = state.copyWith(
                enabled: false,
                available: true,
                isSpeaking: false,
                errorMessage: 'Windows voice output is not available.',
              );
            }),
      );
    } catch (_) {
      _windowsSpeechProcess = null;
      state = state.copyWith(
        enabled: false,
        available: true,
        isSpeaking: false,
        errorMessage: 'Windows voice output is not available.',
      );
    }
  }

  void _configureHandlers(FlutterTts tts) {
    if (_didConfigure) {
      return;
    }
    _didConfigure = true;

    tts.setStartHandler(() {
      state = state.copyWith(isSpeaking: true, clearError: true);
    });
    tts.setCompletionHandler(() {
      state = state.copyWith(isSpeaking: false);
    });
    tts.setCancelHandler(() {
      state = state.copyWith(isSpeaking: false);
    });
    tts.setErrorHandler((message) {
      state = state.copyWith(
        enabled: false,
        available: false,
        isSpeaking: false,
        errorMessage: 'Voice output failed: $message',
      );
    });
  }

  FlutterTts _ensureEngine() {
    final existing = _tts;
    if (existing != null) {
      return existing;
    }

    final created = FlutterTts();
    _tts = created;
    _configureHandlers(created);
    return created;
  }

  Future<void> _saveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<void> _disablePersistedVoice() async {
    try {
      await _saveEnabled(false);
    } catch (_) {
      // If preferences are unavailable, still keep this session disabled.
    }
  }

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  String _cleanForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'\[[A-Z ]+\]'), '')
        .replaceAll(RegExp(r'[`*_#>]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _limitWindowsSpeechText(String text) {
    const maxChars = 2000;
    if (text.length <= maxChars) {
      return text;
    }
    return '${text.substring(0, maxChars)}...';
  }

  String _buildWindowsSpeechCommand(String text) {
    final textBase64 = base64Encode(utf8.encode(text));
    final script =
        """
\$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
\$bytes = [System.Convert]::FromBase64String('$textBase64')
\$text = [System.Text.Encoding]::UTF8.GetString(\$bytes)
\$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
\$synth.Rate = -1
\$synth.Volume = 100
\$synth.Speak(\$text)
\$synth.Dispose()
""";
    final bytes = <int>[];
    for (final codeUnit in script.codeUnits) {
      bytes
        ..add(codeUnit & 0xff)
        ..add((codeUnit >> 8) & 0xff);
    }
    return base64Encode(bytes);
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
