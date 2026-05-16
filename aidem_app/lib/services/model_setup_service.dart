import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ModelStatus { notInstalled, downloading, ready, error }

class ModelSetupState {
  final ModelStatus status;
  final double downloadProgress;
  final String statusMessage;
  final String? errorMessage;
  final String? activeModelPath;

  const ModelSetupState({
    required this.status,
    required this.downloadProgress,
    required this.statusMessage,
    this.errorMessage,
    this.activeModelPath,
  });

  ModelSetupState copyWith({
    ModelStatus? status,
    double? downloadProgress,
    String? statusMessage,
    String? errorMessage,
    String? activeModelPath,
  }) {
    return ModelSetupState(
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      activeModelPath: activeModelPath ?? this.activeModelPath,
    );
  }

  bool get isReady => status == ModelStatus.ready;

  String get modelLabel {
    if (!isReady) {
      return 'No LLM loaded';
    }

    final path = activeModelPath;
    if (path == null || path.isEmpty) {
      return 'Gemma 4 E2B IT';
    }

    return path.split(RegExp(r'[\\/]')).last;
  }
}

class ModelSetupService extends Notifier<ModelSetupState> {
  static const String recommendedModelName =
      'litert-community/gemma-4-E2B-it-litert-lm';
  static const String recommendedModelPageUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/tree/main';
  static const String recommendedModelDownloadUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';

  static const String _modelFileName = 'gemma-4-e2b-it.litertlm';
  static const String _lastUsedModelKey = 'last_used_model_path';

  @override
  ModelSetupState build() {
    return const ModelSetupState(
      status: ModelStatus.notInstalled,
      downloadProgress: 0.0,
      statusMessage: 'Checking for model...',
    );
  }

  Future<bool> checkIfInstalled() async {
    try {
      // 1. Check if Gemma 4 is already active
      final hasActive = FlutterGemma.hasActiveModel();
      if (hasActive) {
        state = state.copyWith(
          status: ModelStatus.ready,
          statusMessage: 'Model ready',
        );
        return true;
      }

      // 2. Check the last used model path or portable app directories.
      final prefs = await SharedPreferences.getInstance();
      String? savedPath = prefs.getString(_lastUsedModelKey);

      if (savedPath == null || !File(savedPath).existsSync()) {
        savedPath = await _findBundledModelPath();
      }

      if (savedPath != null && File(savedPath).existsSync()) {
        debugPrint('Auto-loading model from: $savedPath');
        await installFromLocalFile(savedPath);
        if (state.status == ModelStatus.ready) return true;
      }

      // 3. Fallback check for installed model file name (MediaPipe internal storage)
      final isGemma4Installed = await FlutterGemma.isModelInstalled(
        _modelFileName,
      );
      if (isGemma4Installed) {
        state = state.copyWith(
          status: ModelStatus.ready,
          statusMessage: 'Model ready',
          activeModelPath: _modelFileName,
        );
        return true;
      }

      state = state.copyWith(
        status: ModelStatus.notInstalled,
        statusMessage: 'Model not installed',
      );
      return false;
    } catch (e) {
      debugPrint('checkIfInstalled error: $e');
      state = state.copyWith(status: ModelStatus.notInstalled);
      return false;
    }
  }

  Future<void> downloadAndInstall({String? huggingFaceToken}) async {
    state = state.copyWith(
      status: ModelStatus.downloading,
      downloadProgress: 0,
      statusMessage: 'Starting download...',
    );

    try {
      await FlutterGemma.installModel(modelType: ModelType.gemma4)
          .fromNetwork(recommendedModelDownloadUrl, token: huggingFaceToken)
          .withProgress((progress) {
            // progress is an int representing percentage (0-100)
            final p = progress;
            state = state.copyWith(
              downloadProgress: p / 100.0,
              statusMessage: 'Downloading Gemma ($p%)...',
            );
          })
          .install();

      state = state.copyWith(
        status: ModelStatus.ready,
        statusMessage: 'Model installed successfully',
        downloadProgress: 1.0,
        activeModelPath: _modelFileName,
      );
    } catch (e) {
      state = state.copyWith(
        status: ModelStatus.error,
        errorMessage: e.toString(),
        statusMessage: 'Download failed',
      );
    }
  }

  Future<void> installFromLocalFile(String filePath) async {
    state = state.copyWith(
      status: ModelStatus.downloading,
      statusMessage:
          'Copying model to internal storage (this may take a minute)...',
      activeModelPath: filePath,
    );

    try {
      if (!await File(filePath).exists()) {
        throw Exception('File not found at: $filePath');
      }
      final pathLower = filePath.toLowerCase();

      // Strict validation for supported formats
      final isBinary =
          pathLower.endsWith('.bin') || pathLower.endsWith('.tflite');
      final isLiteRT = pathLower.endsWith('.litertlm');
      final isTask = pathLower.endsWith('.task');

      if (!isBinary && !isLiteRT && !isTask) {
        throw Exception(
          'Unsupported file format. Please provide a .litertlm, .bin, or .tflite model file.\n'
          'Compressed archives (.tar.gz, .zip) are not supported directly.',
        );
      }

      final fileType = isBinary
          ? ModelFileType.binary
          : (isLiteRT ? ModelFileType.litertlm : ModelFileType.task);

      debugPrint(
        'LLM Setup: Starting installation of ($fileType) from: $filePath',
      );
      debugPrint(
        'LLM Setup: This may take a minute as the model is copied to internal storage...',
      );

      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: fileType,
      ).fromFile(filePath).install();

      debugPrint('LLM Setup: Installation call completed.');

      // Save this path as the last used one
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUsedModelKey, filePath);

      debugPrint('LLM Setup: SharedPreferences updated.');

      state = state.copyWith(
        status: ModelStatus.ready,
        statusMessage: 'Model installed from local file',
        downloadProgress: 1.0,
        activeModelPath: filePath,
      );
    } catch (e) {
      debugPrint('LLM Setup: installFromLocalFile error: $e');
      state = state.copyWith(
        status: ModelStatus.error,
        errorMessage: e.toString(),
        statusMessage: 'Installation failed',
      );
    }
  }

  Future<String?> _findBundledModelPath() async {
    final candidates = <String>[];

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final exeDir = File(Platform.resolvedExecutable).parent;
      candidates.add(_joinPath(exeDir.path, ['models', _modelFileName]));
      candidates.add(_joinPath(exeDir.parent.path, ['models', _modelFileName]));
    }

    final supportDir = await getApplicationSupportDirectory();
    candidates.add(_joinPath(supportDir.path, ['models', _modelFileName]));

    final documentsDir = await getApplicationDocumentsDirectory();
    candidates.add(
      _joinPath(documentsDir.path, ['AIDEM', 'models', _modelFileName]),
    );

    for (final path in candidates) {
      if (File(path).existsSync()) {
        return path;
      }
    }

    return null;
  }

  String _joinPath(String root, List<String> segments) {
    var current = root;
    for (final segment in segments) {
      current = '$current${Platform.pathSeparator}$segment';
    }
    return current;
  }
}
