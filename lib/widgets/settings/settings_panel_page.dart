/*
 * OpenCoreTV
 * Copyright (C) 2021  Etienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:opencore_tv/providers/apps_service.dart';
import 'package:opencore_tv/widgets/settings/applications_panel_page.dart';
import 'package:opencore_tv/widgets/settings/general_settings_page.dart';
import 'package:opencore_tv/widgets/settings/home_display_settings_page.dart';
import 'package:opencore_tv/widgets/settings/idle_settings_page.dart';
import 'package:opencore_tv/widgets/settings/input_settings_page.dart';
import 'package:opencore_tv/widgets/settings/launcher_sections_panel_page.dart';
import 'package:opencore_tv/widgets/settings/native_device_settings_page.dart';
import 'package:opencore_tv/widgets/settings/opencore_about_dialog.dart';
import 'package:opencore_tv/widgets/settings/opencore_clock_settings_page.dart';
import 'package:opencore_tv/widgets/settings/opencore_health_page.dart';
import 'package:opencore_tv/widgets/settings/remote_buttons_settings_page.dart';
import 'package:opencore_tv/widgets/settings/wallpaper_panel_page.dart';
import 'package:opencore_tv/widgets/settings/weather_settings_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';

class SettingsPanelPage extends StatefulWidget {
  static const String routeName = "settings_panel";

  const SettingsPanelPage({super.key});

  @override
  State<SettingsPanelPage> createState() => _SettingsPanelPageState();
}

class _SettingsPanelPageState extends State<SettingsPanelPage> {
  late DateTime _now = DateTime.now();
  Timer? _clockTimer;
  bool? _homeGuardEnabled;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshHealth());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshHealth() async {
    final appsService = context.read<AppsService>();
    final profile = appsService.deviceProfile;
    final enabled = profile.supportsHomeGuard
        ? await appsService.isHomeGuardEnabled()
        : await appsService.isDefaultLauncher();
    if (!mounted) return;
    setState(() => _homeGuardEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final appsService = context.watch<AppsService>();
    final profile = appsService.deviceProfile;
    final guardHealthy = _homeGuardEnabled == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsHeader(now: _now),
        const SizedBox(height: 14),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel("OpenCore"),
                _SettingsListCard(
                  children: [
                    _ControlTile(
                      autofocus: true,
                      icon: Icons.bedtime_outlined,
                      title: "Idle",
                      subtitle: "Screensaver",
                      routeName: IdleSettingsPage.routeName,
                    ),
                    _ControlTile(
                      icon: Icons.input_outlined,
                      title: "Inputs",
                      subtitle: "HDMI labels and icons",
                      routeName: InputSettingsPage.routeName,
                    ),
                    _ControlTile(
                      icon: Icons.settings_remote_outlined,
                      title: "Remote Buttons",
                      subtitle: "Learn and assign remote shortcuts",
                      routeName: RemoteButtonsSettingsPage.routeName,
                    ),
                    _ControlTile(
                      icon: guardHealthy
                          ? Icons.verified_user_outlined
                          : Icons.warning_amber_rounded,
                      title: "Launcher Protection",
                      subtitle: guardHealthy
                          ? profile.supportsHomeGuard
                              ? "Home Guard active"
                              : "Default launcher"
                          : "Check setup",
                      routeName: OpenCoreHealthPage.routeName,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionLabel("Home"),
                _SettingsListCard(
                  children: [
                    _SettingsRow(
                      icon: Icons.view_week_outlined,
                      title: "Home Layout",
                      subtitle: "Rows, favorites, app sections",
                      routeName: LauncherSectionsPanelPage.routeName,
                    ),
                    _SettingsRow(
                      icon: Icons.tune_outlined,
                      title: "Home Display",
                      subtitle: "Clock, weather, visual options",
                      routeName: HomeDisplaySettingsPage.routeName,
                    ),
                    _SettingsRow(
                      icon: Icons.watch_later_outlined,
                      title: "Clock",
                      subtitle: "Home and idle clock style",
                      routeName: OpenCoreClockSettingsPage.routeName,
                    ),
                    _SettingsRow(
                      icon: Icons.cloud_outlined,
                      title: "Weather",
                      subtitle: "Location, units, provider",
                      routeName: WeatherSettingsPage.routeName,
                    ),
                    _SettingsRow(
                      icon: Icons.wallpaper_outlined,
                      title: "Wallpaper",
                      subtitle: "Library and rotation",
                      routeName: WallpaperPanelPage.routeName,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionLabel("Device"),
                _SettingsListCard(
                  children: [
                    _SettingsRow(
                      icon: Icons.apps,
                      title: "Apps",
                      subtitle: "Organize and manage installed apps",
                      routeName: ApplicationsPanelPage.routeName,
                    ),
                    _SettingsRow(
                      icon: Icons.settings_suggest_outlined,
                      title: "Device Tools",
                      subtitle: "Brightness, date/time, usage",
                      routeName: GeneralSettingsPage.routeName,
                    ),
                    _SettingsRow(
                      icon: Icons.wifi_outlined,
                      title: "System Settings",
                      subtitle: "${profile.label} settings sections",
                      routeName: NativeDeviceSettingsPage.routeName,
                    ),
                    _SettingsRow(
                      icon: Icons.info_outline,
                      title: "About OpenCore",
                      subtitle: "Version and license",
                      onPressed: _showAbout,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.done && snapshot.hasData
                ? OpenCoreTVAboutDialog(packageInfo: snapshot.data!)
                : const SizedBox.shrink(),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final DateTime now;

  const _SettingsHeader({required this.now});

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final accentLine = context.openCoreAccentFaint;
    final weekday = const [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun",
    ][now.weekday - 1];
    final month = const [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ][now.month - 1];
    final hour =
        now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, "0");
    final period = now.hour >= 12 ? "PM" : "AM";

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 14),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$weekday, $month ${now.day.toString().padLeft(2, "0")}",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$hour:$minute $period",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: colors.text,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 1,
                      color: accentLine,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Control Center",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.faintText,
                            fontSize: 13,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String routeName;
  final bool autofocus;

  const _ControlTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.routeName,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final focusedMuted = isLight ? colors.mutedText : colors.focusMutedText;
    return _PressableSurface(
      autofocus: autofocus,
      borderRadius: 18,
      onPressed: () => Navigator.of(context).pushNamed(routeName),
      builder: (context, focused) => _MenuRowSurface(
        focused: focused,
        child: Row(
          children: [
            Icon(
              icon,
              color: focused ? colors.focusText : context.openCoreAccentMuted,
              size: 19,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: focused ? colors.focusText : colors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: focused ? focusedMuted : colors.mutedText,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: focused ? colors.focusText : colors.faintText,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final labelColor =
        Color.lerp(colors.faintText, context.openCoreAccent, 0.18)!;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 7),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _SettingsListCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsListCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(color: colors.line),
          bottom: BorderSide(color: colors.line),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? routeName;
  final VoidCallback? onPressed;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.routeName,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final focusedMuted = isLight ? colors.mutedText : colors.focusMutedText;
    return _PressableSurface(
      borderRadius: 18,
      onPressed: onPressed ?? () => Navigator.of(context).pushNamed(routeName!),
      builder: (context, focused) => _MenuRowSurface(
        focused: focused,
        child: Row(
          children: [
            Icon(
              icon,
              color: focused ? colors.focusText : context.openCoreAccentMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: focused ? colors.focusText : colors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: focused ? focusedMuted : colors.mutedText,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 19,
              color: focused ? colors.focusText : colors.faintText,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRowSurface extends StatelessWidget {
  final bool focused;
  final Widget child;

  const _MenuRowSurface({required this.focused, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final focusRing = context.openCoreFocusRing;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: focused ? colors.focusFill : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focused ? focusRing : Colors.transparent,
          width: 1,
        ),
        boxShadow: [
          if (focused)
            BoxShadow(
              color: colors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: child,
    );
  }
}

class _PressableSurface extends StatefulWidget {
  final bool autofocus;
  final double borderRadius;
  final VoidCallback onPressed;
  final Widget Function(BuildContext context, bool focused) builder;

  const _PressableSurface({
    required this.onPressed,
    required this.builder,
    required this.borderRadius,
    this.autofocus = false,
  });

  @override
  State<_PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<_PressableSurface> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        ActivateIntent:
            CallbackAction<ActivateIntent>(onInvoke: (_) => _activate()),
        ButtonActivateIntent:
            CallbackAction<ButtonActivateIntent>(onInvoke: (_) => _activate()),
      },
      child: Focus(
        autofocus: widget.autofocus,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: context.openCoreColors.focusFill.withOpacity(0.12),
          onTap: widget.onPressed,
          child: widget.builder(context, _focused),
        ),
      ),
    );
  }

  Object? _activate() {
    widget.onPressed();
    return null;
  }
}
