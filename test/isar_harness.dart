import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:isar_community/src/native/isar_core.dart';
import 'package:needhamcapital/models/app_setting.dart';
import 'package:needhamcapital/models/holding.dart';
import 'package:needhamcapital/models/price_alert.dart';
import 'package:needhamcapital/models/transaction.dart';

/// Shared scaffolding for tests that need a real Isar store.
///
/// Isar's native library ships with isar_community_flutter_libs and only exists
/// for the host platform, so these tests skip rather than fail when it is
/// missing.
final _pubCache = Platform.environment['PUB_CACHE'] ??
    '${Platform.environment['HOME'] ?? '.'}/.pub-cache';

final isarCoreLibrary = '$_pubCache/hosted/pub.dev/'
    'isar_community_flutter_libs-3.3.2/macos/libisar.dylib';

/// True when the host cannot run these tests.
final isarUnavailable = !File(isarCoreLibrary).existsSync();

var _coreReady = false;

Future<void> _ensureCore() async {
  if (_coreReady) return;
  await initializeCoreBinary(libraries: {Abi.current(): isarCoreLibrary});
  _coreReady = true;
}

/// Opens a throwaway store, optionally seeded with [holdings].
Future<Isar> openStore(
  String name, {
  List<Holding> holdings = const [],
  List<PriceAlert> alerts = const [],
}) async {
  await _ensureCore();
  final dir = Directory.systemTemp.createTempSync(name);
  final store = await Isar.open(
    [AppSettingSchema, HoldingSchema, TransactionSchema, PriceAlertSchema],
    directory: dir.path,
    name: name,
  );
  if (holdings.isNotEmpty) {
    await store.writeTxn(() => store.holdings.putAll(holdings));
  }
  if (alerts.isNotEmpty) {
    await store.writeTxn(() => store.priceAlerts.putAll(alerts));
  }
  addTearDown(() {
    if (store.isOpen) store.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  return store;
}

/// [openStore] for a widget test: real Isar I/O has to run outside the widget
/// tester's fake clock, otherwise the await never resolves.
Future<Isar> openStoreInWidgetTest(
  WidgetTester tester,
  String name, {
  List<Holding> holdings = const [],
  List<PriceAlert> alerts = const [],
}) async {
  late Isar store;
  await tester.runAsync(() async {
    store = await openStore(name, holdings: holdings, alerts: alerts);
  });
  return store;
}

/// The provider tree reads Isar and fetches quotes with real async I/O, which
/// the widget tester's fake clock does not advance on its own. Pumping between
/// short real-time slices lets those futures resolve, without `pumpAndSettle`
/// hanging on the loading spinner's endless animation.
Future<void> settleRealIo(WidgetTester tester) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
}

/// Real fonts, so layout is measured with realistic text widths. The default
/// test font draws every glyph as a full-width box, which makes narrow layouts
/// overflow for reasons that never happen on a device.
Future<void> loadTestFonts() async {
  const fontDir = '/Users/delong/flutter/bin/cache/artifacts/material_fonts';
  if (!Directory(fontDir).existsSync()) return;
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(File('$fontDir/$name').readAsBytesSync());
  final text = FontLoader('Roboto')
    ..addFont(read('Roboto-Regular.ttf'))
    ..addFont(read('Roboto-Medium.ttf'))
    ..addFont(read('Roboto-Bold.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(read('MaterialIcons-Regular.otf'));
  await text.load();
  await icons.load();
}
