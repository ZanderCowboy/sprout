abstract final class AppStrings {
  static const String appTitle = 'Sprout';
  static const String tabOverview = 'Overview';
  static const String tabAccounts = 'Accounts';
  static const String tabGoals = 'Goals';
  static const String tabSettings = 'Settings';
  static const String actionAdd = 'Add';
  static const String sheetTitle = 'What would you like to do?';
  static const String newGoal = 'New goal';
  static const String deposit = 'Deposit';
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
  static const String goalTargetMustBePositive =
      'Target amount must be greater than zero.';
  static const String duplicateGoalName =
      'You already have a goal with this name.';
  static const String duplicateAccountName =
      'You already have an account with this name.';
  static const String nameRequired = 'Please enter a name.';
  static const String invalidAmount = 'Enter a valid amount.';
  static const String amountCannotBeNegative = 'Amount cannot be negative.';
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

  // Empty state guidance
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
}
