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

  testWidgets('MobileFrame frames the app on a wide desktop window',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MobileFrame(
          child: SizedBox.expand(key: Key('content')),
        ),
      ),
    );

    // Phone-width preview rather than the full 1200px window.
    // The frame is 390x844 including its 2px border, so the child sits
    // inside that border.
    final size = tester.getSize(find.byKey(const Key('content')));
    expect(size.width, 390 - 4);
    expect(size.height, 844 - 4);
  });

  testWidgets('MobileFrame passes through on a real phone-sized window',
      (tester) async {
    // A narrow viewport is an actual device, not a desktop preview. Framing
    // there would letterbox the app inside itself and break the farmer
    // screens' adaptive layouts.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MobileFrame(
          child: SizedBox.expand(key: Key('content')),
        ),
      ),
    );

    final size = tester.getSize(find.byKey(const Key('content')));
    expect(size.width, 400);
    expect(size.height, 800);
  });

  testWidgets('MobileFrame shrinks the frame to fit a short window',
      (tester) async {
    // An 844px-tall frame would overflow a laptop browser viewport.
    tester.view.physicalSize = const Size(1200, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MobileFrame(
          child: SizedBox.expand(key: Key('content')),
        ),
      ),
    );

    final size = tester.getSize(find.byKey(const Key('content')));
    expect(size.width, 390 - 4);
    expect(size.height, 700 - 32 - 4);
    expect(tester.takeException(), isNull); // no overflow
  });

  testWidgets('MobileFrame tolerates a null child', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MobileFrame()));

    expect(find.byType(MobileFrame), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
