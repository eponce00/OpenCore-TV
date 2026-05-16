import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencore_tv/providers/apps_service.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/widgets/input_tile_content.dart';
import 'package:opencore_tv/widgets/settings/input_settings_page.dart';
import 'package:provider/provider.dart';

class InputSelectorDialog extends StatefulWidget {
  final VoidCallback onClose;

  const InputSelectorDialog({super.key, required this.onClose});

  @override
  State<InputSelectorDialog> createState() => _InputSelectorDialogState();
}

class _InputSelectorDialogState extends State<InputSelectorDialog> {
  late final List<FocusNode> _tileFocusNodes;

  static const _columns = 3;

  @override
  void initState() {
    super.initState();
    _tileFocusNodes = List.generate(
      OpenCoreInputConfig.inputs.length,
      (index) => FocusNode(debugLabel: 'input-selector-$index'),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tileFocusNodes.isNotEmpty) {
        _tileFocusNodes.first.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final node in _tileFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final colors = context.openCoreColors;

    return FocusScope(
      canRequestFocus: true,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          SingleActivator(LogicalKeyboardKey.goBack): DismissIntent(),
          SingleActivator(LogicalKeyboardKey.browserBack): DismissIntent(),
          SingleActivator(LogicalKeyboardKey.gameButtonB): DismissIntent(),
          SingleActivator(LogicalKeyboardKey.home): DismissIntent(),
          SingleActivator(LogicalKeyboardKey.contextMenu): DismissIntent(),
          SingleActivator(LogicalKeyboardKey.gameButtonStart): DismissIntent(),
        },
        child: Actions(
          actions: {
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                widget.onClose();
                return null;
              },
            ),
          },
          child: Material(
            color: colors.page,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(56, 42, 56, 52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 24),
                      child: Row(
                        children: [
                          Icon(
                            Icons.input_outlined,
                            color: colors.mutedText,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Inputs",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0,
                                  color: colors.text,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: OpenCoreInputConfig.inputs.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _columns,
                            childAspectRatio: 16 / 9,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 18,
                          ),
                          itemBuilder: (context, index) {
                            final input = OpenCoreInputConfig.inputs[index];
                            final label = settings.inputLabel(
                              input.packageName,
                              settings.defaultInputLabel(input.packageName),
                            );
                            final icon = settings.inputIcon(input.packageName);

                            return _InputSelectorTile(
                              focusNode: _tileFocusNodes[index],
                              icon: OpenCoreInputConfig.iconData(icon),
                              label: label,
                              onMove: (direction) =>
                                  _moveFocus(index, direction),
                              onPressed: () async {
                                widget.onClose();
                                await context
                                    .read<AppsService>()
                                    .launchPackage(input.packageName);
                              },
                              onClose: widget.onClose,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _moveFocus(int index, LogicalKeyboardKey key) {
    final count = _tileFocusNodes.length;
    var nextIndex = index;

    if (key == LogicalKeyboardKey.arrowRight) {
      nextIndex =
          index % _columns == _columns - 1 ? index - (_columns - 1) : index + 1;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      nextIndex = index % _columns == 0 ? index + (_columns - 1) : index - 1;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      nextIndex = index + _columns;
      if (nextIndex >= count) nextIndex = index % _columns;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      nextIndex = index - _columns;
      if (nextIndex < 0) {
        final column = index % _columns;
        nextIndex = column;
        while (nextIndex + _columns < count) {
          nextIndex += _columns;
        }
      }
    }

    _tileFocusNodes[nextIndex.clamp(0, count - 1).toInt()].requestFocus();
  }
}

class _InputSelectorTile extends StatefulWidget {
  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final ValueChanged<LogicalKeyboardKey> onMove;
  final VoidCallback onPressed;
  final VoidCallback onClose;

  const _InputSelectorTile({
    required this.focusNode,
    required this.icon,
    required this.label,
    required this.onMove,
    required this.onPressed,
    required this.onClose,
  });

  @override
  State<_InputSelectorTile> createState() => _InputSelectorTileState();
}

class _InputSelectorTileState extends State<_InputSelectorTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final focusRing = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).colorScheme.primary
        : colors.focusFill;

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) => setState(() => _focused = focused),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.handled;

        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.gameButtonA) {
          widget.onPressed();
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowRight ||
            event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.arrowDown) {
          widget.onMove(event.logicalKey);
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.escape ||
            event.logicalKey == LogicalKeyboardKey.goBack ||
            event.logicalKey == LogicalKeyboardKey.browserBack ||
            event.logicalKey == LogicalKeyboardKey.gameButtonB ||
            event.logicalKey == LogicalKeyboardKey.home ||
            event.logicalKey == LogicalKeyboardKey.contextMenu ||
            event.logicalKey == LogicalKeyboardKey.gameButtonStart) {
          widget.onClose();
          return KeyEventResult.handled;
        }

        return KeyEventResult.handled;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: _focused ? colors.focusFill : colors.elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused ? focusRing : colors.line,
                width: _focused ? 2 : 1,
              ),
              boxShadow: [
                if (_focused)
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: InputTileContent(
              icon: widget.icon,
              label: widget.label,
              focused: _focused,
            ),
          ),
        ),
      ),
    );
  }
}
