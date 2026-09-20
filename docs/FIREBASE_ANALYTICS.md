# Firebase Analytics for Sprout

This document covers the minimal MVP Firebase Analytics integration for Sprout.

## Overview

Sprout tracks a minimal set of analytics events via Firebase Analytics:
- `app_open` (automatic, tracked by Firebase SDK)
- `sign_in_success` with `method` param
- `wizard_completed`
- `first_deposit_logged`

No PII (personally identifiable information) is logged in any event parameters.

## Configuration

### Development Flavor

Firebase Analytics is configured and active for the **development** flavor (`app.stackmint.sprout.dev`). Events are visible in Firebase Console DebugView.

### Production Flavor

The same Analytics API is used in the production flavor, but the production Firebase project remains unconfigured per issue #52. Enable production Firebase Analytics by completing #52.

## Events

### `app_open`

**Automatic event** tracked by Firebase SDK when the app starts.

### `sign_in_success`

Logged after a user successfully signs in.

**Parameters:**
- `method` (string): The sign-in method used
  - `email_otp`: Email OTP verification
  - `google`: Google Sign-In
  - `other`: Other methods (reserved)

**Location:** `AuthServiceImpl.verifyEmailOtp()` and `AuthServiceImpl.signInWithGoogle()`

### `wizard_completed`

Logged when a user completes the first-run wizard (goal + account + optional deposit).

**Parameters:** None

**Location:** `WizardCubit._complete()`

### `first_deposit_logged`

Logged the first time a user records a deposit transaction (via wizard or normal deposit flow).

**Parameters:** None

**Location:** `TransactionsServiceImpl.recordDeposit()` and `TransactionsServiceImpl.recordAccountDeposit()`

**Tracking:** Uses `UserContext.getFirstDepositLogged()` / `markFirstDepositLogged()` per user ID to ensure the event fires only once.

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

- **Service:** `AnalyticsService` (abstract) / `AnalyticsServiceImpl`
- **Location:** `lib/core/analytics/`
- **Setup:** Initialized in `startup_initializer.dart` during app startup
- **Dependencies:** `firebase_analytics` package (via `pubspec.yaml`)

## Out of Scope (MVP)

The following are intentionally excluded from the MVP and may be added later:
- Paywall analytics
- Funnel tracking
- A/B testing events
- BigQuery export
- Custom V2 metrics
- Screen view tracking
- User properties
