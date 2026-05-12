import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/global_providers.dart';
import '../../services/voice_input_settings_service.dart';
import '../../services/vosk_speech_service.dart';
import 'tactical_container.dart';

class VoiceDiagnosticsPanel extends ConsumerStatefulWidget {
  const VoiceDiagnosticsPanel({super.key});

  @override
  ConsumerState<VoiceDiagnosticsPanel> createState() =>
      _VoiceDiagnosticsPanelState();
}

class _VoiceDiagnosticsPanelState extends ConsumerState<VoiceDiagnosticsPanel> {
  bool _isChecking = false;
  bool _isProbingMic = false;
  List<_DiagnosticRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    if (_isChecking) {
      return;
    }

    setState(() => _isChecking = true);
    final rows = <_DiagnosticRow>[];

    rows.add(
      _DiagnosticRow(
        label: 'Platform',
        value: Platform.operatingSystem,
        color: AppColors.brandAi,
      ),
    );

    final recorder = AudioRecorder();
    try {
      final hasMicPermission = await recorder.hasPermission(request: false);
      final devices = hasMicPermission
          ? await recorder.listInputDevices()
          : const <InputDevice>[];
      rows.add(
        _DiagnosticRow(
          label: 'Microphone',
          value: hasMicPermission
              ? devices.isEmpty
                    ? 'Permission OK'
                    : '${devices.length} input device(s)'
              : 'Permission not granted',
          color: hasMicPermission ? AppColors.brandAi : AppColors.accentRed,
        ),
      );
    } catch (e) {
      rows.add(
        _DiagnosticRow(
          label: 'Microphone',
          value: 'Check failed: $e',
          color: AppColors.accentRed,
        ),
      );
    } finally {
      await recorder.dispose();
    }

    final nativeSpeech = ref.read(speechServiceProvider);
    rows.add(
      _DiagnosticRow(
        label: 'Native speech input',
        value: nativeSpeech.isAvailable
            ? 'Available'
            : nativeSpeech.error ?? 'Not initialized or unavailable',
        color: nativeSpeech.isAvailable ? AppColors.brandAi : AppColors.warning,
      ),
    );

    final voskReady = await ref
        .read(voskSpeechProvider.notifier)
        .prepare(allowDownload: false);
    final voskState = ref.read(voskSpeechProvider);
    rows.add(
      _DiagnosticRow(
        label: 'Offline Vosk input',
        value: voskReady
            ? 'Ready'
            : voskState.error ?? 'Model not installed yet',
        color: voskReady ? AppColors.brandAi : AppColors.warning,
      ),
    );

