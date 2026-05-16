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

import 'package:opencore_tv/gradients.dart';
import 'package:opencore_tv/providers/wallpaper_service.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/widgets/ensure_visible.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GradientPanelPage extends StatelessWidget {
  static const String routeName = "gradient_panel";

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text("Gradient", style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 4 / 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: OpenCoreTVGradients.all
                  .map((gradient) => EnsureVisible(
                      alignment: 0.5, child: _gradientCard(context, gradient)))
                  .toList(),
            ),
          ),
        ],
      );

  Widget _gradientCard(
          BuildContext context, OpenCoreTVGradient OpenCoreTVGradient) =>
      Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) => context
                  .read<WallpaperService>()
                  .setGradient(OpenCoreTVGradient)),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
              onInvoke: (_) => context
                  .read<WallpaperService>()
                  .setGradient(OpenCoreTVGradient)),
        },
        child: Focus(
          key: Key("gradient-${OpenCoreTVGradient.uuid}"),
          canRequestFocus: false,
          child: Builder(
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: _cardBorder(context, Focus.of(context).hasFocus),
                    child: InkWell(
                      autofocus:
                          OpenCoreTVGradient == OpenCoreTVGradients.greatWhale,
                      onTap: () => context
                          .read<WallpaperService>()
                          .setGradient(OpenCoreTVGradient),
                      child: Container(
                          decoration: BoxDecoration(
                              gradient: OpenCoreTVGradient.gradient)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedDefaultTextStyle(
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          decoration: TextDecoration.underline,
                          color: Focus.of(context).hasFocus
                              ? context.openCoreColors.text
                              : null,
                        ),
                    duration: const Duration(milliseconds: 50),
                    child: Text(OpenCoreTVGradient.name,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  ShapeBorder? _cardBorder(BuildContext context, bool hasFocus) {
    final colors = context.openCoreColors;
    final focusRing = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).colorScheme.primary
        : colors.focusFill;
    return hasFocus
        ? RoundedRectangleBorder(
            side: BorderSide(color: focusRing, width: 2),
            borderRadius: BorderRadius.circular(12))
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  }
}
