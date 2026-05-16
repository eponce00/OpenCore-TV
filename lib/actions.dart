/*
 * OpenCoreTV
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:opencore_tv/providers/apps_service.dart';
import 'package:opencore_tv/providers/launcher_state.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class WakeInputSuppressor {
  static DateTime? _suppressUntil;
  static LogicalKeyboardKey? _wakeKey;

  static void suppressFor(Duration duration, LogicalKeyboardKey wakeKey) {
    _suppressUntil = DateTime.now().add(duration);
    _wakeKey = wakeKey;
  }

  static bool shouldSuppress({LogicalKeyboardKey? key}) {
    final suppressUntil = _suppressUntil;
    if (suppressUntil == null) return false;
    if (DateTime.now().isAfter(suppressUntil)) {
      _suppressUntil = null;
      _wakeKey = null;
      return false;
    }

    // Directional focus intents do not carry the original key, so they are
    // suppressed during the whole wake window. Keyed activations are limited
    // to the key that woke the screensaver.
    return key == null || _wakeKey == null || key == _wakeKey;
  }
}

class SoundFeedbackDirectionalFocusAction extends DirectionalFocusAction {
  final BuildContext context;

  SoundFeedbackDirectionalFocusAction(this.context);

  @override
  void invoke(DirectionalFocusIntent intent) {
    if (WakeInputSuppressor.shouldSuppress()) {
      return;
    }

    super.invoke(intent);

    SettingsService settingsService = context.read<SettingsService>();
    if (settingsService.appKeyClickEnabled) {
      Feedback.forTap(context);
    } else {
      silentForTap(context);
    }
  }

  /// copied from Feedback.forTap, omitting playing a sound
  static void silentForTap(BuildContext context) async {
    context.findRenderObject()!.sendSemanticsEvent(const TapSemanticEvent());
  }
}

class BackAction extends Action<BackIntent> {
  final BuildContext context;

  BackAction(this.context);

  @override
  Future<void> invoke(BackIntent intent) async {
    NavigatorState? navigator = Navigator.maybeOf(context);

    if (navigator != null && await navigator.maybePop()) {
      return;
    }

    LauncherState state = context.read<LauncherState>();
    state.handleBackNavigation(context);
  }
}

class MoveFocusToSettingsIntent extends Intent {
  const MoveFocusToSettingsIntent();
}

class RemoteMenuIntent extends Intent {
  const RemoteMenuIntent();
}

class BackIntent extends Intent {
  const BackIntent();
}

Future<bool> isDefaultLauncher(BuildContext context) async =>
    await context.read<AppsService>().isDefaultLauncher();
