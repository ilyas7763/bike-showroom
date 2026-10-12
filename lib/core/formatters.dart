import 'package:intl/intl.dart';

/// Change this single constant to switch the currency label app-wide.
const String kCurrencySymbol = 'Rs ';

final NumberFormat _moneyFmt =
    NumberFormat.currency(symbol: kCurrencySymbol, decimalDigits: 0);
final DateFormat _dateFmt = DateFormat('dd MMM yyyy');

String money(num value) => _moneyFmt.format(value);
String dateStr(DateTime d) => _dateFmt.format(d);

/// Storage format for dates: yyyy-MM-dd (sorts correctly as text in SQLite).
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

double? parseAmount(String? s) =>
    double.tryParse((s ?? '').replaceAll(',', '').trim());

String? validateAmount(String? v) {
  final a = parseAmount(v);
  if (a == null || a <= 0) return 'Enter a valid amount';
  return null;
}

String? nullIfBlank(String? s) {
  final t = s?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

double roundMoney(double v) => (v * 100).roundToDouble() / 100;
