import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/constants/hive_boxes.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/core/storage/hive_adapters.dart';
import 'package:sprout/core/storage/migrate_hive_user_id_to_auth.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/accounts.dart';
import 'package:sprout/features/goals/goals.dart';
import 'package:sprout/features/sync/sync.dart';
import 'package:sprout/features/transactions/transactions.dart';

enum StartupStep {
  hiveInit,
  openBoxes,
  loadConfig,
  initSupabase,
  configureDI,
  resolveUser,
  migrateUserIds,
  flushPending,
  pullRemote,
}

enum StartupStepStatus { pending, running, done, skipped, failed }

abstract class StartupProgressReporter {
  void update(
    StartupStep step,
    StartupStepStatus status, {
    String? detail,
  });
}

bool _hiveInitialized = false;
bool _supabaseInitialized = false;

Future<void> initializeApp({
  required String configAssetPath,
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
  final transactionsBox =
      await Hive.openBox<TransactionHiveModel>(HiveBoxes.transactions);
  final pendingSyncBox =
      await Hive.openBox<PendingSyncHiveModel>(HiveBoxes.pendingSync);
  reporter.update(StartupStep.openBoxes, StartupStepStatus.done);

  reporter.update(StartupStep.loadConfig, StartupStepStatus.running);
  final AppConfig config;
  Object? configError;
  StackTrace? configStackTrace;

  if (strictConfig) {
    config = await AppConfig.load(configAssetPath: configAssetPath);
    config.assertValidSupabaseIfConfigured();
  } else {
    final loaded = await AppConfig.tryLoad(configAssetPath: configAssetPath);
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
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        await supabaseClient.auth.signInAnonymously();
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Supabase anonymous sign-in failed: $e. '
          'Enable Anonymous under Authentication → Providers, then restart.',
        );
      }
    }
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
    transactionsBox: transactionsBox,
    pendingSyncBox: pendingSyncBox,
    supabaseClient: supabaseClient,
  );
  reporter.update(StartupStep.configureDI, StartupStepStatus.done);

  reporter.update(StartupStep.resolveUser, StartupStepStatus.running);
  await sl<UserContext>().resolveUserId();
  reporter.update(StartupStep.resolveUser, StartupStepStatus.done);

  reporter.update(StartupStep.migrateUserIds, StartupStepStatus.running);
  final authUserId = supabaseClient?.auth.currentUser?.id;
  if (authUserId != null && authUserId.isNotEmpty) {
    await migrateHiveUserIdsToAuthUser(
      authUserId: authUserId,
      accounts: sl(),
      goals: sl(),
      transactions: sl(),
    );
    reporter.update(StartupStep.migrateUserIds, StartupStepStatus.done);
  } else {
    reporter.update(StartupStep.migrateUserIds, StartupStepStatus.skipped);
  }

  reporter.update(StartupStep.flushPending, StartupStepStatus.running);
  await sl<SyncService>().flushPending();
  reporter.update(StartupStep.flushPending, StartupStepStatus.done);

  if (allowSupabase && config.isSupabaseConfigured) {
    reporter.update(StartupStep.pullRemote, StartupStepStatus.running);
    await sl<AccountsRepository>().pullRemote();
    await sl<GoalsRepository>().pullRemote();
    await sl<TransactionsRepository>().pullRemote();
    reporter.update(StartupStep.pullRemote, StartupStepStatus.done);
  } else {
    reporter.update(StartupStep.pullRemote, StartupStepStatus.skipped);
  }
}

