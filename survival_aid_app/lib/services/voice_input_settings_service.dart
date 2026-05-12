import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VoiceInputMode { automatic, offlineVosk, nativeSystem }

class VoiceInputSettingsState {
  final VoiceInputMode mode;
  final bool debugEnabled;
  final String? inputDeviceId;
  final String? inputDeviceLabel;

  const VoiceInputSettingsState({
    this.mode = VoiceInputMode.automatic,
    this.debugEnabled = true,
    this.inputDeviceId,
    this.inputDeviceLabel,
  });

  VoiceInputSettingsState copyWith({
    VoiceInputMode? mode,
    bool? debugEnabled,
    String? inputDeviceId,
    String? inputDeviceLabel,
    bool clearInputDevice = false,
  }) {
    return VoiceInputSettingsState(
      mode: mode ?? this.mode,
      debugEnabled: debugEnabled ?? this.debugEnabled,
      inputDeviceId: clearInputDevice
          ? null
          : (inputDeviceId ?? this.inputDeviceId),
      inputDeviceLabel: clearInputDevice
          ? null
          : (inputDeviceLabel ?? this.inputDeviceLabel),
    );
  }
}

class VoiceInputSettingsService extends Notifier<VoiceInputSettingsState> {
  static const String _modeKey = 'aidem_voice_input_mode';
  static const String _debugKey = 'aidem_voice_input_debug_enabled';
  static const String _deviceIdKey = 'aidem_voice_input_device_id';
  static const String _deviceLabelKey = 'aidem_voice_input_device_label';

  @override
  VoiceInputSettingsState build() {
    _restore();
    return const VoiceInputSettingsState();
  }

  Future<void> setMode(VoiceInputMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<void> setDebugEnabled(bool enabled) async {
    state = state.copyWith(debugEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugKey, enabled);
  }

  Future<void> setInputDevice({String? id, String? label}) async {
    state = state.copyWith(
      inputDeviceId: id,
      inputDeviceLabel: label,
      clearInputDevice: id == null,
    );
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_deviceIdKey);
      await prefs.remove(_deviceLabelKey);
      return;
    }
    await prefs.setString(_deviceIdKey, id);
    await prefs.setString(_deviceLabelKey, label ?? id);
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeName = prefs.getString(_modeKey);
      final inputDeviceId = prefs.getString(_deviceIdKey);
      final inputDeviceLabel = prefs.getString(_deviceLabelKey);
      final restoredMode = VoiceInputMode.values.firstWhere(
        (mode) => mode.name == modeName,
        orElse: () => VoiceInputMode.automatic,
      );
      final debugEnabled = prefs.getBool(_debugKey) ?? true;
      state = VoiceInputSettingsState(
        mode: restoredMode,
        debugEnabled: debugEnabled,
        inputDeviceId: inputDeviceId,
        inputDeviceLabel: inputDeviceLabel,
      );
    } catch (_) {
      state = const VoiceInputSettingsState();
    }
  }
}
