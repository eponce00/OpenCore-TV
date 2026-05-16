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

import 'package:opencore_tv/actions.dart';
import 'package:opencore_tv/app_image_type.dart';
import 'package:opencore_tv/providers/apps_service.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/widgets/application_info_panel.dart';
import 'package:opencore_tv/widgets/focus_keyboard_listener.dart';
import 'package:opencore_tv/widgets/input_tile_content.dart';
import 'package:opencore_tv/widgets/settings/input_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';
import '../models/category.dart';

const _validationKeys = [
  LogicalKeyboardKey.select,
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.gameButtonA
];

const _syntheticInputPackagePrefix = "opencore.input.";

class AppCard extends StatefulWidget {
  final App application;
  final Category category;
  final bool autofocus;
  final void Function(AxisDirection) onMove;
  final VoidCallback onMoveEnd;
  final bool Function()? shouldIgnoreActivation;
  final bool handleUpNavigationToSettings;
  final double scrollAlignment;
  final FocusNode? focusNode;

  const AppCard({
    super.key,
    required this.application,
    required this.category,
    required this.autofocus,
    required this.onMove,
    required this.onMoveEnd,
    this.shouldIgnoreActivation,
    this.handleUpNavigationToSettings = false,
    this.scrollAlignment = 0.5,
    this.focusNode,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  bool _moving = false;
  bool _clicked = false;
  bool _isFocused = false;
  bool _isTraditionalHighlightMode = false;
  bool _isHighlightAnimating = false;
  DateTime? _lastMoveAt;
  DateTime? _lastEnsureVisibleAt;
  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  // late Future<(AppImageType, ImageProvider)> _appImageLoadFuture;
  (AppImageType, ImageProvider)? _loadedImage;
  bool _imageLoadError = false;

  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(
      milliseconds: 1200,
    ),
  );

  late final CurvedAnimation _curvedAnimation =
      CurvedAnimation(parent: _animation, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _isTraditionalHighlightMode =
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

    FocusManager.instance.addHighlightModeListener(_focusHighlightModeChanged);
    if (!_isInputTile) {
      _loadAppImage(Provider.of<AppsService>(context, listen: false));
    }

    // Check if we need to restore focus/reorder mode after a move
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appsService = Provider.of<AppsService>(context, listen: false);
      if (appsService.pendingReorderFocusPackage ==
              widget.application.packageName &&
          appsService.pendingReorderFocusCategoryId == widget.category.id) {
        appsService.clearPendingReorderFocusPackage();
        _focusNode.requestFocus();

        setState(() {
          _moving = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(AppCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final appsService = Provider.of<AppsService>(context, listen: false);
    if (_isInputTile) {
      _loadedImage = null;
      _imageLoadError = false;
    } else if (oldWidget.application.packageName !=
        widget.application.packageName) {
      _loadedImage = null;
      _imageLoadError = false;
      _loadAppImage(appsService);
    } else if (appsService.consumeDirtyImage(widget.application.packageName)) {
      _loadAppImage(appsService);
    }

    if (oldWidget.focusNode != widget.focusNode) {
      if (_ownsFocusNode) {
        _focusNode.dispose();
      }
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
    }

    // Check for pending focus on update as well
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appsService = Provider.of<AppsService>(context, listen: false);
      if (appsService.pendingReorderFocusPackage ==
              widget.application.packageName &&
          appsService.pendingReorderFocusCategoryId == widget.category.id) {
        appsService.clearPendingReorderFocusPackage();
        _focusNode.requestFocus();

        if (!_moving) {
          setState(() {
            _moving = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    FocusManager.instance
        .removeHighlightModeListener(_focusHighlightModeChanged);
    _curvedAnimation.dispose();
    _animation.dispose();
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bool showAppNames =
        context.select<SettingsService, bool>((s) => s.showAppNamesBelowIcons);
    final appImageWidget = _appImage();
    final bool shouldHighlight = _shouldHighlight();

    return Actions(
      actions: <Type, Action<Intent>>{
        RemoteMenuIntent: CallbackAction<RemoteMenuIntent>(
          onInvoke: (_) {
            _showPanel();
            return null;
          },
        ),
      },
      child: FocusKeyboardListener(
        onPressed: _onPressed,
        onLongPress: _onLongPress,
        child: AnimatedScale(
          scale: _clicked ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _clicked ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: RepaintBoundary(
                      child: AnimatedScale(
                        scale: !_moving && shouldHighlight ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        alignment: Alignment.center,
                        curve: Curves.easeInOut,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.elevated,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (isLight)
                                BoxShadow(
                                  color: colors.shadow,
                                  blurRadius: shouldHighlight ? 18 : 10,
                                  offset: Offset(0, shouldHighlight ? 8 : 4),
                                ),
                            ],
                          ),
                          child: Material(
                            color: colors.elevated,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            elevation: 0,
                            shadowColor: colors.shadow,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                InkWell(
                                  focusNode: _focusNode,
                                  autofocus: widget.autofocus,
                                  focusColor: Colors.transparent,
                                  child: appImageWidget,
                                  onTap: () =>
                                      _onPressed(LogicalKeyboardKey.enter),
                                  onLongPress: () =>
                                      _onLongPress(LogicalKeyboardKey.enter),
                                  onFocusChange: (focused) {
                                    _handleFocusChange(context, focused);
                                  },
                                ),
                                if (_moving) ..._arrows(),
                                if (!isLight)
                                  IgnorePointer(
                                    child: AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      opacity: shouldHighlight ? 0.0 : 1.0,
                                      child: ColoredBox(
                                          color: colors.cardScrim
                                              .withOpacity(0.25)),
                                    ),
                                  ),
                                IgnorePointer(
                                  child: _BaseCardOutline(
                                    color: colors.line,
                                    width: isLight ? 1.2 : 0.6,
                                  ),
                                ),
                                Selector<SettingsService, bool>(
                                  selector: (_, settingsService) =>
                                      settingsService
                                          .appHighlightAnimationEnabled,
                                  builder: (context, settings, _) {
                                    final animationEnabled = settings;
                                    final accentColor =
                                        context.openCoreFocusRing;
                                    _setHighlightAnimation(
                                        shouldHighlight && animationEnabled);

                                    if (shouldHighlight) {
                                      if (animationEnabled) {
                                        return AnimatedBuilder(
                                          animation: _curvedAnimation,
                                          child: IgnorePointer(
                                            child: RepaintBoundary(
                                              child: _HighlightOutline(
                                                  color: accentColor),
                                            ),
                                          ),
                                          builder: (context, child) {
                                            final opacity =
                                                0.4 + (_animation.value * 0.6);
                                            return Opacity(
                                                opacity: opacity, child: child);
                                          },
                                        );
                                      } else {
                                        return IgnorePointer(
                                          child: RepaintBoundary(
                                            child: _HighlightOutline(
                                                color: accentColor),
                                          ),
                                        );
                                      }
                                    }

                                    return const SizedBox();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (showAppNames)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: _AppNameLabel(name: widget.application.name),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _isInputTile =>
      widget.application.packageName.startsWith(_syntheticInputPackagePrefix);

  Future<void> _loadAppImage(AppsService service) async {
    try {
      Uint8List bytes = Uint8List(0);

      bytes = await service.getAppBanner(widget.application.packageName);
      AppImageType type = AppImageType.Banner;
      if (bytes.isEmpty) {
        type = AppImageType.Icon;
        bytes = await service.getAppIcon(widget.application.packageName);
      }
      if (mounted) {
        final resizeWidth = type == AppImageType.Banner ? 960 : 384;
        setState(() {
          _loadedImage =
              (type, ResizeImage(MemoryImage(bytes), width: resizeWidth));
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _imageLoadError = true);
      }
    }
  }

  Widget _appImage() {
    App app = widget.application;

    if (_isInputTile) {
      return _inputTileContent();
    }

    if (_loadedImage != null) {
      final (type, image) = _loadedImage!;
      if (type == AppImageType.Banner) {
        return Ink.image(image: image, fit: BoxFit.cover);
      } else {
        final colors = context.openCoreColors;
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.cardScrim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Ink.image(
                      image: image,
                      height: double.maxFinite,
                    ),
                  ),
                ),
              ),
              Flexible(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    app.name,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } else if (_imageLoadError) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
            child: Text(
          app.name,
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        )),
      );
    } else {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 0, width: 16),
            Text("Loading")
          ],
        ),
      );
    }
    // Old way to load app images
    // return FutureBuilder(
    //   future: _appImageLoadFuture,
    //   builder: (context, snapshot) {
    //     if (snapshot.hasData) {
    //       (AppImageType, ImageProvider) record = snapshot.data!;
    //
    //       if (record.$1 == AppImageType.Banner) {
    //         return Ink.image(image: record.$2, fit: BoxFit.cover);
    //       }
    //       else {
    //         return Padding(
    //           padding: const EdgeInsets.all(8),
    //           child: Row(
    //             children: [
    //               Expanded(
    //                 flex: 2,
    //                 child: Ink.image(
    //                   image: record.$2,
    //                   height: double.maxFinite,
    //                 ),
    //               ),
    //               Flexible(
    //                 flex: 3,
    //                 child: Padding(
    //                   padding: const EdgeInsets.only(left: 8),
    //                   child: Text(
    //                     app.name,
    //                     style: Theme.of(context).textTheme.bodySmall,
    //                     overflow: TextOverflow.ellipsis,
    //                     maxLines: 3,
    //                   ),
    //                 ),
    //               ),
    //             ],
    //           ),
    //         );
    //       }
    //     }
    //     else if (snapshot.hasError) {
    //       return Padding(
    //         padding: const EdgeInsets.all(8),
    //         child: Center(
    //           child: Text(
    //             app.name,
    //             style: Theme.of(context).textTheme.bodySmall,
    //             overflow: TextOverflow.ellipsis,
    //             maxLines: 3,
    //           )
    //         ),
    //       );
    //     }
    //     else {
    //       return const Padding(
    //         padding: EdgeInsets.all(8),
    //         child: Row(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             CircularProgressIndicator(),
    //             SizedBox(height: 0, width: 16),
    //             Text("Loading")
    //           ],
    //         ),
    //       );
    //     }
    //   }
    // );
  }

  Widget _inputTileContent() {
    final settings = context.watch<SettingsService>();
    final packageName = widget.application.packageName;
    final label = settings.inputLabel(
      packageName,
      settings.defaultInputLabel(packageName),
    );
    final icon = OpenCoreInputConfig.iconData(settings.inputIcon(packageName));

    return InputTileContent(
      icon: icon,
      label: label,
      focused: _shouldHighlight(),
      dense: true,
    );
  }

  void _focusHighlightModeChanged(FocusHighlightMode mode) {
    final nextMode = mode == FocusHighlightMode.traditional;
    if (nextMode == _isTraditionalHighlightMode) {
      return;
    }
    setState(() {
      _isTraditionalHighlightMode = nextMode;
    });
  }

  bool _shouldHighlight() {
    return _isTraditionalHighlightMode && _isFocused;
  }

  void _handleFocusChange(BuildContext context, bool focused) {
    if (_isFocused != focused) {
      setState(() {
        _isFocused = focused;
      });
    }

    if (!focused) {
      return;
    }

    final now = DateTime.now();
    if (_lastEnsureVisibleAt != null &&
        now.difference(_lastEnsureVisibleAt!).inMilliseconds < 120) {
      return;
    }
    _lastEnsureVisibleAt = now;
    _ensureVisibleIfNeeded(
      context,
      // This specific alignment value is not only
      // to center the focused card in the row while
      // scrolling, but to prevent the topmost category
      // title to be hidden by the content above it when
      // scrolling from the app bar. How it relates to this,
      // I don't know
      alignment: widget.scrollAlignment,
    );
  }

  void _setHighlightAnimation(bool shouldAnimate) {
    if (_isHighlightAnimating == shouldAnimate) {
      return;
    }
    _isHighlightAnimating = shouldAnimate;
    if (shouldAnimate) {
      _animation.repeat(reverse: true);
    } else {
      _animation.stop();
    }
  }

  void _ensureVisibleIfNeeded(BuildContext context,
      {required double alignment}) {
    final renderObject = context.findRenderObject();
    final scrollable = Scrollable.maybeOf(context);
    if (renderObject == null || scrollable == null) {
      return;
    }

    final viewport = RenderAbstractViewport.of(renderObject);
    if (viewport == null) {
      return;
    }

    final position = scrollable.position;
    final targetOffset =
        viewport.getOffsetToReveal(renderObject, alignment).offset;
    const minDeltaToScroll = 24.0;
    if ((targetOffset - position.pixels).abs() < minDeltaToScroll) {
      return;
    }

    Scrollable.ensureVisible(
      context,
      alignment: alignment,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 220),
    );
  }

  List<Widget> _arrows() {
    final arrows = <Widget>[
      _arrow(Alignment.centerLeft, Icons.keyboard_arrow_left, () {
        widget.onMove(AxisDirection.left);
      }),
      _arrow(Alignment.centerRight, Icons.keyboard_arrow_right, () {
        widget.onMove(AxisDirection.right);
      }),
    ];

    // Only show Up/Down arrows for grid layouts
    if (widget.category.type == CategoryType.grid) {
      arrows.add(_arrow(Alignment.topCenter, Icons.keyboard_arrow_up, () {
        widget.onMove(AxisDirection.up);
      }));
      arrows.add(_arrow(Alignment.bottomCenter, Icons.keyboard_arrow_down, () {
        widget.onMove(AxisDirection.down);
      }));
    }

    return arrows;
  }

  Widget _arrow(Alignment alignment, IconData icon, VoidCallback onTap) =>
      Align(
          alignment: alignment,
          child: Ink(
              decoration: ShapeDecoration(
                  color: context.openCoreColors.focusFill,
                  shape: const CircleBorder()),
              child: SizedBox(
                  height: 36,
                  width: 36,
                  child: IconButton(
                      icon: Icon(icon,
                          size: 24, color: context.openCoreColors.focusText),
                      onPressed: onTap,
                      padding: EdgeInsets.all(0)))));

  KeyEventResult _onPressed(LogicalKeyboardKey? key) {
    if (_moving) {
      if (_validationKeys.contains(key) || key == LogicalKeyboardKey.escape) {
        _lastMoveAt = null;
        setState(() => _moving = false);
        widget.onMoveEnd();
      } else {
        final now = DateTime.now();
        if (_lastMoveAt != null &&
            now.difference(_lastMoveAt!).inMilliseconds < 60) {
          return KeyEventResult.handled;
        }

        if (key == LogicalKeyboardKey.arrowLeft) {
          widget.onMove(AxisDirection.left);
        } else if (key == LogicalKeyboardKey.arrowUp) {
          widget.onMove(AxisDirection.up);
        } else if (key == LogicalKeyboardKey.arrowRight) {
          widget.onMove(AxisDirection.right);
        } else if (key == LogicalKeyboardKey.arrowDown) {
          widget.onMove(AxisDirection.down);
        } else {
          return KeyEventResult.ignored;
        }

        _lastMoveAt = now;
        final nowForScroll = DateTime.now();
        if (_lastEnsureVisibleAt == null ||
            nowForScroll.difference(_lastEnsureVisibleAt!).inMilliseconds >=
                120) {
          _lastEnsureVisibleAt = nowForScroll;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _ensureVisibleIfNeeded(context, alignment: 0.1),
          );
        }
      }

      return KeyEventResult.handled;
    } else if (_validationKeys.contains(key)) {
      if (WakeInputSuppressor.shouldSuppress(key: key) ||
          (widget.shouldIgnoreActivation?.call() ?? false)) {
        return KeyEventResult.handled;
      }
      if (!_clicked) {
        setState(() => _clicked = true);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          context.read<AppsService>().launchApp(widget.application);
          // Reset after a short delay so it looks normal when user returns
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() => _clicked = false);
            }
          });
        });
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp &&
        widget.handleUpNavigationToSettings) {
      Actions.invoke(context, const MoveFocusToSettingsIntent());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onLongPress(LogicalKeyboardKey? key) {
    if (!_moving && (key == null || longPressableKeys.contains(key))) {
      _showPanel();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _showPanel() async {
    final result = await showDialog<ApplicationInfoPanelResult>(
      context: context,
      builder: (context) => ApplicationInfoPanel(
        category: widget.category,
        application: widget.application,
      ),
    );
    if (result == ApplicationInfoPanelResult.reorderApp) {
      setState(() => _moving = true);
    }
  }
}

class _AppNameLabel extends StatelessWidget {
  final String name;

  const _AppNameLabel({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: TextAlign.center,
    );
  }
}

class _HighlightOutline extends StatelessWidget {
  final Color color;

  const _HighlightOutline({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color,
              width: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _BaseCardOutline extends StatelessWidget {
  final Color color;
  final double width;

  const _BaseCardOutline({required this.color, required this.width});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: width),
      ),
    );
  }
}
