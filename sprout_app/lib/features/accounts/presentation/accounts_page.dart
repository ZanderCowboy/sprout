import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import 'package:sprout/core/core.dart';
import 'package:sprout/ui/export.dart';
import '../../home/presentation/home_bloc.dart';
import 'account_detail_page.dart';

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
        final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            );

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
                  child: Text(
                    'Tap + to add an account.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
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
                      'Current: ${formatZarFromCents(currentCents)}',
                      if (scheduledCents > 0)
                        'Scheduled: ${formatZarFromCents(scheduledCents)}',
                    ];
                    return ColoredEntityCard(
                      title: a.name,
                      subtitle: subtitleLines.join('\n'),
                      color: Color(a.color),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AccountDetailPage(account: a),
                          ),
                        );
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

