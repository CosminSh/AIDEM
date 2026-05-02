import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

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
  static const String _modelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it.litertlm';
  static const String _modelFileName = 'gemma3-1b-it.litertlm';

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
      // First check if the specific Gemma 3 model is installed
      final isGemma3Installed = await FlutterGemma.isModelInstalled(_modelFileName);
      
      // Also check if there's any active inference model already configured
      final hasActive = FlutterGemma.hasActiveModel();

      if (isGemma3Installed || hasActive) {
        state = state.copyWith(status: ModelStatus.ready, statusMessage: 'Model ready');
        return true;
      }
      
      state = state.copyWith(status: ModelStatus.notInstalled, statusMessage: 'Model not installed');
      return false;
    } catch (e) {
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
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromNetwork(
        _modelUrl,
        token: huggingFaceToken,
      ).withProgress((progress) {
        // progress is an int representing percentage (0-100)
        final p = (progress as int);
        state = state.copyWith(
          downloadProgress: p / 100.0,
          statusMessage: 'Downloading Gemma ($p%)...',
        );
      }).install();

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
      statusMessage: 'Installing from local file...',
    );

    try {
      final pathLower = filePath.toLowerCase();
      final fileType = pathLower.endsWith('.bin') || pathLower.endsWith('.tflite')
          ? ModelFileType.binary
          : (pathLower.endsWith('.litertlm') ? ModelFileType.litertlm : ModelFileType.task);

      print('Installing model ($fileType) from: $filePath');
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: fileType,
      ).fromFile(filePath).install();
      
      print('Installation successful');

      state = state.copyWith(
        status: ModelStatus.ready,
        statusMessage: 'Model installed from local file',
        downloadProgress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        status: ModelStatus.error,
        errorMessage: e.toString(),
        statusMessage: 'Installation failed',
      );
    }
  }
}
