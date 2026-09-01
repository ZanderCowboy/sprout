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

        final scheme = Theme.of(context).colorScheme;
        final titleStyle = Theme.of(context).textTheme.titleMedium;

        if (state.accounts.isEmpty) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Text(AppStrings.accounts, style: titleStyle),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      AppStrings.accountsEmptyGuidance,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<HomeBloc>().add(const HomeSubscriptionRequested());
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(AppStrings.accounts, style: titleStyle),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList.separated(
                  itemCount: state.accounts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final a = state.accounts[i];
                    final currentCents =
                        state.accountCurrentTotalsById[a.id] ?? 0;
                    final scheduledCents =
                        state.accountScheduledTotalsById[a.id] ?? 0;
                    final subtitleLines = <String>[
                      AppStrings.currentColon(formatZarFromCents(currentCents)),
                      if (scheduledCents > 0)
                        AppStrings.scheduledColon(
                          formatZarFromCents(scheduledCents),
                        ),
                    ];
                    return ColoredEntityCard(
                      identifier: SemanticsIds.accountCard,
                      semanticsLabel: a.name,
                      title: a.name,
                      subtitle: subtitleLines.join('\n'),
                      color: Color(a.color),
                      onTap: () {
                        context.push(AppRoute.accountDetail.location(id: a.id));
                      },
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
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
