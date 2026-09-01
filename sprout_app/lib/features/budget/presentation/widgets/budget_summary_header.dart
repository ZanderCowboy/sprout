import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

import '../budget_bloc.dart';

class BudgetSummaryHeader extends StatefulWidget {
  const BudgetSummaryHeader({super.key, required this.state});

  final BudgetReady state;

  @override
  State<BudgetSummaryHeader> createState() => _BudgetSummaryHeaderState();
}

class _BudgetSummaryHeaderState extends State<BudgetSummaryHeader> {
  bool _showBreakdown = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = widget.state;
    final disposableCents = (state.disposableIncome * 100).round();
    final isNegative = disposableCents < 0;
    final valueColor = isNegative ? scheme.error : scheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, _showBreakdown ? 14 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _showBreakdown = !_showBreakdown),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_tree_rounded,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.theoreticalDisposableIncome,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Icon(
                        _showBreakdown
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: scheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatZarFromCents(disposableCents),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
            if (!_showBreakdown) ...[
              const SizedBox(height: 4),
              Text(
                AppStrings.tapAboveForBreakdown,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (_showBreakdown) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _MiniTotalPill(
                    label: AppStrings.budgetIncome,
                    value: formatZarFromCents(
                      (state.totalIncome * 100).round(),
                    ),
                    icon: Icons.trending_up_rounded,
                    color: scheme.primary,
                  ),
                  _MiniTotalPill(
                    label: AppStrings.budgetEssentials,
                    value: formatZarFromCents(
                      (state.totalEssentials * 100).round(),
                    ),
                    icon: Icons.home_rounded,
                    color: scheme.tertiary,
                  ),
                  _MiniTotalPill(
                    label: AppStrings.budgetLifestyle,
                    value: formatZarFromCents(
                      (state.totalLifestyle * 100).round(),
                    ),
                    icon: Icons.local_cafe_rounded,
                    color: scheme.secondary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniTotalPill extends StatelessWidget {
  const _MiniTotalPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
