import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/core/constants/hive_boxes.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/core/flags/remote_feature_flag.dart';
import 'package:sprout/core/storage/hive_adapters.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/auth/export.dart';
import 'package:sprout/features/budget/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/sync/export.dart';
import 'package:sprout/features/transactions/export.dart';

enum StartupStep {
  hiveInit,
  openBoxes,
  loadConfig,
  initRemoteConfig,
  initSupabase,
  configureDI,
  resolveUser,
  configurePurchases,
  flushPending,
  pullRemote,
}

enum StartupStepStatus { pending, running, done, skipped, failed }

abstract class StartupProgressReporter {
  void update(StartupStep step, StartupStepStatus status, {String? detail});

  /// Called after Remote Config activates (or defaults are applied).
  void onShowStartupChecks(bool enabled);
}

bool _hiveInitialized = false;
bool _supabaseInitialized = false;
bool _purchasesConfigured = false;
final RemoteConfigService _remoteConfigService = RemoteConfigService();

Future<void> initializeApp({
  required String configAssetPath,
  required AppEnvironment environment,
  required StartupProgressReporter reporter,
  required bool allowSupabase,
  required bool strictConfig,
}) async {
  reporter.update(StartupStep.hiveInit, StartupStepStatus.running);
  if (!_hiveInitialized) {
    await Hive.initFlutter();
    registerHiveAdapters();
    _hiveInitialized = true;
  }
  reporter.update(StartupStep.hiveInit, StartupStepStatus.done);

  reporter.update(StartupStep.openBoxes, StartupStepStatus.running);
  final settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
  final accountsBox = await Hive.openBox<AccountHiveModel>(HiveBoxes.accounts);
  final goalsBox = await Hive.openBox<GoalHiveModel>(HiveBoxes.goals);
  final budgetGroupsBox = await _openBudgetGroupsBox();
  final transactionsBox = await Hive.openBox<TransactionHiveModel>(
    HiveBoxes.transactions,
  );
  final pendingSyncBox = await Hive.openBox<PendingSyncHiveModel>(
    HiveBoxes.pendingSync,
  );
  reporter.update(StartupStep.openBoxes, StartupStepStatus.done);

  reporter.update(StartupStep.loadConfig, StartupStepStatus.running);
  final AppConfig config;
  Object? configError;
  StackTrace? configStackTrace;

  if (strictConfig) {
    config = await AppConfig.load(
      configAssetPath: configAssetPath,
      environment: environment,
    );
    config.assertValidSupabaseIfConfigured();
  } else {
    final loaded = await AppConfig.tryLoad(
      configAssetPath: configAssetPath,
      environment: environment,
    );
    config = loaded.config;
    configError = loaded.error;
    configStackTrace = loaded.stackTrace;
    if (configError == null) {
      config.assertValidSupabaseIfConfigured();
    }
  }

  reporter.update(
    StartupStep.loadConfig,
    configError == null ? StartupStepStatus.done : StartupStepStatus.failed,
    detail: configError == null ? null : '$configError',
  );

  if (configError != null && strictConfig) {
    Error.throwWithStackTrace(
      configError,
      configStackTrace ?? StackTrace.current,
    );
  }

  reporter.update(StartupStep.initRemoteConfig, StartupStepStatus.running);
  await _remoteConfigService.setup(config);
  await _remoteConfigService.fetchFlags();
  final showStartupChecks = _remoteConfigService.isEnabled(
    RemoteFeatureFlag.showStartupChecks,
  );
  reporter.onShowStartupChecks(showStartupChecks);
  reporter.update(
    StartupStep.initRemoteConfig,
    _remoteConfigService.isReady
        ? StartupStepStatus.done
        : StartupStepStatus.skipped,
    detail: showStartupChecks
        ? 'show_startup_checks=true'
        : 'show_startup_checks=false',
  );

  SupabaseClient? supabaseClient;
  if (allowSupabase && config.isSupabaseConfigured) {
    reporter.update(StartupStep.initSupabase, StartupStepStatus.running);
    if (!_supabaseInitialized) {
      await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabaseAnonKey,
      );
      _supabaseInitialized = true;
    }
    supabaseClient = Supabase.instance.client;
    reporter.update(StartupStep.initSupabase, StartupStepStatus.done);
  } else {
    reporter.update(StartupStep.initSupabase, StartupStepStatus.skipped);
  }

  reporter.update(StartupStep.configureDI, StartupStepStatus.running);
  await sl.reset(dispose: false);
  await configureDependencies(
    appConfig: config,
    settingsBox: settingsBox,
    accountsBox: accountsBox,
    goalsBox: goalsBox,
    budgetGroupsBox: budgetGroupsBox,
    transactionsBox: transactionsBox,
    pendingSyncBox: pendingSyncBox,
    supabaseClient: supabaseClient,
    remoteConfigService: _remoteConfigService,
  );
  reporter.update(StartupStep.configureDI, StartupStepStatus.done);

  reporter.update(StartupStep.resolveUser, StartupStepStatus.running);
  final userId = await sl<UserContext>().resolveUserId();
  reporter.update(StartupStep.resolveUser, StartupStepStatus.done);

  await _configurePurchases(config: config, userId: userId, reporter: reporter);

  final authService = sl<AuthService>();
  final canSync = authService.canSync;

  if (canSync) {
    reporter.update(StartupStep.flushPending, StartupStepStatus.running);
    await sl<SyncService>().flushPending();
    reporter.update(StartupStep.flushPending, StartupStepStatus.done);

    reporter.update(StartupStep.pullRemote, StartupStepStatus.running);
    await sl<AccountsRepository>().pullRemote();
    await sl<GoalsRepository>().pullRemote();
    await sl<BudgetRepository>().pullRemote();
    await sl<TransactionsRepository>().pullRemote();
    reporter.update(StartupStep.pullRemote, StartupStepStatus.done);
  } else {
    reporter.update(StartupStep.flushPending, StartupStepStatus.skipped);
    reporter.update(StartupStep.pullRemote, StartupStepStatus.skipped);
  }
}

