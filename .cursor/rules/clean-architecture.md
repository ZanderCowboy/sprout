# Clean-arch boundaries (features)

Applies to feature work under `sprout_app/lib/features/**`.

## Barrel exports
- Feature barrel files must be named `export.dart`.
- Import from `package:sprout/features/<feature>/export.dart` (not `.../<feature>.dart`).

## UI-only pages
- Files under `sprout_app/lib/features/**/presentation/**_page.dart` must be UI-only.
- Do not define `enum`s, top-level helper functions, or sorting/business logic in pages.
- Extract non-UI code to `sprout_app/lib/features/**/presentation/utils/**` or a bloc/service as appropriate.

## Reusable UI
- If the same UI pattern appears in 2+ features (form sheets, cards, empty states, buttons, pickers), prefer extracting a shared widget under `sprout_app/lib/ui/**` and re-using it.
- Feature UI (`features/**/presentation/**`) may depend on shared UI (`lib/ui/**`). Shared UI must not import feature code.
- Shared UI should stay “dumb”: take inputs + callbacks; do not call `sl<>`, repositories, or feature services directly.
- If a widget needs async work (save/delete/fetch), keep that in the feature (bloc/controller/service) and pass a callback/result into the shared widget.

## Enums location
- UI-specific enums live in `sprout_app/lib/features/**/presentation/enums/**`.
- Domain-wide enums live in `sprout_app/lib/features/**/domain/enums/**`.

## Frontend vs backend models and mapping
- Frontend entities used by UI/blocs live in `sprout_app/lib/features/**/domain/**`.
- Backend/storage/DTO models live under `sprout_app/lib/features/**/data/**/models/**`.
- Mapping functions live under `sprout_app/lib/features/**/data/mappers/**`.

## Dependency direction
- `presentation/**` may depend on `domain/**` and `application/**`.
- `presentation/**` must not import `data/local/**`, `data/remote/**`, or `data/**/models/**` directly.

