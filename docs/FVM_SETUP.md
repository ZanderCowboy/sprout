# FVM Setup for Sprout

Sprout uses [FVM (Flutter Version Management)](https://fvm.app/) to isolate its Flutter SDK version from other projects on your machine. This ensures Sprout runs on Flutter 3.47.5 without affecting work projects like Grosvenor (which stays on 3.38.10).

## Prerequisites

Install FVM if you haven't already:

### macOS

```bash
brew install fvm
```

Or using Dart pub:

```bash
dart pub global activate fvm
```

### Windows

Using Chocolatey:

```powershell
choco install fvm
```

Or using Dart pub:

```powershell
dart pub global activate fvm
```

After installing via pub, ensure `$HOME/.pub-cache/bin` (macOS) or `%USERPROFILE%\AppData\Local\Pub\Cache\bin` (Windows) is in your PATH.

## Initial Setup

1. **Install the pinned Flutter version** for Sprout:

   ```bash
   cd /path/to/sprout
   fvm install
   ```

   This reads `.fvmrc` (JSON: `{"flutter": "3.47.5"}`) and downloads that SDK
   version into FVM's cache. FVM 4 requires JSON; a bare version string such as
   `3.47.5` will crash `fvm install` with a `FormatException`.

2. **Verify the installation**:

   ```bash
   fvm flutter --version
   ```

   Should report Flutter 3.47.5 and Dart 3.13.x.

3. **Run pub get** using FVM:

   ```bash
   cd sprout_app
   fvm flutter pub get
   ```

## Using FVM with Sprout

### Command Line

Prefix all `flutter` commands with `fvm` when working in the Sprout repository:

```bash
cd sprout_app
fvm flutter run --flavor development -t lib/main_development.dart
fvm flutter build apk --release --flavor development -t lib/main_development.dart
fvm flutter analyze
fvm flutter test
```

### IDE Setup (VS Code / Cursor)

The workspace settings in `.vscode/settings.json` already point to `.fvm/flutter_sdk`, so the Dart extension will automatically use the FVM-managed SDK. No additional configuration needed.

If you need to manually configure it:

1. Open Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`)
2. Run **"Dart: Change SDK"**
3. Select the `.fvm/flutter_sdk` path

### Important: Work Projects Isolation

**Do NOT run `flutter upgrade` in your global Flutter installation** or in the Grosvenor work project directory. Sprout's FVM setup is completely isolated:

- **Sprout**: Uses FVM with Flutter 3.47.5 (via `.fvm/flutter_sdk`)
- **Grosvenor / work projects**: Continue using FVM with Flutter 3.38.10 (their own `.fvmrc`)

Each project's `.fvmrc` controls its own Flutter version. FVM caches all versions globally but activates the correct one per project.

## Windows-Specific Notes

- FVM cache location: `%LOCALAPPDATA%\fvm\versions\`
- If using Git Bash or PowerShell, `fvm flutter` works the same
- Ensure FVM is in your PATH after installation

## macOS-Specific Notes

- FVM cache location: `~/Library/Application Support/fvm/versions/` (Intel) or `~/Library/Application Support/fvm/versions/` (Apple Silicon)
- If you previously used a global Flutter SDK, remove it from PATH or ensure `fvm flutter` resolves to the FVM shim first

## Troubleshooting

**`fvm install` fails with `FormatException: Unexpected character`**

- `.fvmrc` must be JSON, not a bare version. Use `{"flutter": "3.47.5"}`.
- Recreate it with `fvm use 3.47.5` if needed.

**"flutter: command not found" when running `fvm flutter`**

- Ensure FVM is installed and in your PATH
- Try running `fvm list` to confirm FVM works
- Run `fvm install` in the Sprout root to install the pinned SDK

**IDE still showing old Flutter version**

- Restart VS Code / Cursor after running `fvm install`
- Verify `.vscode/settings.json` has `"dart.flutterSdkPath": ".fvm/flutter_sdk"`
- Check that `.fvm/flutter_sdk` symlink exists (created by `fvm install`)

**Accidentally upgraded global Flutter / work project SDK**

- Work projects: Check their `.fvmrc` and run `fvm install` to restore the correct version
- Global Flutter: Reinstall FVM versions as needed; FVM isolates each project

## Additional Resources

- [FVM Documentation](https://fvm.app/)
- [FVM GitHub](https://github.com/leoafarias/fvm)
