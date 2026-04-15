import 'package:intl/intl.dart';

String formatDate(DateTime dt) => DateFormat.yMMMd().format(dt.toLocal());

String formatDateTime(DateTime dt) =>
    DateFormat.yMMMd().add_jm().format(dt.toLocal());
