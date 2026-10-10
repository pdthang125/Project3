import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _vndFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static String formatVND(double amount) => _vndFormatter.format(amount);

  static String formatVNDShort(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}T ₫';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ₫';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K ₫';
    }
    return '${amount.toStringAsFixed(0)} ₫';
  }
}

class DateFormatter {
  DateFormatter._();

  static final _displayFormat = DateFormat('dd/MM/yyyy');
  static final _shortFormat = DateFormat('dd MMM');
  static final _monthYear = DateFormat('MMM yyyy');

  static String toDisplay(DateTime date) => _displayFormat.format(date);
  static String toDMY(DateTime date) => _displayFormat.format(date);
  static String toShort(DateTime date) => _shortFormat.format(date);
  static String toMonthYear(DateTime date) => _monthYear.format(date);

  static String toRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hôm nay';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return toDisplay(date);
  }
}
