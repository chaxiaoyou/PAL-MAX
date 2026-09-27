import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/isar_portfolio_store.dart';
import 'data/portfolio_store.dart';
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
  final portfolioStore = IsarPortfolioStore(isar);
  if (kSeedDemoPortfolio) {
    await seedDemoPortfolioIfEmpty(portfolioStore);
  }
  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        portfolioStoreProvider.overrideWithValue(portfolioStore),
      ],
      child: const PalMaxApp(),
    ),
  );
}
