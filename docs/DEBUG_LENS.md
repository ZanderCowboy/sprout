# Debug Lens

Debug Lens is an on-device debugging panel that provides visibility into network calls, logs, navigation, Remote Config values, and other runtime information.

## Availability

### Development flavor
Debug Lens is **always enabled** in development builds:
- No Remote Config flag required
- Entry visible in Settings → Debug tools → Debug Lens

### Production flavor
Debug Lens is **gated by Remote Config**:
- Default: **disabled** (`debug_lens_enabled = false`)
- Enable for break-glass debugging by setting `debug_lens_enabled = true` in Firebase Remote Config
- Only visible in Settings when the flag is enabled

## Remote Config setup

### Flag name
```
debug_lens_enabled
```

### Default value
```json
false
```

### Enabling Debug Lens in production

1. Open [Firebase Console](https://console.firebase.google.com)
2. Select the Sprout production project
3. Navigate to **Remote Config**
4. Add or edit parameter:
   - **Parameter key**: `debug_lens_enabled`
   - **Value**: `true` (boolean)
5. Click **Publish changes**
6. Users will see Debug Lens after the next Remote Config fetch (typically within minutes for active sessions)

## Features

Debug Lens provides:
- **Network**: captured requests/responses (when Dio interceptor is configured)
- **Logs**: tagged log feed
- **Navigation**: route history
- **Remote Config**: current values and feature flags
- **Device & App**: device info, app version, platform details
- **Storage**: SharedPreferences inspection (debug_lens uses it internally)

## Current integration

The Sprout integration:
- Enables DebugLens when `shouldEnableDebugLens()` returns `true`
  - Development flavor: always `true`
  - Production flavor: `RemoteConfigService.isEnabled(debugLensEnabled)`
- Wraps the app with `DebugLens.wrap()` in `app.dart`
- Feeds Firebase Remote Config values via `DebugLens.setRemoteConfigData()`
- Provides Settings entry point (gated by visibility logic)

## Security

Debug Lens shows data already accessible to the client (Remote Config values, device info, navigation state). It does **not** expose server-side secrets, authentication tokens beyond what the client already holds, or Supabase RLS-protected data outside the current user's access.

Production use should still be limited to break-glass debugging scenarios, not continuous production deployment.

## Package

- Package: [`debug_lens`](https://pub.dev/packages/debug_lens) ^0.0.2
- Docs: [pub.dev/documentation/debug_lens](https://pub.dev/documentation/debug_lens/latest/)

## References

- GitHub issue: [#60 MVP debug_lens](https://github.com/ZanderCowboy/sprout/issues/60)
- Remote Config service: `lib/core/flags/remote_config_service.dart`
- Feature flag enum: `lib/core/flags/remote_feature_flag.dart` (`debugLensEnabled`)
- Settings entry: `lib/features/settings/presentation/settings_page.dart`
