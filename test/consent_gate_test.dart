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
    expect(find.text('أوافق وأتابع'), findsNothing);
  });

  testWidgets('accepting the consent screen records true and returns true',
      (tester) async {
    bool? result;
    await tester.pumpWidget(harness((ctx) async {
      result = await showAiConsent(ctx);
    }));
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    expect(find.text('أوافق وأتابع'), findsOneWidget);
    await tester.tap(find.text('أوافق وأتابع'));
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

    await tester.tap(find.text('لا أوافق'));
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
    expect(find.text('أوافق وأتابع'), findsOneWidget);
    await tester.tap(find.text('أوافق وأتابع'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
