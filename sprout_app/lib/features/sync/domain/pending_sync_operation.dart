enum PendingSyncOperationType {
  insertTransaction,
  upsertAccount,
  deleteAccount,
  upsertGoal,
  deleteGoal,
  // Appended to preserve existing index values.
  deleteTransaction,
  upsertBudgetGroup,
  deleteBudgetGroup,
}
