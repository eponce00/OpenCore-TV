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

import 'package:opencore_tv/actions.dart';
import 'package:opencore_tv/providers/apps_service.dart';
import 'package:opencore_tv/providers/appearance_service.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/providers/launcher_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'opencore_tv.dart';

class OpenCoreTVApp extends StatelessWidget {
  static const PrioritizedIntents _backIntents =
      PrioritizedIntents(orderedIntents: [DismissIntent(), BackIntent()]);

  const OpenCoreTVApp();

  @override
  Widget build(BuildContext context) {
    AppsService appsService = context.read<AppsService>();
    LauncherState launcherState = context.read<LauncherState>();
    launcherState.refresh(appsService);

    return Selector2<SettingsService, AppearanceService,
            ({Color accentColor, bool light})>(
        selector: (_, settings, appearance) => (
              accentColor: settings.accentColor,
              light: appearance.isLight,
            ),
        builder: (context, appearance, _) {
          final accentColor = appearance.accentColor;
          final isLight = appearance.light;
          final schemeBrightness = isLight ? Brightness.light : Brightness.dark;
          final openCoreColors =
              isLight ? OpenCoreThemeColors.light : OpenCoreThemeColors.dark;
          final surface = openCoreColors.panel;
          final background = openCoreColors.page;
          final baseTextTheme = isLight
              ? Typography.material2018().black
              : Typography.material2018().white;
          return MaterialApp(
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              overscroll: false,
            ),
            shortcuts: {
              ...WidgetsApp.defaultShortcuts,
              const SingleActivator(LogicalKeyboardKey.escape): _backIntents,
              const SingleActivator(LogicalKeyboardKey.gameButtonB):
                  _backIntents,
              const SingleActivator(LogicalKeyboardKey.select):
                  const ActivateIntent()
            },
            actions: {
              ...WidgetsApp.defaultActions,
              BackIntent: BackAction(context),
              DirectionalFocusIntent:
                  SoundFeedbackDirectionalFocusAction(context)
            },
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            title: 'OpenCore TV',
            theme: ThemeData(
              useMaterial3: true,
              brightness: schemeBrightness,
              // Use ColorScheme based on accent color
              colorScheme: ColorScheme.fromSeed(
                seedColor: accentColor,
                brightness: schemeBrightness,
                primary: accentColor,
                secondary: accentColor,
                surface: surface,
                background: background,
              ),
              cardColor: surface,
              canvasColor: background,
              dialogBackgroundColor: surface,
              scaffoldBackgroundColor: background,
              textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                foregroundColor: openCoreColors.text,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              )),
              extensions: <ThemeExtension<dynamic>>[
                openCoreColors,
              ],
              dialogTheme: DialogTheme(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                backgroundColor: openCoreColors.panel,
                titleTextStyle: baseTextTheme.titleLarge
                    ?.copyWith(color: openCoreColors.text),
                contentTextStyle: baseTextTheme.bodyMedium
                    ?.copyWith(color: openCoreColors.text),
              ),
              appBarTheme: const AppBarTheme(
                  elevation: 0, backgroundColor: Colors.transparent),
              typography: Typography.material2018(),
              textTheme: baseTextTheme.apply(
                bodyColor: openCoreColors.text,
                displayColor: openCoreColors.text,
              ),
              inputDecorationTheme: InputDecorationTheme(
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: openCoreColors.text)),
                labelStyle: baseTextTheme.bodyMedium
                    ?.copyWith(color: openCoreColors.text),
              ),
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: accentColor,
                selectionColor: accentColor.withOpacity(0.4),
                selectionHandleColor: accentColor,
              ),
              // Override indicator colors for focus
              indicatorColor: accentColor,
              progressIndicatorTheme:
                  ProgressIndicatorThemeData(color: accentColor),
              sliderTheme: SliderThemeData(
                activeTrackColor: accentColor,
                thumbColor: accentColor,
                inactiveTrackColor: accentColor.withOpacity(0.3),
              ),
              toggleButtonsTheme: ToggleButtonsThemeData(
                selectedColor: accentColor,
                fillColor: accentColor.withOpacity(0.1),
              ),
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return accentColor;
                  return null;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected))
                    return accentColor.withOpacity(0.5);
                  return null;
                }),
              ),
            ),
            home: Builder(
                builder: (context) => PopScope(
                    canPop: false,
                    child: ExcludeSemantics(
                      child: OpenCoreTV(),
                    ),
                    onPopInvoked: (didPop) {
                      LauncherState launcherState =
                          context.read<LauncherState>();
                      launcherState.handleBackNavigation(context);
                    })),
          );
        });
  }
}
