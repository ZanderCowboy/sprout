# Firebase Analytics for Sprout

This document covers Firebase Analytics integration for Sprout.

## Overview

Sprout tracks core analytics events via Firebase Analytics:
- `app_open` (automatic, tracked by Firebase SDK)
- `screen_view` with `screen_name` param
- `sign_in_success` with `method` param
- `sign_up_success` with `method` param
- `sign_out`
- `wizard_completed`
- `first_deposit_logged`

No PII (personally identifiable information) is logged in any event parameters.

**Event Catalog:** See `lib/core/analytics/analytics_events.dart` for the single source of truth on all event names, parameter names, and allowed values. Call sites reference this catalog rather than using raw strings.

## Configuration

### Development Flavor

Firebase Analytics is configured and active for the **development** flavor (`app.stackmint.sprout.dev`). Events are visible in Firebase Console DebugView.

### Production Flavor

The same Analytics API is used in the production flavor, but the production Firebase project remains unconfigured per issue #52. Enable production Firebase Analytics by completing #52.

## Architecture

### Event Catalog (`analytics_events.dart`)

Single source of truth defining:
- **Event names** (`AnalyticsEvent` constants)
- **Parameter names** (`AnalyticsParam` constants)
- **Allowed values** (`ScreenName`, `SignInMethod` constants)
- **Documentation** for each event and param

Call sites reference these constants instead of raw strings.

### Thin Service Layer (`AnalyticsService`)

`AnalyticsService` is a thin wrapper around Firebase Analytics. It only **sends** events — no business logic, no state tracking, no branching.

**Domain/app code decides when to fire events** based on business rules (e.g., first deposit tracking in `TransactionsServiceImpl`, sign-up vs sign-in logic in `AuthServiceImpl`).

The service provides a single method: `logEvent(String eventName, [Map<String, Object>? parameters])`.

## Events

For the complete event catalog with all allowed values, see `lib/core/analytics/analytics_events.dart`.

### `app_open`

**Automatic event** tracked by Firebase SDK when the app starts.

### `screen_view`

Logged automatically when users navigate between screens.

**Parameters:**
- `screen_name` (string): The screen identifier

**Tracked screens:**
- `overview` — Home overview page
- `accounts` — Accounts list
- `account` — Individual account detail
- `goals` — Goals list
- `settings` — Settings page
- `sign_in` — Sign-in page
- `create_account` — Create account page
- `verify_otp` — OTP verification page
- `wizard` — First-run wizard

**Location:** `AnalyticsNavigatorObserver` in app router

### `sign_in_success`

Logged after an existing user successfully signs in.

**Parameters:**
- `method` (string): The sign-in method used
  - `email_otp`: Email OTP verification (existing user)
  - `google`: Google Sign-In (returning user)
  - `other`: Other methods (reserved)

**Location:** `AuthServiceImpl.verifyEmailOtp()` and `AuthServiceImpl.signInWithGoogle()`

### `sign_up_success`

Logged after a new user successfully creates an account.

**Parameters:**
- `method` (string): The sign-up method used
  - `email_otp`: Email OTP verification (new user)
  - `google`: Google Sign-In (first-time user)
  - `other`: Other methods (reserved)

**Location:** `AuthServiceImpl.verifyEmailOtp()` (with `isSignUp=true`) and `AuthServiceImpl.signInWithGoogle()` (new user detection)

**Note:** Sign-up and sign-in are distinct events. A single auth action fires only one event, not both.

### `sign_out`

Logged when a user successfully signs out.

**Parameters:** None

**Location:** `AuthServiceImpl.signOut()`

### `wizard_completed`

Logged when a user completes the first-run wizard (goal + account + optional deposit).

**Parameters:** None

**Location:** `WizardCubit._complete()`

### `first_deposit_logged`

Logged the first time a user records a deposit transaction (via wizard or normal deposit flow).

**Parameters:** None

**Location:** `TransactionsServiceImpl._logFirstDepositIfNeeded()`

**Tracking:** Uses `UserContext.getFirstDepositLogged()` / `markFirstDepositLogged()` per user ID to ensure the event fires only once. Business logic lives in the service, not in `AnalyticsService`.

## Viewing Events in DebugView

1. Open Firebase Console → Analytics → DebugView
2. Build and install the development flavor:
   ```bash
   cd sprout_app
   flutter build apk --debug --flavor development -t lib/main_development.dart
   flutter install --debug --flavor development
   ```
3. Launch the app on a device/emulator
4. Events appear in DebugView within a few seconds

## Implementation

- **Event Catalog:** `lib/core/analytics/analytics_events.dart`
- **Service:** `AnalyticsService` (abstract) / `AnalyticsServiceImpl` (thin wrapper)
- **Location:** `lib/core/analytics/`
- **Setup:** Initialized in `startup_initializer.dart` after DI configuration
- **Dependencies:** `firebase_analytics` package (via `pubspec.yaml`)
- **Screen tracking:** `AnalyticsNavigatorObserver` registered in app router

## Out of Scope (MVP)

The following are intentionally excluded from the MVP and may be added later:
- Paywall analytics
- Funnel tracking
- A/B testing events
- BigQuery export
- Custom V2 metrics
- User properties
- Additional screen views (detail pages, dialogs, sheets)
