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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const longPressableKeys = [
  LogicalKeyboardKey.select,
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.gameButtonA,
];

const menuKeys = [
  LogicalKeyboardKey.contextMenu,
  LogicalKeyboardKey.gameButtonStart,
];

class FocusKeyboardListener extends StatefulWidget {
  final Widget child;
  final KeyEventResult Function(LogicalKeyboardKey)? onPressed;
  final KeyEventResult Function(LogicalKeyboardKey)? onLongPress;

  FocusKeyboardListener({
    Key? key,
    required this.child,
    this.onPressed,
    this.onLongPress,
  }) : super(key: key);

  @override
  _FocusKeyboardListenerState createState() => _FocusKeyboardListenerState();
}

class _FocusKeyboardListenerState extends State<FocusKeyboardListener> {
  Timer? _longPressTimer;
  LogicalKeyboardKey? _heldKey;
  bool _longPressFired = false;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
        canRequestFocus: false,
        // Using "onKeyEvent", in favor of the deprecated "onKey"
        // seems to break the fix for issue #21 so, keep using the old property
        onKey: (_, rawKeyEvent) => _handleKey(context, rawKeyEvent),
        child: widget.child,
      );

  KeyEventResult _handleKey(BuildContext context, RawKeyEvent rawKeyEvent) {
    if (_isAndroidMenuKey(rawKeyEvent)) {
      if (rawKeyEvent is RawKeyDownEvent) {
        return widget.onLongPress?.call(LogicalKeyboardKey.contextMenu) ??
            KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }

    switch (rawKeyEvent.runtimeType) {
      case RawKeyDownEvent:
        return _keyDownEvent(context, rawKeyEvent.logicalKey);
      case RawKeyUpEvent:
        return _keyUpEvent(context, rawKeyEvent.logicalKey);
    }
    return KeyEventResult.handled;
  }

  bool _isAndroidMenuKey(RawKeyEvent event) {
    final data = event.data;
    return data is RawKeyEventDataAndroid && data.keyCode == 82;
  }

  KeyEventResult _keyDownEvent(BuildContext context, LogicalKeyboardKey key) {
    if (menuKeys.contains(key)) {
      return widget.onLongPress?.call(key) ?? KeyEventResult.ignored;
    }

    if (!longPressableKeys.contains(key)) {
      return widget.onPressed?.call(key) ?? KeyEventResult.ignored;
    }

    if (_heldKey == null) {
      _heldKey = key;
      _longPressFired = false;
      _longPressTimer?.cancel();
      _longPressTimer = Timer(const Duration(milliseconds: 550), () {
        if (!mounted || _heldKey == null) return;
        _longPressFired = true;
        widget.onLongPress?.call(_heldKey!);
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  KeyEventResult _keyUpEvent(BuildContext context, LogicalKeyboardKey key) {
    if (_heldKey == key) {
      _longPressTimer?.cancel();
      _heldKey = null;
      if (_longPressFired) {
        _longPressFired = false;
        return KeyEventResult.handled;
      }
      return widget.onPressed?.call(key) ?? KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }
}
