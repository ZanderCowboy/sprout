enum DepositFlowMode {
  fullDepositToGoal,
  depositToAccountThenAllocate,
  allocateExistingUnallocated,
}

class DepositAllocationInput {
  const DepositAllocationInput({
    required this.goalId,
    required this.amountCents,
  });

  final String goalId;
  final int amountCents;
}
