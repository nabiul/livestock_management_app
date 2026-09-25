import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livestock_management_app/app.dart';
import 'package:livestock_management_app/core/session_controller.dart';
import 'package:livestock_management_app/widgets/common.dart';

void main() {
  test('formats API dates for Bangladesh-style app display', () {
    expect(formatAppDate('2026-09-25'), '25-09-2026');
    expect(formatAppDate('2026-09-25T20:17:30.000000Z'), '25-09-2026');
    expect(dateFormat.format(DateTime(2026, 9, 25)), '2026-09-25');
  });

  testWidgets('shows a loading indicator while the session initializes', (
    tester,
  ) async {
    final session = SessionController();

    await tester.pumpWidget(LivestockApp(session: session));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('LivestockOS'), findsNothing);
  });
}
