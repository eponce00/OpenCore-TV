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
import 'package:opencore_tv/widgets/settings/opencore_about_dialog.dart';
import 'package:opencore_tv/widgets/settings/opencore_clock_settings_page.dart';
import 'package:opencore_tv/widgets/settings/opencore_health_page.dart';
import 'package:opencore_tv/widgets/settings/wallpaper_panel_page.dart';
import 'package:opencore_tv/widgets/settings/weather_settings_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

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
    final enabled = await context.read<AppsService>().isHomeGuardEnabled();
    if (!mounted) return;
    setState(() => _homeGuardEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final guardHealthy = _homeGuardEnabled == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsHeader(now: _now, guardHealthy: guardHealthy),
        const SizedBox(height: 18),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.75,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _ControlTile(
                      autofocus: true,
                      icon: Icons.bedtime_outlined,
                      title: "Idle",
                      subtitle: "Screensaver",
                      routeName: IdleSettingsPage.routeName,
                    ),
                    _ControlTile(
                      icon: Icons.wallpaper_outlined,
                      title: "Wallpaper",
                      subtitle: "Library",
                      routeName: WallpaperPanelPage.routeName,
                    ),
                    _ControlTile(
                      icon: Icons.input_outlined,
                      title: "Inputs",
                      subtitle: "HDMI labels",
                      routeName: InputSettingsPage.routeName,
                    ),
                    _ControlTile(
                      icon: guardHealthy
                          ? Icons.verified_user_outlined
                          : Icons.warning_amber_rounded,
                      title: "Health",
                      subtitle: guardHealthy ? "Protected" : "Check guard",
                      routeName: OpenCoreHealthPage.routeName,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Personalize",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.82),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
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
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  "System",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.82),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
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
                      title: "OpenCore System",
                      subtitle: "Brightness, time, network tools",
                      routeName: GeneralSettingsPage.routeName,
                    ),
                    _SettingsRow(
                      icon: Icons.settings_outlined,
                      title: "Fire TV Settings",
                      subtitle: "Open native device settings",
                      onPressed: _openFireTvSettings,
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

  Future<void> _openFireTvSettings() async {
    final appsService = context.read<AppsService>();
    Navigator.of(context, rootNavigator: true).pop();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await appsService.openSettings();
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData
                ? OpenCoreTVAboutDialog(packageInfo: snapshot.data!)
                : const SizedBox.shrink(),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final DateTime now;
  final bool guardHealthy;

  const _SettingsHeader({required this.now, required this.guardHealthy});

  @override
  Widget build(BuildContext context) {
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
    final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, "0");
    final period = now.hour >= 12 ? "PM" : "AM";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.060),
            Colors.white.withOpacity(0.025),
            Colors.black.withOpacity(0.18),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.075)),
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
                        color: Colors.white.withOpacity(0.82),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$hour:$minute $period",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Control Center",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.58),
                      ),
                ),
              ],
            ),
          ),
          _StatusPill(
            icon: guardHealthy
                ? Icons.shield_outlined
                : Icons.warning_amber_rounded,
            label: guardHealthy ? "Guard on" : "Check guard",
            color:
                guardHealthy ? const Color(0xFF9BE58C) : const Color(0xFFFFB35C),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.88),
                  fontWeight: FontWeight.w700,
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
    return _PressableSurface(
      autofocus: autofocus,
      borderRadius: 22,
      onPressed: () => Navigator.of(context).pushNamed(routeName),
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: focused
              ? Colors.white.withOpacity(0.105)
              : Colors.white.withOpacity(0.045),
          border: Border.all(
            color: focused
                ? Colors.white.withOpacity(0.78)
                : Colors.white.withOpacity(0.065),
            width: focused ? 1.8 : 1,
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(focused ? 0.16 : 0.08),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 13),
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
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.54),
                        ),
                  ),
                ],
              ),
            ),
          ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.055)),
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
    return _PressableSurface(
      borderRadius: 18,
      onPressed: onPressed ?? () => Navigator.of(context).pushNamed(routeName!),
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: focused ? Colors.white.withOpacity(0.075) : Colors.transparent,
          border: Border.all(
            color: focused
                ? Colors.white.withOpacity(0.62)
                : Colors.transparent,
            width: 1.35,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.80), size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.48),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(focused ? 0.82 : 0.34),
            ),
          ],
        ),
      ),
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
          splashColor: Colors.white.withOpacity(0.06),
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
