import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static WidgetBuilder? _loginBuilder;

  static void registerLoginBuilder(WidgetBuilder builder) {
    _loginBuilder = builder;
  }

  static BuildContext? get _context => navigatorKey.currentContext;

  static void showSessionExpiredMessage([String? message]) {
    final ctx = _context;
    if (ctx == null) return;

    final messenger = ScaffoldMessenger.maybeOf(ctx);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message ?? 'Session expired. Please sign in again.'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static void redirectToLogin() {
    final navigator = navigatorKey.currentState;
    final builder = _loginBuilder;
    if (navigator == null || builder == null) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: builder),
      (_) => false,
    );
  }
}

