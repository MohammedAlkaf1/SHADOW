import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shadow/flutter_flow/flutter_flow_theme.dart';
import 'package:shadow/pages/consent/consent_screen.dart';
import 'package:shadow/services/app_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FlutterFlowTheme.initialize();
  });

  Widget harness(void Function(BuildContext) onTap) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => onTap(context),
              child: const Text('trigger'),
            ),
          ),
        ),
      ),
    );
  }

  // Interactions/assertions below use structural finders (widget type),
  // not the screen's copy. ConsentScreen's text goes through
  // easy_localization's .tr(), which needs a real EasyLocalization
  // ancestor (provided by production's main.dart) to resolve to actual
  // translated strings; without one .tr() gracefully falls back to
  // showing the raw key instead of throwing, so the screen still renders
  // and its structure (agree = the one ElevatedButton, decline = the one
  // OutlinedButton) is exactly as reliable to test against — and doesn't
  // require standing up a full, fragile EasyLocalization harness just to
  // verify this screen's actual job: the accept/decline gating logic.
  testWidgets('ensureAiConsent returns true immediately when already accepted',
      (tester) async {
    SharedPreferences.setMockInitialValues({'ai_consent': true});
    bool? result;
    await tester.pumpWidget(harness((ctx) async {
      result = await ensureAiConsent(ctx);
    }));
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    // It must NOT have shown the consent screen.
    expect(find.byType(ConsentScreen), findsNothing);
  });

  testWidgets('accepting the consent screen records true and returns true',
      (tester) async {
    bool? result;
    await tester.pumpWidget(harness((ctx) async {
      result = await showAiConsent(ctx);
    }));
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    expect(find.byType(ConsentScreen), findsOneWidget);
    // The agree action is the sole ElevatedButton on this screen.
    await tester.tap(find.descendant(
        of: find.byType(ConsentScreen), matching: find.byType(ElevatedButton)));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(await AppPrefs.getAiConsent(), isTrue);
  });

  testWidgets('declining records false and returns false', (tester) async {
    bool? result;
    await tester.pumpWidget(harness((ctx) async {
      result = await showAiConsent(ctx);
    }));
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    // The decline action is the sole OutlinedButton on this screen.
    await tester.tap(find.descendant(
        of: find.byType(ConsentScreen), matching: find.byType(OutlinedButton)));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(await AppPrefs.getAiConsent(), isFalse);
  });

  testWidgets('a declined user is re-prompted (gating shows the screen again)',
      (tester) async {
    SharedPreferences.setMockInitialValues({'ai_consent': false});
    bool? result;
    await tester.pumpWidget(harness((ctx) async {
      result = await ensureAiConsent(ctx);
    }));
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    // The consent screen should be shown again, not silently return.
    expect(find.byType(ConsentScreen), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(ConsentScreen), matching: find.byType(ElevatedButton)));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
