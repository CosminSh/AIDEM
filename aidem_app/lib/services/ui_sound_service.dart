import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UiSoundState {
  final bool enabled;
  final bool loaded;

  const UiSoundState({required this.enabled, required this.loaded});

  UiSoundState copyWith({bool? enabled, bool? loaded}) {
    return UiSoundState(
      enabled: enabled ?? this.enabled,
      loaded: loaded ?? this.loaded,
    );
  }
}

class UiSoundSettingsService extends Notifier<UiSoundState> {
  static const _enabledKey = 'ui_sounds_enabled';

  @override
  UiSoundState build() {
    _load();
    return const UiSoundState(enabled: true, loaded: false);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? true;
    UiSoundService.setEnabled(enabled);
    state = state.copyWith(enabled: enabled, loaded: true);
  }

  Future<void> setEnabled(bool enabled) async {
    UiSoundService.setEnabled(enabled);
    state = state.copyWith(enabled: enabled, loaded: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
}

class UiSoundService {
  static DateTime? _lastPlayedAt;
  static bool _enabled = true;

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  static void tap() {
    if (!_enabled) {
      return;
    }

    final now = DateTime.now();
    final lastPlayedAt = _lastPlayedAt;
    if (lastPlayedAt != null &&
        now.difference(lastPlayedAt) < const Duration(milliseconds: 45)) {
      return;
    }

    _lastPlayedAt = now;
    unawaited(SystemSound.play(SystemSoundType.click));
  }

  static void confirm() => tap();

  static void toggle() => tap();
}
