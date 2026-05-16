import 'package:flutter/material.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';

class SettingsPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SettingsPageHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                    height: 1.25,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class SettingsSectionLabel extends StatelessWidget {
  final String text;

  const SettingsSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.faintText,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class SettingsTileText extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SettingsTileText({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveTitleColor = defaultStyle.color ?? colors.text;
    final effectiveSubtitleColor =
        IconTheme.of(context).color ?? colors.mutedText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: effectiveTitleColor),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: effectiveSubtitleColor,
                ),
          ),
        ],
      ],
    );
  }
}
