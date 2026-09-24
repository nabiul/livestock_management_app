import 'package:flutter/material.dart';

import 'core/session_controller.dart';
import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_shell.dart';

class LivestockApp extends StatelessWidget {
  const LivestockApp({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => MaterialApp(
        title: 'LivestockOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: session.initializing
            ? const _SplashScreen()
            : session.isAuthenticated
            ? HomeShell(session: session)
            : LoginScreen(session: session),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
