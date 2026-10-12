import 'package:flutter/foundation.dart';

import '../data/showroom_repository.dart';
import '../models/bike.dart';
import '../models/contribution.dart';
import '../models/enums.dart';
import '../models/expense.dart';
import '../models/partner.dart';
import '../models/partner_summary.dart';
import '../models/sale.dart';

class ShowroomProvider extends ChangeNotifier {
  ShowroomProvider(this.repo);
  final ShowroomRepository repo;

  bool loading = false;
  String? error;

  BikeStatus? statusFilter; // null = all
  String search = '';

  List<BikeSummary> bikes = [];
  Map<BikeStatus, int> statusCounts = {};
  List<SaleRecord> sales = [];
  List<Partner> partners = [];
  List<PartnerSummary> partnerSummaries = [];
  List<Expense> showroomExpenses = [];

  int get totalBikeCount => statusCounts.values.fold(0, (a, b) => a + b);
  double get totalRevenue =>
      sales.fold(0.0, (a, s) => a + s.sale.salePrice);
  double get totalNetProfit => sales.fold(0.0, (a, s) => a + s.netProfit);

  Future<void> loadAll() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final r = await Future.wait<Object>([
        repo.getBikes(status: statusFilter, query: search),
        repo.getStatusCounts(),
        repo.getSalesHistory(),
        repo.getPartners(),
        repo.getPartnerSummaries(),
        repo.getShowroomExpenses(),
      ]);
      bikes = r[0] as List<BikeSummary>;
      statusCounts = r[1] as Map<BikeStatus, int>;
      sales = r[2] as List<SaleRecord>;
      partners = r[3] as List<Partner>;
      partnerSummaries = r[4] as List<PartnerSummary>;
      showroomExpenses = r[5] as List<Expense>;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Filters
  Future<void> setStatusFilter(BikeStatus? s) {
    statusFilter = s;
    return loadAll();
  }

  Future<void> setSearch(String q) {
    search = q;
    return loadAll();
  }

  // Mutations – each one persists, then refreshes every derived list.
  Future<void> addPartner(Partner p) async {
    await repo.addPartner(p);
    await loadAll();
  }

  Future<void> saveBike(Bike bike, Map<int, double> contributions) async {
    if (bike.id == null) {
      await repo.createBike(bike, contributions);
    } else {
      await repo.updateBike(bike);
    }
    await loadAll();
  }

  Future<void> changeStatus(int bikeId, BikeStatus status) async {
    await repo.updateBikeStatus(bikeId, status);
    await loadAll();
  }

  Future<void> deleteBike(int bikeId) async {
    await repo.deleteBike(bikeId);
    await loadAll();
  }

  Future<void> recordSale(Sale sale) async {
    await repo.recordSale(sale);
    await loadAll();
  }

  Future<void> undoSale(int saleId) async {
    await repo.undoSale(saleId);
    await loadAll();
  }

  Future<void> addExpense(Expense e) async {
    await repo.addExpense(e);
    await loadAll();
  }

  Future<void> deleteExpense(int id) async {
    await repo.deleteExpense(id);
    await loadAll();
  }

  Future<void> addContribution(Contribution c) async {
    await repo.addContribution(c);
    await loadAll();
  }

  Future<void> deleteContribution(int id) async {
    await repo.deleteContribution(id);
    await loadAll();
  }
}
