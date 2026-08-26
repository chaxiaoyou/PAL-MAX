import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers/providers.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Immersive edge-to-edge: the app background extends behind the system
  // bars, so the transparent status/navigation bars match the screen color.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final isar = await openDatabase();
  runApp(
    ProviderScope(
      overrides: [isarProvider.overrideWithValue(isar)],
      child: const PalMaxApp(),
    ),
  );
}
