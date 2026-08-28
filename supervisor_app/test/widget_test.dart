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

  testWidgets('MobileFrame constrains its child to phone dimensions',
      (tester) async {
    // Give the test surface room for the full 844px-tall frame, otherwise
    // the frame is clamped by the default 800x600 viewport.
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MobileFrame(child: SizedBox.expand()),
      ),
    );

    // The frame is 390x844 including its 2px border, so a child asking for
    // all available space is bounded to the area inside that border.
    final size = tester.getSize(find.byType(SizedBox).last);
    expect(size.width, 390 - 4);
    expect(size.height, 844 - 4);
  });

  testWidgets('MobileFrame tolerates a null child', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MobileFrame()));

    expect(find.byType(MobileFrame), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
