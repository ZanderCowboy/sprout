# Tooling

Flutter app directory: `sprout_app/` (package name `sprout`).

## Flavors

| Profile | Flavor | Entry | Config asset | Android applicationId |
|---------|--------|-------|--------------|------------------------|
| Dev | `development` | `lib/main_development.dart` | `assets/config/development.json` | `app.stackmint.sprout.dev` |
| Prod | `production` | `lib/main_production.dart` | `assets/config/production.json` | `app.stackmint.sprout` |

Launch from `.vscode/launch.json` (`Sprout · dev · …` / `Sprout · prod · …`) or:

```bash
cd sprout_app
flutter run --flavor development -t lib/main_development.dart
flutter run --flavor production -t lib/main_production.dart
```

Android still needs `--flavor` even if you use `lib/main.dart` (that file also loads development config).

## Checks (agent runs these)

```bash
cd sprout_app
flutter analyze
flutter test
```

Repo Makefile wrappers from the workspace root: `make analyze`, `make test`, `make check`.

Local gitignored config (flavor JSON, `google-services.json`, signing) → `<OneDrive>/Projects/sprout-local-config`. `make config-export` / `config-import` works on macOS and on Windows when Git for Windows is installed. Windows without Make: `scripts/sync-local-config.ps1`. Details: [secrets.md](secrets.md).

## Codegen

There is **no** `melos.yaml` and **no** `build_runner` today. Hive `TypeAdapter`s are hand-written in `sprout_app/lib/core/storage/hive_adapters.dart` and checked in.

If you add codegen later, introduce Melos first and run `build_runner` through Melos — never ad-hoc from a random package directory.

## GitHub CLI

Agent shells may not inherit workspace `GH_CONFIG_DIR`. Before any `gh` command:

```bash
export GH_CONFIG_DIR="$HOME/.config/gh-zandercowboy"
```

Must be account `ZanderCowboy`, never work `Zander-K`. Details: `docs/GITHUB_CLI_PERSONAL.md`.

## Firebase CLI

Firebase has no `GH_CONFIG_DIR` flag; auth is `$XDG_CONFIG_HOME/configstore/firebase-tools.json`. Agent shells may not inherit workspace `XDG_CONFIG_HOME`. Before any `firebase` command:

```bash
export XDG_CONFIG_HOME="$HOME/.config/firebase-personal"
```

Must be the personal Google account for Sprout, not work. Details: `docs/FIREBASE_CLI_PERSONAL.md`.

## Maestro MCP

Project MCP in `.cursor/mcp.json` starts the Maestro CLI MCP (`maestro mcp`). After adding or changing it, toggle the server in Cursor Settings → Tools & MCPs (or reload the window).

Local CLI (Windows): `C:\Programming\maestro\bin` — `maestro.bat` is on the user PATH. Requires Java 17+ (`JAVA_HOME` is `C:\Programming\Java\jdk-21`).

Use the MCP to inspect devices, run `.maestro/` flows, and author YAML. Call `cheat_sheet` before unfamiliar commands. Flows target the **development** flavor and tap **Debug sign in**. Human docs: `README.md` (Maestro UI Tests).

**After Dart/UI/semantics changes**, rebuild and reinstall before running Maestro (`flutter build apk --flavor development -t lib/main_development.dart` then `flutter install …`, or keep `flutter run --flavor development …` active on the device). Maestro hits the installed binary, not hot-reload state.

## gcloud CLI

gcloud stores auth and ADC under `$CLOUDSDK_CONFIG` (default `~/.config/gcloud`). Agent shells may not inherit workspace `CLOUDSDK_CONFIG`. Before any `gcloud` command:

```bash
export CLOUDSDK_CONFIG="$HOME/.config/gcloud-personal"
```

Must be the personal Google account and project `sprout-app-development`, not work. Details: `docs/GCLOUD_CLI_PERSONAL.md`.
