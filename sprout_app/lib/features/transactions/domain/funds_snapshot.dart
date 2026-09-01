import 'package:equatable/equatable.dart';

class FundsSnapshot extends Equatable {
  const FundsSnapshot({
    required this.savedCentsByGoalId,
    required this.unallocatedCents,
    required this.accountCurrentDepositTotalsById,
    required this.accountScheduledDepositTotalsById,
  });

  final Map<String, int> savedCentsByGoalId;
  final int unallocatedCents;
  final Map<String, int> accountCurrentDepositTotalsById;
  final Map<String, int> accountScheduledDepositTotalsById;

  @override
  List<Object?> get props => [
        savedCentsByGoalId,
        unallocatedCents,
        accountCurrentDepositTotalsById,
        accountScheduledDepositTotalsById,
      ];
}
