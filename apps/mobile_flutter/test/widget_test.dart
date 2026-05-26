import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/app.dart';

void main() {
  testWidgets('app renders onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    await tester.pump();

    expect(find.text('AI MUSIC GENERATOR'), findsOneWidget);
  });
}
