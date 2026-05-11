import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

enum ModelStatus { notInstalled, downloading, ready, error }

class ModelSetupState {
  final ModelStatus status;
  final double downloadProgress;
  final String statusMessage;
  final String? errorMessage;

  const ModelSetupState({
    required this.status,
    required this.downloadProgress,
    required this.statusMessage,
    this.errorMessage,
  });

  ModelSetupState copyWith({
    ModelStatus? status,
    double? downloadProgress,
    String? statusMessage,
    String? errorMessage,
  }) {
    return ModelSetupState(
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isReady => status == ModelStatus.ready;
}

class ModelSetupService extends Notifier<ModelSetupState> {
  static const String _modelFileName = 'gemma-4-e2b-it.litertlm';
  static const String _lastUsedModelKey = 'last_used_model_path';
  static const String _defaultModelPath =
      r'G:\Antigravity Projects\AIDEM\Assets\Models\gemma-4-E2B-it.litertlm';
  static const String _huggingFaceBaseUrl =
      'https://huggingface.co/google/gemma-4-2b-it-lite-rt-gguf/resolve/main/gemma4-2b-it-lite-rt-web.zip';

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

      // 2. Check for last used model path or default paths
      final prefs = await SharedPreferences.getInstance();
      String? savedPath = prefs.getString(_lastUsedModelKey);

      // Look for model in relative 'models' folder next to the exe (Portable mode)
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final relativePath = '$exeDir\\models\\$_modelFileName';

      if (savedPath == null || !File(savedPath).existsSync()) {
        if (File(relativePath).existsSync()) {
          savedPath = relativePath;
        } else if (File(_defaultModelPath).existsSync()) {
          savedPath = _defaultModelPath;
        }
      }

      if (savedPath != null && File(savedPath).existsSync()) {
        print('Auto-loading model from: $savedPath');
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
        );
        return true;
      }

      state = state.copyWith(
        status: ModelStatus.notInstalled,
        statusMessage: 'Model not installed',
      );
      return false;
    } catch (e) {
      print('checkIfInstalled error: $e');
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
          .fromNetwork(_huggingFaceBaseUrl, token: huggingFaceToken)
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

      print('LLM Setup: Starting installation of ($fileType) from: $filePath');
      print(
        'LLM Setup: This may take a minute as the model is copied to internal storage...',
      );

      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: fileType,
      ).fromFile(filePath).install();

      print('LLM Setup: Installation call completed.');

      // Save this path as the last used one
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUsedModelKey, filePath);

      print('LLM Setup: SharedPreferences updated.');

      state = state.copyWith(
        status: ModelStatus.ready,
        statusMessage: 'Model installed from local file',
        downloadProgress: 1.0,
      );
    } catch (e) {
      print('LLM Setup: installFromLocalFile error: $e');
      state = state.copyWith(
        status: ModelStatus.error,
        errorMessage: e.toString(),
        statusMessage: 'Installation failed',
      );
    }
  }
}
