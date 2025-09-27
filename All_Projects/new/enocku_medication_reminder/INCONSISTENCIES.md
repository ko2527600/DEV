## Inconsistencies, Risks, and Remediations

### 1) Secrets committed in repo
- Evidence: `lib/src/core/config/supabase_config.dart` contains real URL and anon key.
- Risk: Credential leakage; misuse; rate-limit/abuse.
- Fix:
  - Move to env loader (e.g., `flutter_dotenv` or `flutter_config`).
  - Use `--dart-define` for CI builds.
  - Rotate keys in Supabase.

### 2) Drift code still present alongside Supabase
- Evidence: `lib/src/core/database/*` and related providers.
- Risk: Confusion, dead code, larger app size.
- Fix: Remove Drift files and dev deps; or gate behind feature flag. Update `pubspec.yaml` accordingly.

### 3) `getMedicationsNeedingRefill` column compare
- Evidence: `.lte('remaining_quantity', 'refill_threshold')` likely compares to a string literal, not a column.
- Risk: Incorrect filtering.
- Fix: Use a server RPC or filter client-side; e.g., fetch active meds and compute `(remaining <= threshold)`.

### 4) Missing `user_id` on inserts
- Evidence: `AddMedicationScreen` builds `medication` map without `user_id`.
- Risk: RLS insert may fail; cross-user data leakage if policies relax.
- Fix: Add `user_id: Supabase.instance.client.auth.currentUser!.id` on insert.

### 5) Auth routing not enforced
- Evidence: `GoRouter` always starts at `/splash` → `/onboarding` → `/`.
- Risk: Unauthenticated access to data screens.
- Fix: Read auth state provider; redirect unauthenticated users to `/auth`.

### 6) README vs DOCUMENTATION drift
- Evidence: `README.md` still says "A new Flutter project"; real docs are in `DOCUMENTATION.md`.
- Risk: Onboarding confusion.
- Fix: Replace root README with project summary and quick start.


