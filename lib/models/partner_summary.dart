import 'partner.dart';

class PartnerSummary {
  final Partner partner;

  /// Everything this partner has put in (bike purchases + general capital).
  final double totalInvested;

  /// Capital not tied to a specific bike.
  final double generalCapital;

  /// Capital that went into bikes that have since been sold.
  final double investedInSoldBikes;

  /// This partner's share of net profit from sold bikes (pro-rata to contribution).
  final double profitShare;

  const PartnerSummary({
    required this.partner,
    required this.totalInvested,
    required this.generalCapital,
    required this.investedInSoldBikes,
    required this.profitShare,
  });

  /// Capital invested in bikes that are still unsold.
  double get capitalInStock =>
      totalInvested - generalCapital - investedInSoldBikes;

  /// Cash this partner is owed from sold bikes: capital back + profit share.
  double get payoutDue => investedInSoldBikes + profitShare;
}
