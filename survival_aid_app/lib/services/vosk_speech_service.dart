import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

class VoskSpeechState {
  final bool isAvailable;
  final bool isPreparing;
  final bool isListening;
  final bool modelReady;
  final String lastWords;
  final String? modelPath;
  final String? error;
  final int chunksProcessed;
  final int bytesProcessed;
  final int acceptedResults;
  final double lastPeak;
  final String lastPartialJson;
  final String lastResultJson;
  final String debugStatus;

  const VoskSpeechState({
    this.isAvailable = false,
    this.isPreparing = false,
    this.isListening = false,
    this.modelReady = false,
    this.lastWords = '',
    this.modelPath,
    this.error,
    this.chunksProcessed = 0,
    this.bytesProcessed = 0,
    this.acceptedResults = 0,
    this.lastPeak = 0,
    this.lastPartialJson = '',
    this.lastResultJson = '',
    this.debugStatus = 'Idle',
  });

  VoskSpeechState copyWith({
    bool? isAvailable,
    bool? isPreparing,
    bool? isListening,
    bool? modelReady,
    String? lastWords,
    String? modelPath,
    String? error,
    int? chunksProcessed,
    int? bytesProcessed,
    int? acceptedResults,
    double? lastPeak,
    String? lastPartialJson,
    String? lastResultJson,
    String? debugStatus,
    bool clearError = false,
  }) {
    return VoskSpeechState(
      isAvailable: isAvailable ?? this.isAvailable,
      isPreparing: isPreparing ?? this.isPreparing,
      isListening: isListening ?? this.isListening,
      modelReady: modelReady ?? this.modelReady,
      lastWords: lastWords ?? this.lastWords,
      modelPath: modelPath ?? this.modelPath,
      error: clearError ? null : (error ?? this.error),
      chunksProcessed: chunksProcessed ?? this.chunksProcessed,
      bytesProcessed: bytesProcessed ?? this.bytesProcessed,
      acceptedResults: acceptedResults ?? this.acceptedResults,
      lastPeak: lastPeak ?? this.lastPeak,
      lastPartialJson: lastPartialJson ?? this.lastPartialJson,
      lastResultJson: lastResultJson ?? this.lastResultJson,
      debugStatus: debugStatus ?? this.debugStatus,
    );
  }
}

class VoskFallbackSpeechService extends Notifier<VoskSpeechState> {
  static const int _sampleRate = 16000;
  static const String _modelName = 'vosk-model-small-en-us-0.15';
  static const String _assetModelPath =
      'assets/models/vosk-model-small-en-us-0.15.zip';

  final AudioRecorder _recorder = AudioRecorder();
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  final ModelLoader _modelLoader = ModelLoader();

  Model? _model;
  Recognizer? _recognizer;
  StreamSubscription<Uint8List>? _audioSubscription;

  @override
  VoskSpeechState build() {
    ref.onDispose(() {
      unawaited(_audioSubscription?.cancel());
      unawaited(_recorder.dispose());
      unawaited(_recognizer?.dispose());
    });

    return const VoskSpeechState();
  }

  Future<bool> prepare({bool allowDownload = true}) async {
    if (_recognizer != null && state.modelReady) {
      return true;
    }
    if (state.isPreparing) {
      return state.modelReady;
    }

    state = state.copyWith(isPreparing: true, clearError: true);

    try {
      final modelPath = await _resolveModelPath(allowDownload: allowDownload);
      if (modelPath == null) {
        state = state.copyWith(
          isAvailable: false,
          isPreparing: false,
          modelReady: false,
          error: allowDownload
              ? 'Offline voice model could not be prepared.'
              : 'Offline voice model is not installed yet.',
        );
        return false;
      }

      _model ??= await _vosk.createModel(modelPath);
      _recognizer ??= await _vosk.createRecognizer(
        model: _model!,
        sampleRate: _sampleRate,
      );

      state = state.copyWith(
        isAvailable: true,
        isPreparing: false,
        modelReady: true,
        modelPath: modelPath,
        debugStatus: 'Vosk model ready',
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isAvailable: false,
        isPreparing: false,
        modelReady: false,
        error: 'Offline voice fallback unavailable: $e',
      );
      return false;
    }
  }

  Future<void> startListening({required void Function(String) onResult}) async {
    if (state.isListening) {
      return;
    }

    final ready = await prepare();
    if (!ready || _recognizer == null) {
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(
        error: 'Microphone permission was denied.',
        debugStatus: 'Microphone permission denied',
      );
      return;
    }

    try {
      await _recognizer!.reset();
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
          autoGain: true,
          noiseSuppress: true,
        ),
      );

