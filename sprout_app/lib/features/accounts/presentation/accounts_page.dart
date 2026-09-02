import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/ui/export.dart';
import '../../home/presentation/home_bloc.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! HomeReady) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<HomeBloc>().add(const HomeSubscriptionRequested());
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _AccountsHeader()),
              if (state.accounts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                      child: Text(
                        AppStrings.accountsEmptyGuidance,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverList.separated(
                    itemCount: state.accounts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final account = state.accounts[i];
                      final currentCents =
                          state.accountCurrentTotalsById[account.id] ?? 0;
                      final scheduledCents =
                          state.accountScheduledTotalsById[account.id] ?? 0;
                      final monthChange =
                          state.accountMonthChangePercentById[account.id];

                      return ColoredEntityCard.account(
                        identifier: SemanticsIds.accountCard,
                        semanticsLabel: account.name,
                        name: account.name,
                        kind: AppStrings.accountKindSavings,
                        amount: formatZarFromCents(currentCents),
                        changeLabel: monthChange == null
                            ? null
                            : AppStrings.percentThisMonth(monthChange),
                        footer: scheduledCents > 0
                            ? AppStrings.scheduledColon(
                                formatZarFromCents(scheduledCents),
                              )
                            : null,
                        color: Color(account.color),
                        onTap: () {
                          context.push(
                            AppRoute.accountDetail.location(id: account.id),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AccountsHeader extends StatelessWidget {
  const _AccountsHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SproutShellHeader(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.accounts, style: textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  AppStrings.accountsSubtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
