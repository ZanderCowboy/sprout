import 'package:flutter/material.dart';

import 'overview_page.dart';

@Deprecated('Split into OverviewPage and AccountsPage. Use OverviewPage.')
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const OverviewPage();
}
