import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';
import 'screens/webview_screen.dart';
import 'services/app_conf_service.dart';
import 'theme/app_theme.dart';

typedef FetchAppConf = Future<String?> Function();

class PalMaxApp extends ConsumerStatefulWidget {
  const PalMaxApp({super.key, this.fetchAppConf});

  /// Startup gate: returns the `steer` URL when the backend wants to
  /// replace the native app with a web page, or `null` to keep the app.
  final FetchAppConf? fetchAppConf;

  @override
  ConsumerState<PalMaxApp> createState() => _PalMaxAppState();
}

class _PalMaxAppState extends ConsumerState<PalMaxApp> {
  static const _retryDelay = Duration(seconds: 2);

  late final FetchAppConf _fetchAppConf =
      widget.fetchAppConf ?? AppConfService().fetchSteerUrl;

  String? _steerUrl;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAppConf();
  }

  Future<void> _checkAppConf() async {
    while (mounted) {
      try {
        final steer = await _fetchAppConf();
        if (!mounted) return;
        setState(() {
          _steerUrl = steer;
          _checking = false;
        });
        return;
      } catch (error, stackTrace) {
        debugPrint('fetchAppConf failed: $error\n$stackTrace');
        if (!mounted) return;
        await Future<void>.delayed(_retryDelay);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget home;
    if (_checking) {
      home = const _StartupLoading();
    } else {
      final steer = _steerUrl;
      home = (steer == null || steer.isEmpty)
          ? const HomeScreen()
          : WebViewScreen(url: steer);
    }

    return MaterialApp(
      title: 'Stock Trading Calculator',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      home: home,
    );
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAL-Puls',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
