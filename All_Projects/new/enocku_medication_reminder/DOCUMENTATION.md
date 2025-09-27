# 📱 Enocku Medication Reminder – Mobile App  
Flutter | Android & iOS first, web/desktop later

---

## 1. Vision in one sentence
A privacy-first, offline-capable medication companion that **never lets a dose slip**.

---

## 2. High-level roadmap (MVP → 1.0)

| Phase | Goal | Core user stories | Target |
|-------|------|-------------------|--------|
| **M0** | Skeleton & tooling | Project runs on Android & iOS | ✅ Done |
| **M1** | Add medication | "I can add a med with name, dose, schedule" | Sprint 1 |
| **M2** | Remind & track | Push notification fires → I mark taken/skipped | Sprint 2 |
| **M3** | Refill & history | "Show me last 30 days" + low-stock alert | Sprint 3 |
| **M4** | Polish & ship | Dark mode, i18n, Play Store / TestFlight | Sprint 4 |

---

## 3. Architecture decisions (ADR-lite)

| Topic | Choice | Rationale |
|-------|--------|-----------|
| State mgmt | **Riverpod** (hooks_riverpod) | Compile-safe, dev-tool friendly |
| Local DB | **Drift** (sqlite) | Migrations, type-safe, works offline |
| Schedules | **android_alarm_manager_plus** + **iOS BGTaskScheduler** | Reliable wake-ups |
| Navigation | **GoRouter** | Declarative, deep-link ready |
| Theming | **FlexColorScheme** | 1-line dark/light + accessibility |
| CI | GitHub Actions | `flutter build apk`, `flutter test`, `flutter analyze` |

---

## 4. Folder layout (clean architecture-ish)

```
lib/
├── main.dart               // Bootstrap & env switch
├── src/
│   ├── core/               // Pure utils, constants, extensions
│   ├── features/
│   │   ├── medications/    // Domain layer (entities, repos, use-cases)
│   │   ├── reminders/      // Notifications & scheduling
│   │   └── history/        // Read-only log screen
│   ├── shared/             // Reusable widgets, themes
│   └── app.dart            // ProviderScope + GoRouter
```

---

## 5. Quick start (zero → running)

```bash
# 1. Prerequisites
flutter --version   # 3.24+ recommended
dart --version

# 2. Clone & install
cd Mobile_App/enocku_medication_reminder
flutter pub get

# 3. Code-gen (Drift, Freezed, etc.)
dart run build_runner build --delete-conflicting-outputs

# 4. Run
flutter run              # default device
flutter run -d chrome    # web smoke test
```

---

## 6. Branch & release strategy

| Branch | Purpose | Protection |
|--------|---------|------------|
| `main` | Production releases | CI must pass |
| `develop` | Integration branch | PR reviews |
| `feature/*` | Short-lived | squash-merge |

Release tags: `v0.1.0`, `v0.2.0`, …  
Internal builds: `yyyyMMdd-HHmm` (e.g., `20240612-1430`)

---

## 7. Testing pyramid

| Layer | Tool | Command |
|-------|------|---------|
| Unit | `flutter_test` | `flutter test` |
| Widget | `flutter_test` + `golden_toolkit` | `flutter test --update-goldens` |
| Integration | `flutter_driver` | `flutter drive --target=test_driver/app.dart` |

---

## 8. Secrets & env

Never commit secrets.  
Create `env.json` (git-ignored) and load via `flutter_config`.

Example:

```json
{
  "SENTRY_DSN": "https://...@sentry.io/...",
  "ALARM_API_KEY": "dev-key"
}
```

---

## 9. Contributing checklist

- [ ] `flutter analyze` clean  
- [ ] Tests green (`flutter test`)  
- [ ] Feature branch rebased on `develop`  
- [ ] CHANGELOG.md entry added  
- [ ] Screenshots attached to PR (UI changes)

---

## 10. Useful commands cheat-sheet

```bash
# Generate DB & models
dart run build_runner watch --delete-conflicting-outputs

# Icons & splash
flutter pub run flutter_launcher_icons:main
flutter pub run flutter_native_splash:create

# Build release
flutter build apk --split-per-abi
flutter build ipa --export-method=ad-hoc
```

---

## 11. Docs & links

- [Flutter docs](https://docs.flutter.dev)  
- [Riverpod](https://riverpod.dev)  
- [Drift](https://drift.simonbinder.eu)  
- [GoRouter](https://pub.dev/packages/go_router)  

---

Next step → **M1 branch: `feature/add-medication`**  
Let’s start coding the medication CRUD.
