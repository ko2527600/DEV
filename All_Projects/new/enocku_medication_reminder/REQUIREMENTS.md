## Product Requirements: TAKE MEDICATION

### 1. Goal
- Build a privacy-first, offline-capable medication companion that never lets a dose slip.

### 2. Target Platforms
- Android, iOS primary
- Web and desktop secondary (smoke tests acceptable)

### 3. Users & Personas
- Primary: Individual managing their own medications
- Secondary: Caregiver monitoring a dependent’s regimen (future)

### 4. Core Use Cases (MVP)
- Add a medication with name, dose, unit, form, quantity, refill threshold, instructions
- View list of medications with refill indicators
- Edit medication; soft-delete medication (inactive)
- Authentication (email/password) with Supabase

### 5. Scheduling & Reminders (Post-MVP → 1.0)
- Create schedules per medication: times of day, days of week
- Local notifications on schedule; mark taken/skipped; log entries
- Refill alerts based on remaining quantity vs threshold

### 6. Data Model (current direction)
- Use Supabase tables: `medications`, `medication_schedules`, `medication_logs`
- RLS per-user isolation; user_id references `auth.users`

### 7. Non-Functional Requirements
- Privacy and security: RLS, no secrets in repo, environment config externalized
- Offline tolerance: graceful failure with queued actions (future)
- Accessibility: color contrast, scalable text, clear affordances
- Performance: list screens render < 100ms for 200 items
- Reliability: reminders should trigger within ±1 minute of schedule (platform limits apply)

### 8. Constraints
- Flutter 3.24+, Dart SDK ^3.8.1
- Riverpod for state management; GoRouter for navigation

### 9. Out of Scope (for MVP)
- Caregiver sharing and analytics
- PDF/CSV export
- Background sync beyond local notifications

### 10. Acceptance Criteria (M1)
- A user can sign up, verify email, and sign in
- A signed-in user can add a medication and see it in the list
- Refill badge appears when `remaining_quantity <= refill_threshold`
- Edit and delete (soft) work and reflect in the list


