## Design: TAKE MEDICATION

### 1. Architecture Overview
- Flutter app using Riverpod and GoRouter
- Data layer: Supabase (Postgres) via `supabase_flutter`
- Presentation: Feature-first foldering (`features/*/presentation`)

### 2. Current Code vs Docs
- `pubspec.yaml` includes Supabase and still has Drift dev deps; some Drift files remain in `lib/src/core/database/*` though providers and screens now consume Supabase providers. Plan: remove Drift or isolate behind flags.

### 3. Key Modules
- `SupabaseService`: CRUD for medications, schedules, logs; auth helpers
- `supabase_providers.dart`: Riverpod providers for queries and actions
- Screens: `splash`, `onboarding`, `auth`, `medications`
- Routing: `GoRouter` in `app.dart`

### 4. Data Flow (Medications)
1. UI reads `supabaseMedicationsProvider`
2. Provider calls `SupabaseService.getMedications()`
3. Service issues `select` on `medications` table with RLS
4. UI renders cards; actions navigate to add/edit/detail
5. Add uses `supabaseMedicationActionsProvider.addMedication`

### 5. Authentication Flow
- Bootstrap: `main.dart` calls `Supabase.initialize` using `SupabaseConfig`
- `AuthScreen` uses `SupabaseService.signIn/signUp`
- Future: redirect based on `authStateChanges`

### 6. Navigation Map
- `/splash` → `/onboarding` → `/` (medication list)
- `/auth`
- `/add`, `/edit/:id`, `/detail/:id`

### 7. Security & Privacy
- RLS policies per `SUPABASE_SETUP.md` for all three tables
- Do not commit real URL/anon key; load via env for production

### 8. Error Handling
- Service methods throw typed `Exception` with context
- UI shows `SnackBar`/error sections; TODO: centralize error surface and logging

### 9. Theming & UX
- Material 3; light/dark themes defined in `app.dart`
- Consistent components for cards/buttons/inputs

### 10. Open Issues / Decisions
- Remove Drift remnants to reduce confusion, or provide an abstraction that can switch providers (Supabase vs Drift) via build flavor.
- Add `user_id` on inserts from client; currently not included in `AddMedicationScreen`. With RLS, insert requires `user_id = auth.uid()`.
- `getMedicationsNeedingRefill` uses `lte('remaining_quantity', 'refill_threshold')`: value vs column compare likely incorrect. Should use SQL or RPC, or compute client-side.
- Secrets are committed in `supabase_config.dart`; must be moved out.

### 11. Next Changes
- Introduce an auth gate and redirect: if unauthenticated → `/auth`, else `/`
- Add repository layer for medications to abstract service/provider
- Implement schedules and logs screens