Future<void> _configurePurchases({
  required AppConfig config,
  required String userId,
  required StartupProgressReporter reporter,
}) async {
  if (!config.isRevenueCatConfigured) {
    reporter.update(StartupStep.configurePurchases, StartupStepStatus.skipped);
    return;
  }

  final enabled = _remoteConfigService.isEnabled(
    RemoteFeatureFlag.revenueCatEnabled,
  );
  if (!enabled) {
    reporter.update(
      StartupStep.configurePurchases,
      StartupStepStatus.skipped,
      detail: 'remote flag off',
    );
    return;
  }

  reporter.update(StartupStep.configurePurchases, StartupStepStatus.running);
  try {
    if (!_purchasesConfigured) {
      await Purchases.setLogLevel(
        config.environment == AppEnvironment.development || kDebugMode
            ? LogLevel.debug
            : LogLevel.info,
      );
      final purchasesConfig = PurchasesConfiguration(
        config.revenueCatAndroidApiKey,
      )..appUserID = userId;
      await Purchases.configure(purchasesConfig);
      _purchasesConfigured = true;
    }
    reporter.update(StartupStep.configurePurchases, StartupStepStatus.done);
  } on Object catch (e) {
    if (kDebugMode) {
      debugPrint('RevenueCat configure failed: $e');
    }
    reporter.update(
      StartupStep.configurePurchases,
      StartupStepStatus.failed,
      detail: '$e',
    );
  }
}

Future<Box<BudgetGroupHiveModel>> _openBudgetGroupsBox() async {
  try {
    return await Hive.openBox<BudgetGroupHiveModel>(HiveBoxes.budgetGroups);
  } on RangeError catch (e) {
    if (kDebugMode) {
      debugPrint(
        'Budget groups box corrupted ($e). Deleting and recreating Hive box.',
      );
    }
    await Hive.deleteBoxFromDisk(HiveBoxes.budgetGroups);
    return await Hive.openBox<BudgetGroupHiveModel>(HiveBoxes.budgetGroups);
  }
}
