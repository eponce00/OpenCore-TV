import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/widgets/input_selector_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpSelector(
    WidgetTester tester, {
    VoidCallback? onClose,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final settings = SettingsService(preferences);

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsService>.value(
        value: settings,
        child: MaterialApp(
          home: Scaffold(
            body: InputSelectorDialog(onClose: onClose ?? () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows only input tiles without a close button', (tester) async {
    await pumpSelector(tester);

    expect(find.text('Inputs'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.text('HDMI 1'), findsOneWidget);
    expect(find.text('HDMI 4'), findsOneWidget);
    expect(find.text('Antenna'), findsOneWidget);
    expect(find.text('Composite'), findsOneWidget);
  });

  testWidgets('keeps directional focus inside the input grid', (tester) async {
    await pumpSelector(tester);

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'input-selector-0');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'input-selector-2');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'input-selector-5');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'input-selector-3');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'input-selector-0');
  });

  testWidgets('dismiss keys close the selector', (tester) async {
    var closed = false;
    await pumpSelector(tester, onClose: () => closed = true);

    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
    await tester.pump();

    expect(closed, isTrue);
  });
}
