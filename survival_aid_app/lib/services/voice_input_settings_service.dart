import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VoiceInputMode { automatic, offlineVosk, nativeSystem }

class VoiceInputSettingsState {
  final VoiceInputMode mode;
  final bool debugEnabled;

  const VoiceInputSettingsState({
    this.mode = VoiceInputMode.automatic,
    this.debugEnabled = true,
  });

  VoiceInputSettingsState copyWith({VoiceInputMode? mode, bool? debugEnabled}) {
    return VoiceInputSettingsState(
      mode: mode ?? this.mode,
      debugEnabled: debugEnabled ?? this.debugEnabled,
    );
  }
}

class VoiceInputSettingsService extends Notifier<VoiceInputSettingsState> {
  static const String _modeKey = 'aidem_voice_input_mode';
  static const String _debugKey = 'aidem_voice_input_debug_enabled';

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

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeName = prefs.getString(_modeKey);
      final restoredMode = VoiceInputMode.values.firstWhere(
        (mode) => mode.name == modeName,
        orElse: () => VoiceInputMode.automatic,
      );
      final debugEnabled = prefs.getBool(_debugKey) ?? true;
      state = VoiceInputSettingsState(
        mode: restoredMode,
        debugEnabled: debugEnabled,
      );
    } catch (_) {
      state = const VoiceInputSettingsState();
    }
  }
}
