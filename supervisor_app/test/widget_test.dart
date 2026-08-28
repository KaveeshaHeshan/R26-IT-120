// Smoke tests for the phone-frame wrapper used on web.
//
// These deliberately avoid pumping LatexGuardApp itself, because that calls
// Firebase.initializeApp() which is unavailable in a plain widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supervisor_app/main.dart';

void main() {
  testWidgets('MobileFrame renders the route passed to it', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MobileFrame(child: Text('route content')),
      ),
    );

    expect(find.text('route content'), findsOneWidget);
  });

  testWidgets('MobileFrame gives the route the full available space',
      (tester) async {
    // The phone-sized frame was deliberately removed so web, tablet and
    // desktop can use their real estate; feature shells now handle their own
    // adaptive layout. MobileFrame is a pass-through, and this test pins that
    // down so the frame is not silently reintroduced.
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MobileFrame(child: SizedBox.expand()),
      ),
    );

    final size = tester.getSize(find.byType(SizedBox).last);
    expect(size.width, 1200);
    expect(size.height, 1000);
  });

  testWidgets('MobileFrame tolerates a null child', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MobileFrame()));

    expect(find.byType(MobileFrame), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
