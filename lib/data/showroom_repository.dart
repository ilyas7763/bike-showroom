import 'package:sqflite/sqflite.dart';

import '../models/bike.dart';
import '../models/contribution.dart';
import '../models/enums.dart';
import '../models/expense.dart';
import '../models/partner.dart';
import '../models/partner_summary.dart';
import '../models/sale.dart';
import 'database_helper.dart';

/// All SQL lives here. UI and state classes never touch the database directly.
class ShowroomRepository {
  ShowroomRepository(this._helper);
  final DatabaseHelper _helper;

  Future<Database> get _db => _helper.database;

  static const String _bikeSummarySelect = '''
    SELECT b.*,
           COALESCE((SELECT SUM(e.amount) FROM bike_expenses e
                     WHERE e.bike_id = b.id), 0) AS total_expenses,
           s.sale_price AS sale_price
    FROM bikes b
    LEFT JOIN sales s ON s.bike_id = b.id
  ''';

  // ───────────────────────── Partners ─────────────────────────

  Future<int> addPartner(Partner partner) async =>
      (await _db).insert('partners', partner.toMap());

  Future<List<Partner>> getPartners() async {
    final rows =
        await (await _db).query('partners', orderBy: 'name COLLATE NOCASE');
    return rows.map(Partner.fromMap).toList();
  }

  // ───────────────────────── Bikes ─────────────────────────

  /// Inserts the bike and its partner contributions atomically.
  /// [contributions] maps partnerId -> amount contributed to this bike.
  Future<int> createBike(Bike bike, Map<int, double> contributions) async {
    final db = await _db;
    return db.transaction((txn) async {
      final bikeId = await txn.insert('bikes', bike.toMap());
      for (final entry in contributions.entries) {
        await txn.insert(
          'partner_contributions',
          Contribution(
            partnerId: entry.key,
            bikeId: bikeId,
            amount: entry.value,
            date: bike.purchaseDate,
            note: 'Bike purchase',
          ).toMap(),
        );
      }
      return bikeId;
    });
  }

  Future<void> updateBike(Bike bike) async {
    final map = bike.toMap();
    // Sold-ness is owned by recordSale()/undoSale(); never overwrite it here.
    if (bike.status == BikeStatus.sold) map.remove('status');
    await (await _db)
        .update('bikes', map, where: 'id = ?', whereArgs: [bike.id]);
  }

  Future<void> updateBikeStatus(int bikeId, BikeStatus status) async {
    if (status == BikeStatus.sold) {
      throw ArgumentError('Use recordSale() to mark a bike as sold.');
    }
    final db = await _db;
    final rows = await db.query('bikes',
        columns: ['status'], where: 'id = ?', whereArgs: [bikeId]);
    if (rows.isNotEmpty && rows.first['status'] == BikeStatus.sold.dbValue) {
      throw StateError('Sold bikes cannot change status. Undo the sale first.');
    }
    await db.update('bikes', {'status': status.dbValue},
        where: 'id = ?', whereArgs: [bikeId]);
  }

  /// Cascades to the bike's expenses, contributions and sale.
  Future<void> deleteBike(int bikeId) async => (await _db)
      .delete('bikes', where: 'id = ?', whereArgs: [bikeId]);

  Future<BikeSummary?> getBike(int bikeId) async {
    final rows = await (await _db)
        .rawQuery('$_bikeSummarySelect WHERE b.id = ?', [bikeId]);
    return rows.isEmpty ? null : BikeSummary.fromMap(rows.first);
  }

