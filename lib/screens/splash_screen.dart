import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_conf_service.dart';
import '../theme/app_theme.dart';
import 'root_shell.dart';
import 'webview_screen.dart';

/// Returns the `steer` URL when the backend wants to replace the native app
/// with a web page, or `null` to keep the app.
typedef FetchAppConf = Future<String?> Function();

/// Where the startup check sends the app.
enum StartupDestination {
  /// A `steer` URL came back: the native UI never appears.
  web,

  /// No steer: run the native app.
  main,
}

/// The decision itself, kept separate from the routing so it can be tested
/// without standing up a web view.
StartupDestination destinationFor(String? steer) =>
    (steer == null || steer.trim().isEmpty)
        ? StartupDestination.main
        : StartupDestination.web;

/// The page a destination resolves to. Separate from the navigation so the
/// choice can be asserted without building a web view, which needs a platform
/// implementation that tests do not have.
Widget pageFor(StartupDestination destination, String? steer) =>
    destination == StartupDestination.web
        ? WebViewScreen(url: steer!.trim())
        : const RootShell();

/// The page the app opens on.
///
/// Everything else waits on this: it asks the backend what to do, and only then
/// routes — to the web view when a `steer` URL comes back, otherwise to the
/// native app.
///
/// The check is deliberately not allowed to fail open. If the backend cannot be
/// reached it keeps retrying instead of starting the native app on a guess,
/// because "no answer" is not the same as "run the app".
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.fetchAppConf});

  final FetchAppConf? fetchAppConf;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _retryDelay = Duration(seconds: 2);

  /// A splash that flashes for 40ms reads as a glitch rather than a step.
  static const _minimumVisible = Duration(milliseconds: 350);

  late final FetchAppConf _fetchAppConf =
      widget.fetchAppConf ?? AppConfService().fetchSteerUrl;

  int _failedAttempts = 0;

  /// Held so [Retry] can cut the wait short instead of stacking another loop.
  Completer<void>? _retryWait;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _retryWait?.complete();
    _retryWait = null;
    super.dispose();
  }

  Future<void> _check() async {
    final startedAt = DateTime.now();
    while (mounted) {
      try {
        final steer = await _fetchAppConf();
        if (!mounted) return;
        final elapsed = DateTime.now().difference(startedAt);
        if (elapsed < _minimumVisible) {
          await Future<void>.delayed(_minimumVisible - elapsed);
        }
        if (!mounted) return;
        _route(destinationFor(steer), steer);
        return;
      } catch (error, stackTrace) {
        debugPrint('fetchAppConf failed: $error\n$stackTrace');
        if (!mounted) return;
        setState(() => _failedAttempts++);
        final wait = Completer<void>();
        _retryWait = wait;
        await Future.any([
          wait.future,
          Future<void>.delayed(_retryDelay),
        ]);
        if (!mounted) return;
        _retryWait = null;
      }
    }
  }

  void _retryNow() {
    final wait = _retryWait;
    if (wait != null && !wait.isCompleted) wait.complete();
  }

  void _route(StartupDestination destination, String? steer) {
    final page = pageFor(destination, steer);
    // Replace, not push: Back must never return to the transit page, and a
    // steer must not be dismissible.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => page,
        transitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final retrying = _failedAttempts > 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              kAppName,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: Space.xxl),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: Space.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xxxl),
              child: Text(
                retrying
                    ? 'Still connecting…'
                    : 'Checking for updates…',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (retrying) ...[
              const SizedBox(height: Space.xs),
              TextButton(
                onPressed: _retryNow,
                child: const Text('Retry now'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
