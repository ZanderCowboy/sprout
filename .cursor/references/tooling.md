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
