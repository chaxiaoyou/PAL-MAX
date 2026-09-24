import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:isar_community/src/native/isar_core.dart';
import 'package:pjza/models/app_setting.dart';
import 'package:pjza/models/saved_record.dart';

/// Path to the native Isar library shipped with isar_community_flutter_libs, or
/// null when the host does not have it (then the caller should skip).
String? isarCoreLibPath() {
  final pubCache = Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME'] ?? '.'}/.pub-cache';
  final path = '$pubCache/hosted/pub.dev/'
      'isar_community_flutter_libs-3.3.2/macos/libisar.dylib';
  return File(path).existsSync() ? path : null;
}

/// Opens a throw-away Isar database for widget tests so providers that read
/// settings / saved records work exactly like they do in the app.
Future<Isar?> openTestIsar(String name) async {
  final coreLib = isarCoreLibPath();
  if (coreLib == null) return null;
  await initializeCoreBinary(libraries: {Abi.current(): coreLib});
  final dir = Directory.systemTemp.createTempSync('${name}_dir');
  return Isar.open(
    [SavedRecordSchema, AppSettingSchema],
    directory: dir.path,
    name: name,
  );
}

/// Human readable reason for skipping a test that needs the native library.
String get skipWithoutIsarCore =>
    'isar_community_flutter_libs native library not found; skipped';
