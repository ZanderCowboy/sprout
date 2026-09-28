import 'package:intl/intl.dart';

/// Manage Subscription date style matching the Stitch mock (`28 Oct 2026`).
String formatManageSubscriptionDate(DateTime date) =>
    DateFormat('d MMM y').format(date.toLocal());
