# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

- This repository is a Flutter app named **Coffer**; the Dart package name and some internal identifiers still use the older codename `gwp`.
- The app is **local-first**: user financial data stays on-device. Network access is only for public metadata and market data (Frankfurter FX, Eastmoney, Yahoo, OKX, REST Countries), and should never send account or holdings data outward.
- Android is the primary validation target; iOS is kept build-compatible.

## Common commands

```bash
flutter pub get
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

```bash
dart run build_runner watch --delete-conflicting-outputs
```

```bash
flutter analyze
```

```bash
flutter test
```

Run a single test file:

```bash
flutter test test/features/account_repository_test.dart
```

Run a single test by name:

```bash
flutter test --plain-name "updates market value" test/features/valuate_asset_test.dart
```

Run the app locally:

```bash
flutter run
```

Build Android APKs:

```bash
flutter build apk --debug
flutter build apk --release
```

Install Android builds:

```bash
flutter install -d emulator-5554 --use-application-binary "build/app/outputs/flutter-apk/app-debug.apk"
```

For a physical Android phone, prefer `adb install -r` with the release APK so local app data is preserved when possible. Avoid `flutter install` for the phone because it may uninstall the old app first.

```bash
adb -s <device-id> install -r "build/app/outputs/flutter-apk/app-release.apk"
```

If package identity or signing changes, Android may still reject in-place replacement and require a reinstall.

After a code change passes its required verification, default to installing automatically without waiting for an extra user prompt.

Regenerate app assets when branding config changes:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## When code generation is required

Run build_runner after changing any of the following:

- Drift tables, DAOs, or database definitions
- `freezed` entities
- `json_serializable` models

If you change the database schema, update both `schemaVersion` and the migration logic in `lib/data/db/database.dart`.

## Architecture overview

### Application shell and navigation

- `lib/main.dart` initializes Flutter bindings, installs global error handlers, initializes local notifications, and starts the app with `ProviderScope`.
- Routing lives in `lib/app/router.dart` and uses `go_router`.
- The main app experience is a `ShellRoute` with persistent top-level sections: `/dashboard`, `/holdings`, `/events`, `/rates`, and `/cards`.
- Detail and create/edit routes for entities live outside the shell.
- Edit routes consistently use `_EntityEditLoader` to load the current entity from Riverpod before rendering the create/edit page.
- The shell also owns cross-feature UX patterns such as the floating bottom navigation, global search entry point, keyboard shortcut (`Cmd/Ctrl+K`), and horizontal-swipe navigation between top-level tabs.

### Layering

The codebase follows a consistent dependency direction:

```text
presentation -> domain <- data
```

- `lib/app/`: app shell concerns such as routing and theme
- `lib/core/`: cross-cutting infrastructure such as auth, crypto, notifications, result/error types, shared UI, formatting, and search helpers
- `lib/data/`: Drift database, DAOs, repository implementations, backup logic, and remote provider implementations
- `lib/domain/`: framework-independent entities, repository/provider interfaces, valuation logic, events, and use cases
- `lib/features/`: feature presentation code plus feature-scoped Riverpod composition

A key repo rule: UI should consume **domain entities**, not Drift row objects.

### Riverpod composition pattern

- The database is created once through `appDatabaseProvider`, then reused through provider wiring.
- Feature/provider files compose the dependency chain: DAO -> repository -> use case -> UI-facing provider.
- Keep orchestration in Riverpod provider files and feature presentation layers; keep domain use cases framework-agnostic.
- Representative entry points are `lib/features/asset/presentation/asset_providers.dart`, `lib/features/event/presentation/event_providers.dart`, and the provider files under `lib/data/providers/`.

### Persistence, money, and encryption

- Persistence is Drift over encrypted SQLite in `lib/data/db/database.dart`.
- The app uses `sqlite3mc` hooks rather than plain SQLite; database open/setup and schema migration are handled inside `AppDatabase`.
- Monetary and quantity values are intentionally stored as **TEXT decimal strings** and converted through `Decimal` in application code. Do not migrate these values to `double`/`REAL`.
- Soft-delete behavior is part of the schema design; many queries assume `is_deleted = 0` filtering and related partial indexes.
- Sensitive card fields are protected twice:
  - encrypted database storage
  - field-level AES-GCM encryption with keys derived from the platform-backed master key
- Backup/restore is a manual file-based flow under `/backup`; exported packages remain password-encrypted. Backups include portable card-number recovery, but do not include CVV.

### Data model boundaries that matter

- `AppDatabase` owns the authoritative schema, migrations, partial indexes, and built-in dictionary seeding.
- Current schema includes core entities plus support tables such as `account_channels`, `dict_entries`, `asset_price_history`, `asset_cost_history`, `watched_pairs`, and `search_history_entries`.
- Dictionary-backed values such as currency, sovereignty region, and transfer protocol are not meant to be free-form strings. Preserve both the dictionary-driven UI selection and use-case level membership validation.

### Events vs audit history

This repo intentionally separates operational events from valuation history:

- `lib/domain/events/event_bus.dart` defines an **in-memory** broadcast bus only.
- Persist an event before emitting it on the bus.
- Successful asset valuations do **not** go into the `events` table anymore.
- Successful valuations are written to `asset_price_history` instead.
- User-driven cost basis or quantity adjustments are recorded in `asset_cost_history`.
- The `events` table is for actionable items such as failures, alerts, due items, and ack workflows.

This split is important because the UI uses `events` for user-facing signal, while charts and valuation history read from audit/history tables.

### Valuation, FX, and portfolio totals

Asset pricing is coordinated rather than embedded in widgets:

- `AssetValuationRouter` selects the valuation strategy by asset type.
- Current strategies include fixed-income, market-quote, and manual valuation.
- `RefreshAssetPriceUseCase` handles quote fetching, FX conversion, event emission, asset update, and history recording.
- `ValuateAssetUseCase` updates `asset.currentPrice`, recalculates `marketValue`, and records an `AssetPriceHistoryPoint` atomically.
- Cross-currency portfolio aggregation goes through `ValueAssetsInCurrencyUseCase`; top-level pages should not sum raw `asset.marketValue` across mixed currencies.
- FX lookup is layered: local DB snapshot, inverse-rate derivation when possible, cached remote result, then Frankfurter remote fallback.

### Transfer and relationship model

- Channels are not hard-bound to a single source/target account type.
- Account-to-channel capability is modeled through `account_channels`, which gives the transfer planner a graph to search.
- Route planning and fee calculation live in domain use cases and rule engines rather than widgets.
- Account-level channel fee overrides replace channel defaults rather than stacking on top of them.

### Search and feature composition

- Global search is a cross-feature concern implemented in shared UI and opened from the shell.
- Search history is stored in the encrypted local database, not in plaintext files.
- Feature pages generally observe Drift-backed streams through Riverpod so changes propagate directly into the UI.

## Important docs

For deeper context, read:

- `README.md`
- `doc/architecture.md`
- `doc/data-definitions.md`
- `doc/er-diagram.md`
