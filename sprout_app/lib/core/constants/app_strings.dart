abstract final class AppStrings {
  // --- App chrome ---
  static const String appTitle = 'Sprout';
  static const String tabOverview = 'Overview';
  static const String tabAccounts = 'Accounts';
  static const String tabGoals = 'Goals';
  static const String tabSettings = 'Settings';
  static const String actionAdd = 'Add';
  static const String sheetTitle = 'What would you like to do?';
  static const String newGoal = 'New goal';
  static const String deposit = 'Deposit';
  static const String allocation = 'Allocation';
  static const String addDeposit = 'Add deposit';
  static const String addDepositCaptionAccount =
      'This account is pre-selected — pick a goal and amount.';
  static const String addDepositCaptionGoal =
      'This goal is pre-selected — pick an account and amount.';
  static const String portfolioTotal = 'Portfolio total';
  static const String lastUpdated = 'Last updated';
  static const String neverUpdated = 'No activity yet';
  static const String accounts = 'Accounts';
  static const String goals = 'Goals';
  static const String offline = 'Offline';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String remove = 'Remove';
  static const String done = 'Done';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String or = 'or';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String details = 'Details';
  static const String color = 'Color';
  static const String icon = 'Icon';
  static const String date = 'Date';
  static const String time = 'Time';
  static const String note = 'Note';
  static const String total = 'Total';
  static const String current = 'Current';
  static const String scheduled = 'Scheduled';
  static const String history = 'History';
  static const String completed = 'Completed';
  static const String pending = 'Pending';
  static const String enabled = 'Enabled';
  static const String disabled = 'Disabled';
  static const String frequency = 'Frequency';
  static const String category = 'Category';
  static const String groups = 'Groups';
  static const String items = 'Items';
  static const String amount = 'Amount (ZAR)';
  static const String selectAccount = 'Account';
  static const String selectGoal = 'Goal';
  static const String transactions = 'Transactions';
  static const String remaining = 'Remaining';
  static const String progress = 'Progress';
  static const String newAccount = 'New account';
  static const String accountName = 'Account name';
  static const String goalName = 'Goal name';
  static const String targetAmount = 'Target amount (ZAR)';
  static const String syncError = 'Could not sync with the server';
  static const String unallocated = 'Unallocated';
  static const String unknownAccount = 'Unknown account';
  static const String unknownGoal = 'Unknown goal';
  static const String recentActivity = 'Recent activity';
  static const String overallProgress = 'Overall progress';
  static const String overallGoalsProgress = 'Overall goals progress';
  static const String saved = 'Saved';
  static const String target = 'Target';
  static const String disabledStatus = 'disabled';

  // --- Validation ---
  static const String goalTargetMustBePositive =
      'Target amount must be greater than zero.';
  static const String duplicateGoalName =
      'You already have a goal with this name.';
  static const String duplicateAccountName =
      'You already have an account with this name.';
  static const String nameRequired = 'Please enter a name.';
  static const String invalidAmount = 'Enter a valid amount.';
  static const String amountCannotBeNegative = 'Amount cannot be negative.';
  static const String pickAnAccount = 'Pick an account.';
  static const String pickAGoal = 'Pick a goal.';
  static const String pickAccountForOpeningBalance =
      'Pick an account for the opening balance.';
  static const String openingBalance = 'Opening Balance';
  static const String enterEmailAddress = 'Enter an email address.';
  static const String enterVerificationCode = 'Enter the verification code.';
  static const String duplicateGroupName =
      'You already have a group with this name.';
  static const String nameRequiredShort = 'Name required';

  // --- Auth ---
  static const String displayNameOptional = 'Display name (optional)';
  static const String displayNameExistingAccountHint =
      'Leave blank if you already have an account.';
  static const String displayName = 'Display name';
  static const String editDisplayName = 'Edit display name';
  static const String account = 'Account';
  static const String accountSectionProfile = 'Profile';
  static const String accountSectionSession = 'Session';
  static const String accountSectionLegal = 'Legal';
  static const String accountSectionDanger = 'Danger zone';
  static const String signedInWithGoogle = 'Signed in with Google';
  static const String signedInWithEmail = 'Signed in with email';
  static const String signOut = 'Sign out';
  static const String signOutKeepsLocalData =
      'Signing out keeps your local data on this device. '
      'Cloud sync pauses until you sign in again.';
  static const String deleteAccount = 'Delete account';
  static const String deleteAccountConfirmTitle = 'Delete your account?';
  static const String deleteAccountWarning =
      'This permanently removes your savings data from this device and the '
      'cloud. You cannot undo this.';
  static const String deleteAccountPremiumNote =
      'If you subscribe to Premium, deletion does not cancel or refund Play '
      'billing. Manage or cancel Premium separately.';
  static const String deleteAccountFailed =
      'Could not delete your account. Try again.';
  static const String termsOfService = 'Terms of Service';
  static const String privacyPolicy = 'Privacy Policy';
  static const String debugSignIn = 'Debug sign in';
  static const String debugSignInDetails = 'Maestro Test · maestro@test.local';
  static const String byContinuingYouAgree = 'By continuing you agree to the';
  static const String and = 'and';
  static const String termsLoadFailed = 'Could not load Terms of Service.';
  static const String privacyLoadFailed = 'Could not load Privacy Policy.';
  static const String signIn = 'Sign in';
  static const String signInSubtitle =
      'Sign in to sync your savings across devices.';
  static const String signInNotConfigured =
      'Sign-in isn’t configured for this build.';
  static const String email = 'Email';
  static const String sendCode = 'Send code';
  static const String verificationCode = 'Verification code';
  static const String verifyCode = 'Verify code';
  static const String continueWithGoogle = 'Continue with Google';
  static const String checkEmailForCode =
      'Check your email for a 6-digit code.';
  static const String couldNotVerifyCode = 'Could not verify the code.';
  static const String googleSignInFailed = 'Google Sign-In failed.';
  static const String googleSignInCancelled = 'Google Sign-In was cancelled.';
  static const String couldNotUpdateDisplayName =
      'Could not update display name.';
  static const String verifiedSessionRequired = 'Verified session required.';
  static const String supabaseNotConfigured =
      'Supabase is not configured. Sign-in is unavailable.';
  static const String googleSignInNotConfigured =
      'Google Sign-In is not configured. Add googleWebClientId to the flavor config.';
  static const String googleSignInNoIdToken =
      'Google Sign-In did not return an ID token.';
  static const String debugSignInDevOnly =
      'Debug sign-in is only available in the development flavor.';
  static const String introSlide1Title = 'Track your savings in one place';
  static const String introSlide1Body =
      'See your accounts, activity, and totals together so you always know where you stand.';
  static const String introSlide2Title = 'Set goals and watch them grow';
  static const String introSlide2Body =
      'Give each goal a target and watch progress build as you save.';
  static const String introSlide3Title = 'Sign in so your data stays with you';
  static const String introSlide3Body =
      'Your savings stay with your account, not only on this device.';

  // --- Empty state guidance ---
  static const String overviewEmptyTitle = 'Welcome to Sprout';
  static const String overviewEmptyStep1 = '1. Add an account';
  static const String overviewEmptyStep1Detail =
      'Create an account to hold your money (e.g. savings, wallet).';
  static const String overviewEmptyStep2 = '2. Create a goal';
  static const String overviewEmptyStep2Detail =
      'Set a target to save toward (e.g. vacation, new phone).';
  static const String overviewEmptyStep3 = '3. Make a deposit';
  static const String overviewEmptyStep3Detail =
      'Record money you put into an account and allocate it to a goal.';
  static const String accountsEmptyGuidance =
      'Add an account to track your money. Accounts hold deposits that you allocate to goals.';
  static const String goalsEmptyGuidance =
      'Create a goal to save toward. Goals track your progress toward targets.';
  static const String createAccountFirst =
      'Create an account first to hold money for this goal.';
  static const String addDepositCaptionAccountAmountOnly =
      'Enter an amount — this deposit goes to the account as unallocated.';
  static const String overviewEmptyDepositDisabled =
      'Available after you add a goal.';
  static const String noTransactionsYet = 'No transactions yet.';
  static const String noRecurringDepositsYet = 'No recurring deposits yet.';
  static const String noDepositsForAccount = 'No deposits yet for this account.';
  static const String noDepositsTowardGoal =
      'No deposits toward this goal yet.';
  static const String noAllocationsInGroup = 'No allocations in this group.';
  static const String accountNotFound = 'Account not found.';
  static const String transactionNotFound = 'Transaction not found.';
  static const String createAccountFirstShort = 'Create an account first';
  static const String addAccountBeforeDepositing =
      'Add at least one account before depositing.';

  // --- Deposit sheet ---
  static const String addNewMoney = 'Add new money';
  static const String useUnallocated = 'Use unallocated';
  static const String toGoal = 'To goal';
  static const String toAccount = 'To account';
  static const String addGoalFirstToDeposit =
      'Add a goal first to deposit directly to a goal.';
  static const String availableUnallocated = 'Available unallocated';
  static const String makeRecurringDeposit = 'Make this a recurring deposit';
  static const String allocateNowOptional = 'Allocate now (optional)';
  static const String noGoalsYetUnallocated =
      'No goals yet — this deposit will stay unallocated.';
  static const String removeAllocation = 'Remove allocation';
  static const String addAnotherGoal = 'Add another goal';
  static const String noUnallocatedForAccount =
      'No unallocated funds available for this account.';
  static const String enterAtLeastOneAllocation =
      'Enter at least one allocation amount.';
  static const String allocationsExceedUnallocated =
      'Allocations exceed available unallocated funds.';
  static const String allocationsExceedDeposit =
      'Allocations exceed deposited amount.';

  // --- Goals ---
  static const String sortGoals = 'Sort goals';
  static const String sortRemainingLowToHigh = 'Remaining (low → high)';
  static const String sortProgressHighToLow = 'Progress (high → low)';
  static const String sortNameAToZ = 'Name (A → Z)';
  static const String removeGoalConfirm =
      'Remove this goal? Past deposits stay in your history.';
  static const String clearScheduledTransactions =
      'Clear scheduled transactions?';
  static const String clearScheduled = 'Clear scheduled';
  static const String alreadySavedAmount = 'Already Saved Amount (ZAR)';
  static const String whichAccountHoldsMoney =
      'Which Account holds this money?';
  static const String unallocatedFunds = 'Unallocated funds';
  static const String accountValue = 'Account value';

  // --- Accounts ---
  static const String removeAccountConfirm =
      'Remove this account? Deposits stay in history locally; when online, the account row is removed from the server.';

  // --- Transactions ---
  static const String transaction = 'Transaction';
  static const String noteSaved = 'Note saved.';
  static const String couldNotSaveNotePrefix = 'Could not save note: ';
  static const String addANoteHint = 'Add a note…';
  static const String saving = 'Saving…';
  static const String kind = 'Kind';
  static const String recurring = 'Recurring';
  static const String nextScheduled = 'Next scheduled';
  static const String pendingSync = 'Pending sync';
  static const String group = 'Group';
  static const String recurringPayment = 'Recurring payment';
  static const String manageRecurringPayments = 'Manage recurring payments';
  static const String splitGroup = 'Split (group)';
  static const String depositTotal = 'Deposit total';
  static const String allocatedTotal = 'Allocated total';
  static const String recurringPayments = 'Recurring payments';
  static const String editRecurringPayment = 'Edit recurring payment';
  static const String cancelRecurringPaymentTitle =
      'Cancel recurring payment?';
  static const String cancelRecurringPaymentBody =
      'This will remove the recurring payment. Existing transactions already in your history will remain.';
  static const String recurringDeposit = 'Recurring deposit';
  static const String recurringDepositDisabled =
      'Recurring deposit (Disabled)';
  static const String recurringDepositWontApply =
      'This recurring deposit won’t be applied.';
  static const String cancelRemove = 'Cancel (remove)';
  static const String stopRecurring = 'Stop recurring';
  static const String seeAll = 'See all';
  static const String frequencyDaily = 'Daily';
  static const String frequencyWeekly = 'Weekly';
  static const String frequencyMonthly = 'Monthly';
  static const String frequencyYearly = 'Yearly';
  static const String frequencyNone = 'None';

  // --- Budget ---
  static const String masterBudget = 'Master Budget';
  static const String sortBudget = 'Sort budget';
  static const String theoreticalDisposableIncome =
      'Theoretical disposable income';
  static const String tapAboveForBreakdown = 'Tap above for breakdown';
  static const String budgetIncome = 'Income';
  static const String budgetEssentials = 'Essentials';
  static const String budgetLifestyle = 'Lifestyle';
  static const String sortAsIs = 'As is';
  static const String sortNameZToA = 'Name (Z → A)';
  static const String sortValueHighToLow = 'Value (high → low)';
  static const String sortValueLowToHigh = 'Value (low → high)';
  static const String newBudgetGroup = 'New budget group';
  static const String editGroup = 'Edit group';
  static const String groupName = 'Group name';
  static const String descriptionOptional = 'Description (optional)';
  static const String addBudgetGroup = 'Add budget group';
  static const String tapToAddGroup = 'Tap + to add a group';
  static const String colorAndIcon = 'Color & icon';
  static const String removeGroupTitle = 'Remove group?';
  static const String untitledGroup = 'Untitled group';
  static const String tapToAddDescription = 'Tap to add a description';
  static const String addItem = 'Add item';
  static const String removeItemTitle = 'Remove item?';
  static const String itemName = 'Item name';

  // --- Settings ---
  static const String premiumUnlocked = 'Premium unlocked.';
  static const String subscriptionUpdateFailed =
      'Subscription update failed.';
  static const String checkingSubscription = 'Checking subscription...';
  static const String premiumActive = 'Premium active';
  static const String unlockPremium =
      'Unlock premium with Monthly or Annual';
  static const String sproutPremium = 'Sprout Premium';
  static const String viewAllDeposits =
      'View all deposits and allocations';
  static const String viewEditCancelRecurring =
      'View, edit, or cancel recurring deposits';
  static const String planIncomeExpenses =
      'Plan income and expenses (static template)';
  static const String savingsApp = 'Savings app';

  // --- Startup ---
  static const String startupFailedTitle =
      'We couldn’t finish starting Sprout.';
  static const String retry = 'Retry';
  static const String retrying = 'Retrying…';
  static const String stackTraceDebugOnly = 'Stack trace (debug only)';
  static const String startupSteps = 'Startup steps';
  static const String configPrefix = 'Config: ';
  static const String startupHiveInit = 'Initializing local storage';
  static const String startupOpenBoxes = 'Opening boxes';
  static const String startupLoadConfig = 'Loading config';
  static const String startupInitRemoteConfig = 'Loading feature flags';
  static const String startupInitSupabase = 'Connecting to Supabase';
  static const String startupConfigureDI = 'Configuring services';
  static const String startupResolveUser = 'Resolving user';
  static const String startupConfigurePurchases = 'Configuring purchases';
  static const String startupFlushPending = 'Flushing pending sync';
  static const String startupPullRemote = 'Pulling remote data';

  // --- Shared UI / env ---
  static const String environmentDev = 'DEV';
  static const String environmentProd = 'PROD';

  static String colorNumber(int n) => 'Color $n';

  // --- Interpolated helpers (fragments stay stable for Maestro) ---
  static String dateWithLabel(String dateLabel) => 'Date · $dateLabel';

  static String yesWithFrequency(String freq) => 'Yes ($freq)';

  static String clearScheduledBody({
    required int count,
    required String scope,
  }) =>
      'This will remove $count future-dated '
      'transaction${count == 1 ? '' : 's'} from this $scope.';

  static String removeNamedConfirm(String name) =>
      'This will remove “$name”.';

  static String readyToSproutUnallocated(String amount) =>
      'Ready to Sprout! You have $amount waiting to be assigned.';

  static String currentColon(String amount) => 'Current: $amount';

  static String scheduledColon(String amount) => 'Scheduled: $amount';

  static String savedOfTarget(String saved, String target) =>
      'Saved $saved of $target.';

  static String savedSlashTarget(String saved, String target) =>
      'Saved: $saved / $target';

  static String remainingColon(String amount) => 'Remaining: $amount';

  static String savedAmount(String amount) => 'Saved $amount';

  static String targetAmountLabel(String amount) => 'Target $amount';

  static String toGoCompleteAllGoals(String amount) =>
      '$amount to go to complete all goals.';

  static String overallGoalsProgressSemantics({
    required int percent,
    required String saved,
    required String target,
  }) =>
      'Overall goals progress. $percent percent. Saved $saved of $target.';

  static String goalCardSemantics({
    required String name,
    required String remaining,
    required String saved,
    required String target,
    required int percent,
  }) =>
      '$name. ${AppStrings.remaining} $remaining. '
      'Saved $saved of $target. '
      '${AppStrings.progress} $percent percent.';

  static String goalChartLabel(String amount) => 'Goal: $amount';

  static String kindAmountLabel(String kind, String amount) =>
      '$kind $amount';

  static String kindSubtitle(String kind, String detail) =>
      '$kind · $detail';

  static String recurringDot(String freq) => 'Recurring · $freq';

  static String nextColon(String when) => 'next $when';

  static String goalLabelPrefix(String amount) =>
      '${AppStrings.selectGoal}: $amount';
}