    rows.add(await _checkFlutterTts());
    if (Platform.isWindows) {
      rows.add(await _checkWindowsSapiVoices());
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _rows = rows;
      _isChecking = false;
    });
  }

  Future<_DiagnosticRow> _checkFlutterTts() async {
    try {
      final tts = FlutterTts();
      final languages = await tts.getLanguages;
      final count = languages is List ? languages.length : 0;
      return _DiagnosticRow(
        label: 'TTS engine',
        value: count > 0 ? '$count voice language(s)' : 'No voices reported',
        color: count > 0 ? AppColors.brandAi : AppColors.warning,
      );
    } catch (e) {
      return _DiagnosticRow(
        label: 'TTS engine',
        value: 'Check failed: $e',
        color: AppColors.warning,
      );
    }
  }

  Future<_DiagnosticRow> _checkWindowsSapiVoices() async {
    try {
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        "Add-Type -AssemblyName System.Speech; \$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; (\$s.GetInstalledVoices() | Where-Object { \$_.Enabled }).Count; \$s.Dispose()",
      ]).timeout(const Duration(seconds: 8));

      final count = int.tryParse(result.stdout.toString().trim()) ?? 0;
      return _DiagnosticRow(
        label: 'Windows SAPI voices',
        value: count > 0 ? '$count desktop voice(s)' : 'No desktop voices',
        color: count > 0 ? AppColors.brandAi : AppColors.warning,
      );
    } catch (e) {
      return _DiagnosticRow(
        label: 'Windows SAPI voices',
        value: 'Check failed: $e',
        color: AppColors.warning,
      );
    }
  }

  Future<void> _prepareOfflineModel() async {
    await ref.read(voskSpeechProvider.notifier).prepare();
    await _refresh();
  }

  Future<void> _runMicProbe() async {
    if (_isProbingMic) {
      return;
    }
    setState(() => _isProbingMic = true);
    await ref.read(voskSpeechProvider.notifier).runMicrophoneProbe();
    if (!mounted) {
      return;
    }
    setState(() => _isProbingMic = false);
  }

  @override
  Widget build(BuildContext context) {
    final voskState = ref.watch(voskSpeechProvider);
    final voiceState = ref.watch(voiceServiceProvider);
    final inputSettings = ref.watch(voiceInputSettingsProvider);

    return TacticalContainer(
      padding: const EdgeInsets.all(18),
      showGlow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Voice diagnostics',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh voice diagnostics',
                onPressed: _isChecking ? null : _refresh,
                icon: _isChecking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (voiceState.errorMessage != null) ...[
            Text(
              voiceState.errorMessage!,
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SectionLabel(label: 'Input mode'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mode in VoiceInputMode.values)
                ChoiceChip(
                  selected: inputSettings.mode == mode,
                  label: Text(_modeLabel(mode)),
                  onSelected: (_) => ref
                      .read(voiceInputSettingsProvider.notifier)
                      .setMode(mode),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Show input debug data',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            value: inputSettings.debugEnabled,
            onChanged: (enabled) => ref
                .read(voiceInputSettingsProvider.notifier)
                .setDebugEnabled(enabled),
          ),
          for (final row in _rows) _DiagnosticTile(row: row),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: voskState.isPreparing ? null : _prepareOfflineModel,
              icon: voskState.isPreparing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_for_offline_outlined, size: 18),
              label: Text(
                voskState.modelReady
                    ? 'Refresh offline voice model'
                    : 'Prepare offline voice input',
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isProbingMic || voskState.isListening
                  ? null
                  : _runMicProbe,
              icon: _isProbingMic
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.graphic_eq_rounded, size: 18),
              label: const Text('Run microphone probe'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: voiceState.isSpeaking || voiceState.isInitializing
                  ? null
                  : () async {
                      await ref
                          .read(voiceServiceProvider.notifier)
                          .setEnabled(true);
                      await ref
                          .read(voiceServiceProvider.notifier)
                          .speakAiMessage(
                            'AIDEM voice output test. If you can hear this, text to speech is working.',
                          );
                    },
              icon: const Icon(Icons.volume_up_outlined, size: 18),
              label: const Text('Test voice output'),
            ),
          ),
          if (voskState.modelPath != null) ...[
            const SizedBox(height: 8),
            Text(
              voskState.modelPath!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
          if (inputSettings.debugEnabled) ...[
            const SizedBox(height: 14),
            const SectionLabel(label: 'Input debug'),
            const SizedBox(height: 8),
            _DebugGrid(voskState: voskState),
          ],
        ],
      ),
    );
  }

  String _modeLabel(VoiceInputMode mode) {
    switch (mode) {
      case VoiceInputMode.automatic:
        return 'Automatic';
      case VoiceInputMode.offlineVosk:
        return 'Offline Vosk';
      case VoiceInputMode.nativeSystem:
        return 'Native system';
    }
  }
}

class _DiagnosticRow {
  final String label;
  final String value;
  final Color color;

  const _DiagnosticRow({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _DebugGrid extends StatelessWidget {
  final VoskSpeechState voskState;

  const _DebugGrid({required this.voskState});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _DiagnosticRow(
        label: 'Status',
        value: voskState.debugStatus,
        color: AppColors.textSecondary,
      ),
      _DiagnosticRow(
        label: 'Chunks',
        value: '${voskState.chunksProcessed}',
        color: AppColors.brandAi,
      ),
      _DiagnosticRow(
        label: 'Bytes',
        value: '${voskState.bytesProcessed}',
        color: AppColors.brandAi,
      ),
      _DiagnosticRow(
        label: 'Peak',
        value: '${(voskState.lastPeak * 100).toStringAsFixed(1)}%',
        color: voskState.lastPeak > 0.02
            ? AppColors.brandAi
            : AppColors.warning,
      ),
      _DiagnosticRow(
        label: 'Accepted',
        value: '${voskState.acceptedResults}',
        color: AppColors.brandAi,
      ),
      _DiagnosticRow(
        label: 'Transcript',
        value: voskState.lastWords.isEmpty ? '-' : voskState.lastWords,
        color: voskState.lastWords.isEmpty
            ? AppColors.textMuted
            : AppColors.brandAi,
      ),
      _DiagnosticRow(
        label: 'Partial JSON',
        value: voskState.lastPartialJson.isEmpty
            ? '-'
            : voskState.lastPartialJson,
        color: AppColors.textMuted,
      ),
      _DiagnosticRow(
        label: 'Result JSON',
        value: voskState.lastResultJson.isEmpty
            ? '-'
            : voskState.lastResultJson,
        color: AppColors.textMuted,
      ),
    ];

    return Column(
      children: rows.map((row) => _DiagnosticTile(row: row)).toList(),
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  final _DiagnosticRow row;

  const _DiagnosticTile({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: row.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              row.value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                color: row.color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
