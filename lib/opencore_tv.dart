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

import 'dart:math';
import 'dart:async';
import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:opencore_tv/actions.dart';
import 'package:opencore_tv/custom_traversal_policy.dart';
import 'package:opencore_tv/opencore_tv_channel.dart';
import 'package:opencore_tv/providers/apps_service.dart';
import 'package:opencore_tv/providers/launcher_state.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/providers/wallpaper_service.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/widgets/app_card.dart';
import 'package:opencore_tv/widgets/category_clean_row.dart';
import 'package:opencore_tv/widgets/category_row.dart';
import 'package:opencore_tv/widgets/focus_aware_app_bar.dart';
import 'package:opencore_tv/widgets/idle_overlay.dart';
import 'package:opencore_tv/widgets/input_selector_dialog.dart';
import 'package:opencore_tv/widgets/weather_widget.dart';
import 'package:opencore_tv/widgets/wallpaper_video_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'models/app.dart';
import 'models/category.dart';

const _kDockOuterPadding = EdgeInsets.only(left: 12, right: 12, bottom: 6);

class OpenCoreTV extends StatefulWidget {
  const OpenCoreTV({super.key});

  @override
  State<OpenCoreTV> createState() => _OpenCoreTVState();
}

class _OpenCoreTVState extends State<OpenCoreTV> with WidgetsBindingObserver {
  final GlobalKey<FocusAwareAppBarState> _appBarKey = GlobalKey();
  final FocusNode _weatherFocusNode = FocusNode();
  final FocusNode _dockEndFocusNode = FocusNode();
  Timer? _idleTimer;
  SettingsService? _settingsService;
  Timer? _pendingEnterIdleTimer;
  bool _idle = false;
  bool _isResumed = true;
  bool _pendingEnterIdle = false;
  bool _inputSelectorOpen = false;
  LogicalKeyboardKey? _wakeConsumedKey;
  DateTime? _ignoreActivationUntil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    OpenCoreTVChannel.setEnterIdleListener(_enterIdleNow);
    OpenCoreTVChannel.setDismissPanelListener(_dismissTopPanel);
    OpenCoreTVChannel.setRemoteMenuListener(_openFocusedRemoteMenu);
    OpenCoreTVChannel.setInputSelectorListener(_showInputSelector);
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetIdleTimer());
  }

  @override
  void dispose() {
    OpenCoreTVChannel.setEnterIdleListener(null);
    OpenCoreTVChannel.setDismissPanelListener(null);
    OpenCoreTVChannel.setRemoteMenuListener(null);
    OpenCoreTVChannel.setInputSelectorListener(null);
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _settingsService?.removeListener(_resetIdleTimer);
    _weatherFocusNode.dispose();
    _dockEndFocusNode.dispose();
    _pendingEnterIdleTimer?.cancel();
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextSettingsService = context.read<SettingsService>();
    if (_settingsService != nextSettingsService) {
      _settingsService?.removeListener(_resetIdleTimer);
      _settingsService = nextSettingsService;
      _settingsService?.addListener(_resetIdleTimer);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isResumed = state == AppLifecycleState.resumed;
    _trace('lifecycle state=$state isResumed=$_isResumed idle=$_idle');

    if (_isResumed) {
      if (_pendingEnterIdle) {
        _pendingEnterIdle = false;
        _applyIdle();
        return;
      }
      _resetIdleTimer();
      return;
    }

    _idleTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _wakeFromIdle(),
        onPointerMove: (_) => _wakeFromIdle(),
        child: Actions(
          actions: <Type, Action<Intent>>{
            MoveFocusToSettingsIntent:
                CallbackAction<MoveFocusToSettingsIntent>(
              onInvoke: (_) => _appBarKey.currentState?.focusSettings(),
            ),
          },
          child: FocusTraversalGroup(
            policy: RowByRowTraversalPolicy(),
            child: Stack(
              children: [
                RepaintBoundary(
                  child: Consumer<WallpaperService>(
                    builder: (_, wallpaperService, __) =>
                        _wallpaper(context, wallpaperService),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _idle ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    appBar: FocusAwareAppBar(
                      key: _appBarKey,
                      onFocusWeather: () => _weatherFocusNode.requestFocus(),
                      onFocusDockEnd: () => _dockEndFocusNode.requestFocus(),
                    ),
                    body: Selector<AppsService, (bool, int)>(
                      selector: (_, service) =>
                          (service.initialized, service.layoutVersion),
                      builder: (context, data, _) {
                        if (data.$1) {
                          return _tvOSLayout(
                              context, context.read<AppsService>());
                        } else {
                          return _emptyState(context);
                        }
                      },
                    ),
                  ),
                ),
                if (!_idle)
                  Positioned(
                    top: 58,
                    right: 32,
                    child: WeatherWidget(
                      locationBelow: true,
                      focusNode: _weatherFocusNode,
                      onFocusLeft: () =>
                          _appBarKey.currentState?.focusNetwork(),
                      onFocusDown: () => _dockEndFocusNode.requestFocus(),
                    ),
                  ),
                AnimatedOpacity(
                  opacity: _idle ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  child: const IdleOverlay(),
                ),
                if (_inputSelectorOpen)
                  InputSelectorDialog(onClose: _closeInputSelector),
              ],
            ),
          ),
        ),
      );

  bool _handleHardwareKey(KeyEvent event) {
    final wakeConsumedKey = _wakeConsumedKey;
    if (wakeConsumedKey != null && event.logicalKey == wakeConsumedKey) {
      if (event is KeyUpEvent) {
        _wakeConsumedKey = null;
      }
      return true;
    }

    if (event is! KeyDownEvent) return false;

    if (_inputSelectorOpen) {
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.goBack ||
          event.logicalKey == LogicalKeyboardKey.browserBack ||
          event.logicalKey == LogicalKeyboardKey.gameButtonB ||
          event.logicalKey == LogicalKeyboardKey.home ||
          event.logicalKey == LogicalKeyboardKey.contextMenu ||
          event.logicalKey == LogicalKeyboardKey.gameButtonStart) {
        _closeInputSelector();
        return true;
      }
      _resetIdleTimer();
      return false;
    }

    if (_idle) {
      _wakeConsumedKey = event.logicalKey;
      WakeInputSuppressor.suppressFor(
        const Duration(milliseconds: 1000),
        event.logicalKey,
      );
      _ignoreActivationUntil = DateTime.now().add(
        const Duration(milliseconds: 1200),
      );
      _wakeFromIdle();
      return true;
    }

    _resetIdleTimer();
    return false;
  }

  bool _shouldIgnoreActivation() {
    if (WakeInputSuppressor.shouldSuppress()) return true;
    final until = _ignoreActivationUntil;
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _ignoreActivationUntil = null;
    return false;
  }

  void _wakeFromIdle() {
    _trace('wakeFromIdle idle=$_idle');
    if (_idle && mounted) {
      setState(() => _idle = false);
    }
    _resetIdleTimer();
  }

  void _enterIdleNow() {
    _trace('enterIdleNow mounted=$mounted isResumed=$_isResumed idle=$_idle');
    if (!mounted) return;
    final settings = context.read<SettingsService>();
    if (!settings.idleModeEnabled) {
      _trace('enterIdleNow rejected idleModeEnabled=false');
      return;
    }
    if (!_isResumed) {
      _pendingEnterIdle = true;
      _pendingEnterIdleTimer?.cancel();
      _pendingEnterIdleTimer = Timer(const Duration(milliseconds: 250), () {
        if (!mounted || !_pendingEnterIdle) return;
        _pendingEnterIdle = false;
        _applyIdle();
      });
      _trace('enterIdleNow queued with fallback timer');
      return;
    }
    _applyIdle();
  }

  void _applyIdle() {
    setState(() => _idle = true);
    _idleTimer?.cancel();
    _trace('applyIdle idle=true');
  }

  void _dismissTopPanel() {
    if (!mounted) return;
    if (_inputSelectorOpen) {
      _closeInputSelector();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _openFocusedRemoteMenu() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return;
    Actions.maybeInvoke(focusContext, const RemoteMenuIntent());
  }

  void _showInputSelector() {
    if (!mounted) return;
    if (_inputSelectorOpen) return;
    _wakeFromIdle();
    setState(() => _inputSelectorOpen = true);
    OpenCoreTVChannel().setPanelOpen(true);
  }

  void _closeInputSelector() {
    if (!_inputSelectorOpen) return;
    setState(() => _inputSelectorOpen = false);
    OpenCoreTVChannel().setPanelOpen(false);
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (!mounted) return;
    if (!_isResumed) return;
    if (_idle) return;

    final settings = context.read<SettingsService>();
    if (!settings.idleModeEnabled) return;

    _idleTimer = Timer(
      Duration(minutes: settings.idleTimeoutMinutes.clamp(1, 120)),
      () {
        if (mounted && _isResumed) {
          _trace('idle timer fired');
          setState(() => _idle = true);
        }
      },
    );
  }

  void _trace(String message) {
    developer.log(message, name: 'OpenCoreTrace');
  }

  Widget _tvOSLayout(BuildContext context, AppsService appsService) {
    final favoritesCategory =
        appsService.categories.firstWhereOrNull((c) => c.name == 'Favorites');
    final favoriteApps = favoritesCategory?.applications ?? const [];

    final otherSections = appsService.launcherSections.where((section) {
      if (section is Category && section.name == 'Favorites') return false;
      return true;
    }).toList();

    if (favoriteApps.isEmpty && otherSections.isEmpty)
      return _emptyState(context);

    return CustomScrollView(
      slivers: [
        if (favoriteApps.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight -
                  150,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: _kDockOuterPadding,
              child: _dock(
                context,
                favoritesCategory!,
                favoriteApps,
                appsService,
              ),
            ),
          ),
        ],
        ..._buildSectionSlivers(otherSections,
            firstCategoryAlreadyFound: favoriteApps.isNotEmpty),
        const SliverToBoxAdapter(child: SizedBox(height: 64)),
      ],
    );
  }

  List<Widget> _buildSectionSlivers(List<LauncherSection> sections,
      {bool firstCategoryAlreadyFound = false}) {
    final List<Widget> slivers = [];
    bool firstCategoryFound = firstCategoryAlreadyFound;

    for (final section in sections) {
      final Key sectionKey = Key(section.id.toString());

      if (section is LauncherSpacer) {
        slivers.add(SliverToBoxAdapter(
          key: sectionKey,
          child: SizedBox(height: section.height.toDouble()),
        ));
        continue;
      }

      final category = section as Category;
      final filteredApps = category.applications;
      if (filteredApps.isEmpty) continue;

      final bool isFirstSection = !firstCategoryFound;
      if (isFirstSection) firstCategoryFound = true;

      slivers.add(SliverToBoxAdapter(
        child: Selector<SettingsService, bool>(
          selector: (context, service) => service.showCategoryTitles,
          builder: (context, showTitle, _) {
            if (showTitle) {
              return Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 8, top: 8),
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ));

      switch (category.type) {
        case CategoryType.row:
          slivers.add(SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
              child: CategoryRow(
                key: sectionKey,
                category: category,
                applications: filteredApps,
                isFirstSection: isFirstSection,
                showTitle: false,
              ),
            ),
          ));
          break;
        case CategoryType.grid:
          slivers.add(SliverPadding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
            sliver: SliverGrid(
              key: sectionKey,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: category.columnsCount,
                childAspectRatio: 16 / 9,
                mainAxisSpacing: 12,
                crossAxisSpacing: 0,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: filteredApps.length,
                findChildIndexCallback: (Key key) {
                  final valueKey = key as ValueKey<String>;
                  final index = filteredApps.indexWhere(
                    (app) => app.packageName == valueKey.value,
                  );
                  return index >= 0 ? index : null;
                },
                (context, index) => Padding(
                  key: Key(filteredApps[index].packageName),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: AppCard(
                    category: category,
                    application: filteredApps[index],
                    autofocus: index == 0,
                    shouldIgnoreActivation: _shouldIgnoreActivation,
                    handleUpNavigationToSettings:
                        isFirstSection && index < category.columnsCount,
                    onMove: (direction) => _onGridMove(
                        context, category, index, direction, filteredApps),
                    onMoveEnd: () => context
                        .read<AppsService>()
                        .saveApplicationOrderInCategory(category),
                  ),
                ),
              ),
            ),
          ));
          break;
      }
    }

    return slivers;
  }

  // TO DO : refractor duplicate _onMove code
  void _onGridMove(BuildContext context, Category category, int index,
      AxisDirection direction, List<App> filteredApps) {
    final currentRow = (index / category.columnsCount).floor();
    final totalRows =
        ((filteredApps.length - 1) / category.columnsCount).floor();

    int? newIndex;
    switch (direction) {
      case AxisDirection.up:
        if (currentRow > 0) newIndex = index - category.columnsCount;
        break;
      case AxisDirection.right:
        if (index < filteredApps.length - 1) newIndex = index + 1;
        break;
      case AxisDirection.down:
        if (currentRow < totalRows)
          newIndex =
              min(index + category.columnsCount, filteredApps.length - 1);
        break;
      case AxisDirection.left:
        if (index > 0) newIndex = index - 1;
        break;
    }

    if (newIndex != null) {
      final appsService = context.read<AppsService>();
      final movingApp = filteredApps[index];
      final realOldIndex = category.applications.indexOf(movingApp);
      final realNewIndex =
          category.applications.indexOf(filteredApps[newIndex]);
      if (realOldIndex >= 0 && realNewIndex >= 0) {
        appsService.reorderApplication(category, realOldIndex, realNewIndex);
        appsService.setPendingReorderFocus(movingApp.packageName, category.id);
      }
    }
  }

  Widget _dock(
    BuildContext context,
    Category category,
    List<App> apps,
    AppsService appsService,
  ) {
    final colors = context.openCoreColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: colors.cardScrim,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.line, width: 1),
        boxShadow: [
          if (isLight)
            BoxShadow(
              color: colors.shadow,
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: CategoryCleanRow(
        category: category,
        applications: apps,
        isFirstSection: true,
        scrollAlignment: 1.0,
        endFocusNode: _dockEndFocusNode,
      ),
    );

    return Center(child: content);
  }

  Widget _wallpaper(BuildContext context, WallpaperService wallpaperService) {
    final physicalSize = MediaQuery.sizeOf(context);
    final videoFile = wallpaperService.wallpaperVideoFile;
    if (videoFile != null) {
      return SizedBox(
        width: physicalSize.width,
        height: physicalSize.height,
        child: WallpaperVideoBackground(
            key: Key("background_video"), file: videoFile),
      );
    }
    if (wallpaperService.wallpaper != null) {
      return Image(
        image: wallpaperService.wallpaper!,
        key: const Key("background"),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        height: physicalSize.height,
        width: physicalSize.width,
      );
    } else {
      return Container(
        key: const Key("background"),
        decoration: BoxDecoration(gradient: wallpaperService.gradient.gradient),
      );
    }
  }

  Widget _emptyState(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(localizations.loading,
              style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
