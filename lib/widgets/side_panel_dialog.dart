import 'package:opencore_tv/actions.dart';
import 'package:flutter/material.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';

class SidePanelDialog extends StatelessWidget {
  final Widget child;
  final double width;
  final bool isRightSide;

  const SidePanelDialog({
    required this.child,
    this.width = 250,
    this.isRightSide = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    return Align(
      alignment: isRightSide ? Alignment.centerRight : Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Material(
          color: colors.panel,
          elevation: 0,
          child: Container(
            width: width,
            height: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            decoration: BoxDecoration(
              color: colors.panel,
              border: Border(
                right: isRightSide
                    ? BorderSide.none
                    : BorderSide(color: colors.line),
                left: isRightSide
                    ? BorderSide(color: colors.line)
                    : BorderSide.none,
              ),
            ),
            child: Actions(
              actions: {BackIntent: BackAction(context)},
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
