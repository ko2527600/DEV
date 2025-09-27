## Project Tasks: TAKE MEDICATION

Legend: [ ] pending, [~] in-progress, [x] done, [!] blocked

### Milestone M1: Add Medication (Sprint 1)
- [ ] Gate routes by auth state (redirect to `/auth` if signed out)
- [ ] Move Supabase URL/key to env loader (no secrets in repo)
- [ ] Fix `getMedicationsNeedingRefill` logic (server RPC or client compare)
- [ ] Add `user_id` on inserts (use `auth.uid()` from Supabase)
- [ ] Medication list: wire edit/delete actions; implement soft-delete
- [ ] Medication detail: show fields, schedules, and logs placeholder
- [ ] Add empty/error/loading states consistency component
- [ ] Tests: unit for service, widget for list/empty state

### Milestone M2: Remind & Track (Sprint 2)
- [ ] Create schedule UI (time(s) per day, days-of-week)
- [ ] Persist schedules to Supabase with RLS
- [ ] Local notifications: schedule/cancel per platform
- [ ] Log taken/skipped; decrement remaining_quantity; refill banner
- [ ] Today screen (logs) with quick actions

### Milestone M3: Refill & History (Sprint 3)
- [ ] Refill alerts (badge + optional notification)
- [ ] History screen (last 30 days) with filters
- [ ] Export CSV (client-side)

### Milestone M4: Polish & Ship (Sprint 4)
- [ ] Dark mode QA, color contrast audit
- [ ] i18n scaffolding, 1-2 locales
- [ ] App icons and splash
- [ ] CI: analyze, test, build

### Clean-up / Tech Debt
- [ ] Remove Drift code or hide behind feature flag
- [ ] Replace secrets in `supabase_config.dart` with env
- [ ] Centralize error handling and toasts/snackbars

### Notes
- Follow `SUPABASE_SETUP.md` to ensure tables and policies exist
- Prefer column constraints and database defaults where possible


