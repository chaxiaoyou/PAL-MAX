import 'package:isar_community/isar.dart';

import '../domain/alert.dart';
import '../domain/transaction.dart';
import '../models/stored_alert.dart';
import '../models/stored_transaction.dart';
import 'portfolio_store.dart';

/// Isar-backed [PortfolioStore].
///
/// Isar rather than SQLite because the portfolio's derived values — average
/// cost, realized P&L, allocation — are all computed in Dart by
/// `domain/portfolio_math.dart`, so storage only ever does keyed CRUD. That
/// removes the reason to carry a second engine: the app already ships Isar for
/// watchlist preferences, nothing new gets compiled in, and there is no schema
/// generator to reconcile with the one already in the build.
class IsarPortfolioStore implements PortfolioStore {
  IsarPortfolioStore(this._db);

  final Isar _db;

  @override
  Future<List<Transaction>> loadTransactions() async {
    final rows =
        await _db.storedTransactions.where().sortByExecutedAt().findAll();
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final row = StoredTransaction.fromDomain(transaction);
    await _db.writeTxn(() async {
      final existing = await _findTransaction(transaction.id);
      // Reuse Isar's primary key so an edit updates in place instead of
      // inserting a second row for the same transaction.
      if (existing != null) row.id = existing.id;
      await _db.storedTransactions.put(row);
    });
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _db.writeTxn(() async {
      final existing = await _findTransaction(id);
      if (existing != null) await _db.storedTransactions.delete(existing.id);
    });
  }

  @override
  Future<List<Alert>> loadAlerts() async {
    final rows = await _db.storedAlerts.where().sortByCreatedAt().findAll();
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<void> saveAlert(Alert alert) async {
    final row = StoredAlert.fromDomain(alert);
    await _db.writeTxn(() async {
      final existing = await _findAlert(alert.id);
      if (existing != null) row.id = existing.id;
      await _db.storedAlerts.put(row);
    });
  }

  @override
  Future<void> deleteAlert(String id) async {
    await _db.writeTxn(() async {
      final existing = await _findAlert(id);
      if (existing != null) await _db.storedAlerts.delete(existing.id);
    });
  }

  /// A retail portfolio holds hundreds of rows, not millions, so a scan is
  /// cheaper than the schema features needed to index `uid` — see
  /// [StoredTransaction.uid].
  Future<StoredTransaction?> _findTransaction(String uid) async {
    final rows = await _db.storedTransactions.where().findAll();
    for (final row in rows) {
      if (row.uid == uid) return row;
    }
    return null;
  }

  Future<StoredAlert?> _findAlert(String uid) async {
    final rows = await _db.storedAlerts.where().findAll();
    for (final row in rows) {
      if (row.uid == uid) return row;
    }
    return null;
  }
}
