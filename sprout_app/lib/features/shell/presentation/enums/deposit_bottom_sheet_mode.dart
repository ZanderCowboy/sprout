/// How the deposit bottom sheet collects and submits money.
enum DepositBottomSheetMode {
  /// Deposit and immediately assign to a single goal.
  fullDepositToGoal,

  /// Deposit to account, then optionally allocate some/all of it to goals.
  depositToAccountThenAllocate,

  /// Allocate existing unallocated funds into one or more goals (no new deposit).
  allocateExistingUnallocated,
}