  Future<List<BikeSummary>> getBikes({
    BikeStatus? status,
    String query = '',
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (status != null) {
      where.add('b.status = ?');
      args.add(status.dbValue);
    }
    final q = query.trim();
    if (q.isNotEmpty) {
      where.add('(b.make LIKE ? OR b.model LIKE ? '
          'OR b.registration_no LIKE ? OR b.chassis_no LIKE ?)');
      args.addAll(List.filled(4, '%$q%'));
    }
    final sql = '$_bikeSummarySelect '
        '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} '
        'ORDER BY b.created_at DESC, b.id DESC';
    final rows = await (await _db).rawQuery(sql, args);
    return rows.map(BikeSummary.fromMap).toList();
  }

  Future<Map<BikeStatus, int>> getStatusCounts() async {
    final rows = await (await _db)
        .rawQuery('SELECT status, COUNT(*) AS c FROM bikes GROUP BY status');
    return {
      for (final r in rows)
        BikeStatus.fromDb(r['status'] as String): r['c'] as int,
    };
  }

  // ───────────────────────── Expenses ─────────────────────────

  Future<int> addExpense(Expense e) async =>
      (await _db).insert('bike_expenses', e.toMap());

  Future<void> deleteExpense(int id) async => (await _db)
      .delete('bike_expenses', where: 'id = ?', whereArgs: [id]);

  Future<List<Expense>> getBikeExpenses(int bikeId) async {
    final rows = await (await _db).query('bike_expenses',
        where: 'bike_id = ?',
        whereArgs: [bikeId],
        orderBy: 'expense_date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  /// General daily showroom expenses (not attached to any bike).
  Future<List<Expense>> getShowroomExpenses() async {
    final rows = await (await _db).query('bike_expenses',
        where: 'bike_id IS NULL', orderBy: 'expense_date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  // ───────────────────────── Contributions ─────────────────────────

  Future<int> addContribution(Contribution c) async =>
      (await _db).insert('partner_contributions', c.toMap());

  Future<void> deleteContribution(int id) async => (await _db)
      .delete('partner_contributions', where: 'id = ?', whereArgs: [id]);

  Future<List<Contribution>> getBikeContributions(int bikeId) async {
    final rows = await (await _db).rawQuery('''
      SELECT c.*, p.name AS partner_name
      FROM partner_contributions c
      JOIN partners p ON p.id = c.partner_id
      WHERE c.bike_id = ?
      ORDER BY c.contribution_date DESC, c.id DESC
    ''', [bikeId]);
    return rows.map(Contribution.fromMap).toList();
  }

  // ───────────────────────── Sales ─────────────────────────

  Future<int> recordSale(Sale sale) async {
    final db = await _db;
    return db.transaction((txn) async {
      final rows = await txn.query('bikes',
          columns: ['status'], where: 'id = ?', whereArgs: [sale.bikeId]);
      if (rows.isEmpty) throw StateError('Bike not found.');
      if (rows.first['status'] == BikeStatus.sold.dbValue) {
        throw StateError('This bike is already sold.');
      }
      final saleId = await txn.insert('sales', sale.toMap());
      await txn.update('bikes', {'status': BikeStatus.sold.dbValue},
          where: 'id = ?', whereArgs: [sale.bikeId]);
      return saleId;
    });
  }

  /// Removes the sale and returns the bike to Available.
  Future<void> undoSale(int saleId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.query('sales',
          columns: ['bike_id'], where: 'id = ?', whereArgs: [saleId]);
      if (rows.isEmpty) return;
      final bikeId = rows.first['bike_id'] as int;
      await txn.delete('sales', where: 'id = ?', whereArgs: [saleId]);
      await txn.update('bikes', {'status': BikeStatus.available.dbValue},
          where: 'id = ?', whereArgs: [bikeId]);
    });
  }

  Future<List<SaleRecord>> getSalesHistory() async {
    final rows = await (await _db).rawQuery('''
      SELECT s.*, b.make, b.model, b.year, b.purchase_price,
             COALESCE((SELECT SUM(e.amount) FROM bike_expenses e
                       WHERE e.bike_id = b.id), 0) AS total_expenses
      FROM sales s
      JOIN bikes b ON b.id = s.bike_id
      ORDER BY s.sale_date DESC, s.id DESC
    ''');
    return rows.map(SaleRecord.fromMap).toList();
  }

  // ───────────────────────── Partner capital summary ─────────────────────────

  /// For every partner: capital in, capital in sold vs unsold bikes, and the
  /// profit share from sold bikes. A bike's net profit is split pro-rata to what
  /// each partner contributed to that bike (equal split if nothing was recorded).
  Future<List<PartnerSummary>> getPartnerSummaries() async {
    final db = await _db;
    final partners = await getPartners();
    final contribRows = await db.query('partner_contributions');
    final sales = await getSalesHistory();

    final total = <int, double>{};
    final general = <int, double>{};
    final byBike = <int, Map<int, double>>{};

    for (final r in contribRows) {
      final pid = r['partner_id'] as int;
      final bikeId = r['bike_id'] as int?;
      final amt = (r['amount'] as num).toDouble();
      total[pid] = (total[pid] ?? 0) + amt;
      if (bikeId == null) {
        general[pid] = (general[pid] ?? 0) + amt;
      } else {
        final m = byBike.putIfAbsent(bikeId, () => {});
        m[pid] = (m[pid] ?? 0) + amt;
      }
    }

    final investedInSold = <int, double>{};
    final profitShare = <int, double>{};

    for (final rec in sales) {
      final contribs = byBike[rec.sale.bikeId] ?? const <int, double>{};
      final bikeTotal = contribs.values.fold<double>(0, (a, b) => a + b);
      for (final partner in partners) {
        final pid = partner.id!;
        final c = contribs[pid] ?? 0;
        final ratio = bikeTotal > 0 ? c / bikeTotal : 1 / partners.length;
        investedInSold[pid] = (investedInSold[pid] ?? 0) + c;
        profitShare[pid] = (profitShare[pid] ?? 0) + rec.netProfit * ratio;
      }
    }

    return partners
        .map((p) => PartnerSummary(
              partner: p,
              totalInvested: total[p.id] ?? 0,
              generalCapital: general[p.id] ?? 0,
              investedInSoldBikes: investedInSold[p.id] ?? 0,
              profitShare: profitShare[p.id] ?? 0,
            ))
        .toList();
  }
}
