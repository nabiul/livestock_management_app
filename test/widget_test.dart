import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livestock_management_app/app.dart';
import 'package:livestock_management_app/core/session_controller.dart';

void main() {
  testWidgets('shows a loading indicator while the session initializes', (
    tester,
  ) async {
    final session = SessionController();

    await tester.pumpWidget(LivestockApp(session: session));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('LivestockOS'), findsNothing);
  });
}
