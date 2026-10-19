import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

String formatCurrency(num value) => _currency.format(value);
