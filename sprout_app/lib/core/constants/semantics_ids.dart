/// Accessibility identifiers for Maestro (`tapOn: id:`) and screen readers.
///
/// Keep values stable — existing `.maestro/` flows depend on them.
abstract final class SemanticsIds {
  // --- Intro ---
  static const introNext = 'intro_next';
  static const introDebugSignIn = 'intro_debug_sign_in';

  // --- Sign in ---
  static const signInBack = 'sign_in_back';
  static const signInDisplayNameField = 'sign_in_display_name_field';
  static const signInEmailField = 'sign_in_email_field';
  static const signInSendCode = 'sign_in_send_code';
  static const signInOtpField = 'sign_in_otp_field';
  static const signInVerifyCode = 'sign_in_verify_code';
  static const signInGoogle = 'sign_in_google';
  static const signInTermsLink = 'sign_in_terms_link';
  static const signInPrivacyLink = 'sign_in_privacy_link';
  static const signInDebugSignIn = 'sign_in_debug_sign_in';

  // --- Startup ---
  static const startupRetry = 'startup_retry';

  // --- Account profile ---
  static const accountEditDisplayName = 'account_edit_display_name';
  static const accountSignOut = 'account_sign_out';
  static const accountTerms = 'account_terms';
  static const accountPrivacy = 'account_privacy';
  static const accountDelete = 'account_delete';
  static const accountEditNameField = 'account_edit_name_field';
  static const accountEditNameSave = 'account_edit_name_save';
  static const accountEditNameCancel = 'account_edit_name_cancel';
  static const accountDeleteConfirm = 'account_delete_confirm';
  static const accountDeleteCancel = 'account_delete_cancel';

  // --- Shell ---
  static const shellTabOverview = 'shell_tab_overview';
  static const shellTabAccounts = 'shell_tab_accounts';
  static const shellAdd = 'shell_add';
  static const shellTabGoals = 'shell_tab_goals';
  static const shellTabSettings = 'shell_tab_settings';
  static const shellActionNewAccount = 'shell_action_new_account';
  static const shellActionNewGoal = 'shell_action_new_goal';
  static const shellActionDeposit = 'shell_action_deposit';

  // --- Overview ---
  static const overviewEmptyTitle = 'overview_empty_title';
  static const overviewEmptyNewAccount = 'overview_empty_new_account';
  static const overviewEmptyNewGoal = 'overview_empty_new_goal';
  static const overviewEmptyDeposit = 'overview_empty_deposit';
  static const overviewProgressHeader = 'overview_progress_header';
  static const overviewDeposit = 'overview_deposit';
  static const overviewNewAccount = 'overview_new_account';
  static const overviewNewGoal = 'overview_new_goal';
  static const overviewTransactionRow = 'overview_transaction_row';
  static const overviewSeeAllTransactions = 'overview_see_all_transactions';

  // --- Account form / list / detail ---
  static const accountNameField = 'account_name_field';
  static const formSave = 'form_save';
  static const colorSwatch = 'color_swatch';
  static const accountCard = 'account_card';
  static const accountDetailDeposit = 'account_detail_deposit';
  static const accountDetailEdit = 'account_detail_edit';
  static const accountDetailDelete = 'account_detail_delete';
  static const accountDetailClearScheduled = 'account_detail_clear_scheduled';
  static const accountDetailTransactionRow = 'account_detail_transaction_row';
  static const accountDetailRecurring = 'account_detail_recurring';

  // --- Goal form / list / detail ---
  static const goalNameField = 'goal_name_field';
  static const goalTargetField = 'goal_target_field';
  static const goalAlreadySavedField = 'goal_already_saved_field';
  static const goalAlreadySavedAccount = 'goal_already_saved_account';
  static const goalNoAccountsNewAccount = 'goal_no_accounts_new_account';
  static const goalNoAccountsCancel = 'goal_no_accounts_cancel';
  static const goalCard = 'goal_card';
  static const goalSortMenu = 'goal_sort_menu';
  static const goalUnallocatedCard = 'goal_unallocated_card';
  static const goalDetailDeposit = 'goal_detail_deposit';
  static const goalDetailEdit = 'goal_detail_edit';
  static const goalDetailDelete = 'goal_detail_delete';
  static const goalDetailClearScheduled = 'goal_detail_clear_scheduled';
  static const goalDetailTransactionRow = 'goal_detail_transaction_row';
  static const goalDetailRecurring = 'goal_detail_recurring';

  // --- Deposit sheet ---
  static const depositAmountField = 'deposit_amount_field';
  static const depositNoAccountsNewAccount = 'deposit_no_accounts_new_account';
  static const depositModeToGoal = 'deposit_mode_to_goal';
  static const depositModeToAccount = 'deposit_mode_to_account';
  static const depositModeUseUnallocated = 'deposit_mode_use_unallocated';
  static const depositModeAddNewMoney = 'deposit_mode_add_new_money';
  static const depositAccountDropdown = 'deposit_account_dropdown';
  static const depositGoalDropdown = 'deposit_goal_dropdown';
  static const depositDatePicker = 'deposit_date_picker';
  static const depositRecurringToggle = 'deposit_recurring_toggle';
  static const depositFrequencyDropdown = 'deposit_frequency_dropdown';
  static const depositAddAllocation = 'deposit_add_allocation';
  static const depositRemoveAllocation = 'deposit_remove_allocation';
  static const depositSave = 'deposit_save';

  // --- Settings ---
  static const settingsAccount = 'settings_account';
  static const settingsPremium = 'settings_premium';
  static const settingsTransactions = 'settings_transactions';
  static const settingsRecurring = 'settings_recurring';
  static const settingsBudget = 'settings_budget';

  // --- Transactions ---
  static const transactionRow = 'transaction_row';
  static const transactionNoteField = 'transaction_note_field';
  static const transactionNoteSave = 'transaction_note_save';
  static const transactionManageRecurring = 'transaction_manage_recurring';

  // --- Recurring payments ---
  static const recurringRow = 'recurring_row';
  static const recurringEdit = 'recurring_edit';
  static const recurringSave = 'recurring_save';
  static const recurringDelete = 'recurring_delete';
  static const recurringCancel = 'recurring_cancel';

  // --- Budget ---
  static const budgetSort = 'budget_sort';
  static const budgetTabIncome = 'budget_tab_income';
  static const budgetTabEssentials = 'budget_tab_essentials';
  static const budgetTabLifestyle = 'budget_tab_lifestyle';
  static const budgetAddGroup = 'budget_add_group';
  static const budgetGroupCard = 'budget_group_card';
  static const budgetItemCard = 'budget_item_card';
  static const budgetGroupSave = 'budget_group_save';
  static const budgetSortSave = 'budget_sort_save';
  static const budgetSortCancel = 'budget_sort_cancel';

  // --- Dialogs (shared) ---
  static const dialogCancel = 'dialog_cancel';
  static const dialogDelete = 'dialog_delete';
  static const dialogSave = 'dialog_save';

  /// Color swatch id for palette index [1-based].
  static String colorSwatchAt(int oneBasedIndex) =>
      '${colorSwatch}_$oneBasedIndex';
}
