import 'package:flutter/material.dart';

import 'app.dart';
import 'core/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = SessionController();
  await session.initialize();
  runApp(LivestockApp(session: session));
}
