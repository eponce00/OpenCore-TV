import 'package:opencore_tv/actions.dart';
import 'dart:ui';

import 'package:flutter/material.dart';

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
    return Align(
      alignment: isRightSide ? Alignment.centerRight : Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.horizontal(
          right: isRightSide ? Radius.zero : const Radius.circular(36),
          left: isRightSide ? const Radius.circular(36) : Radius.zero,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: const Color(0xF20A0D10),
            elevation: 20,
            child: Container(
              width: width,
              height: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                border: Border(
                  right: isRightSide
                      ? BorderSide.none
                      : BorderSide(color: Colors.white.withOpacity(0.07)),
                  left: isRightSide
                      ? BorderSide(color: Colors.white.withOpacity(0.07))
                      : BorderSide.none,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.045),
                    Colors.white.withOpacity(0.018),
                    Colors.black.withOpacity(0.18),
                  ],
                ),
              ),
              child: Actions(
                actions: {BackIntent: BackAction(context)},
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