      state = state.copyWith(
        isListening: true,
        lastWords: '',
        chunksProcessed: 0,
        bytesProcessed: 0,
        acceptedResults: 0,
        lastPeak: 0,
        lastPartialJson: '',
        lastResultJson: '',
        debugStatus: 'Listening to microphone stream',
        clearError: true,
      );

      _audioSubscription = stream.listen(
        (chunk) async {
          final peak = _peakLevel(chunk);
          final accepted = await _recognizer!.acceptWaveformBytes(chunk);
          final raw = accepted
              ? await _recognizer!.getResult()
              : await _recognizer!.getPartialResult();
          final words = _extractText(raw);
          state = state.copyWith(
            chunksProcessed: state.chunksProcessed + 1,
            bytesProcessed: state.bytesProcessed + chunk.length,
            acceptedResults: accepted
                ? state.acceptedResults + 1
                : state.acceptedResults,
            lastPeak: peak,
            lastPartialJson: accepted ? state.lastPartialJson : raw,
            lastResultJson: accepted ? raw : state.lastResultJson,
            debugStatus: words.isEmpty
                ? 'Audio received, waiting for recognizable speech'
                : 'Transcript received',
          );
          if (words.isEmpty || words == state.lastWords) {
            return;
          }
          state = state.copyWith(lastWords: words);
          onResult(words);
        },
        onError: (Object e) {
          state = state.copyWith(
            isListening: false,
            error: 'Offline voice input failed: $e',
            debugStatus: 'Recorder stream error',
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        error: 'Offline voice input failed: $e',
        debugStatus: 'Failed to start recorder stream',
      );
    }
  }

  Future<void> stopListening() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      final finalWords = _recognizer == null
          ? ''
          : _extractText(await _recognizer!.getFinalResult());
      state = state.copyWith(
        isListening: false,
        lastWords: finalWords.isEmpty ? state.lastWords : finalWords,
        debugStatus: finalWords.isEmpty
            ? 'Stopped listening'
            : 'Final transcript received',
      );
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        error: 'Offline voice input could not stop cleanly: $e',
        debugStatus: 'Stop failed',
      );
    }
  }

  Future<bool> runMicrophoneProbe({
    Duration duration = const Duration(seconds: 3),
  }) async {
    if (state.isListening) {
      return false;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(
        error: 'Microphone permission was denied.',
        debugStatus: 'Microphone probe denied',
      );
      return false;
    }

    StreamSubscription<Uint8List>? subscription;
    var chunks = 0;
    var bytes = 0;
    var peak = 0.0;

    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
          autoGain: true,
          noiseSuppress: true,
        ),
      );
      subscription = stream.listen((chunk) {
        chunks++;
        bytes += chunk.length;
        peak = math.max(peak, _peakLevel(chunk));
      });

      state = state.copyWith(debugStatus: 'Running microphone probe...');
      await Future<void>.delayed(duration);
      await subscription.cancel();
      await _recorder.stop();

      state = state.copyWith(
        chunksProcessed: chunks,
        bytesProcessed: bytes,
        lastPeak: peak,
        debugStatus: peak > 0.02
            ? 'Mic probe detected audio'
            : 'Mic probe received little or no audio',
        clearError: true,
      );
      return peak > 0.02;
    } catch (e) {
      await subscription?.cancel();
      try {
        if (await _recorder.isRecording()) {
          await _recorder.stop();
        }
      } catch (_) {}
      state = state.copyWith(
        error: 'Microphone probe failed: $e',
        debugStatus: 'Microphone probe failed',
      );
      return false;
    }
  }

  Future<String?> _resolveModelPath({required bool allowDownload}) async {
    if (await _modelLoader.isModelAlreadyLoaded(_modelName)) {
      return _modelLoader.modelPath(_modelName);
    }

    try {
      return await _modelLoader.loadFromAssets(_assetModelPath);
    } catch (_) {
      // Asset is optional. Packaged builds can include it for fully offline STT.
    }

    if (!allowDownload) {
      return null;
    }

    final models = await _modelLoader.loadModelsList();
    final modelDescription = models.firstWhere(
      (model) => model.name == _modelName,
      orElse: () => models.firstWhere(
        (model) =>
            model.lang == 'en-us' && model.type == 'small' && !model.obsolete,
      ),
    );
    return _modelLoader.loadFromNetwork(modelDescription.url);
  }

  String _extractText(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      return ((decoded['text'] ?? decoded['partial']) as String? ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  double _peakLevel(Uint8List bytes) {
    if (bytes.length < 2) {
      return 0;
    }

    final data = ByteData.sublistView(bytes);
    var peak = 0;
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final sample = data.getInt16(i, Endian.little);
      final abs = sample.abs();
      if (abs > peak) {
        peak = abs;
      }
    }
    return peak / 32768.0;
  }
}
