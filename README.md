# Keizoku

An ad-free, privacy-first gym log and strength training companion built with Flutter & Dart for Android, iOS, and Wear OS.

Keizoku operates on a hybrid architecture: 100% offline-first local persistence (atomic JSON and SQLite B-Tree reader) coupled with Firebase online sync (passwordless anonymous login, unique `@handle` registration, secret `GYM-XXXX-XXXX` recovery codes, real-time friend streaks, and community routine sharing). Biometric progress photos and videos remain strictly local on-device.

---

## Features

### Training & Live Sessions
- Interactive anatomical body map (front and back): tap muscle groups to build targeted sessions.
- Real-time logging of reps, weight, RPE (Rate of Perceived Exertion), and RIR (Reps in Reserve).
- Set categories: Warm-up, Working, Drop set, and Failure.
- Superset chaining: link consecutive exercises to automatically skip intermediate rest.
- Barbell plate calculator: calculates exact plates per side based on available kit.
- Persistent live session: survives device reboots and app restarts without losing active progress.
- Ongoing foreground notification with countdown timer and lock-screen controls.
- Algorithmic rest alarm with custom vibration and audio chime profiles.

### Progress & Analytics
- Automated Personal Records (PRs), workout volume, and active streak calculation.
- Strength curves with estimated 1RM progression tracking.
- Muscle radar and visual fatigue distribution heatmaps.
- Private progress photo timeline and 10-point body measurement curves.
- Gamified profile medals, badges, and weekly training targets.
- Sticker generator: export aesthetic workout summaries for sharing.

### Routine Management & Community
- Custom routine builder with multi-day scheduling, superset links, and custom rest times.
- Community Routines Hub: share workouts with 6-character codes (`GYM-XXXX`) and import community routines.
- Passwordless Social Network: connect with friends by `@handle`, view live streaks, and exchange motivation.
- Gym Places: configure equipment inventory and plate pairs for home, commercial, or travel gyms.
- AI Routine Ingestion: build prompts for LLMs (ChatGPT, Claude) and import JSON plans directly.

### Privacy & Data Sovereignty
- 100% passwordless: Anonymous Firebase authentication on startup (no email or password required).
- Secret Recovery Code: 13-character code (`GYM-XXXX-XXXX`) for zero-password account recovery on new devices.
- Local-Only Biometric Invariant: Progress photos, profile avatars, and videos are NEVER uploaded to cloud servers.
- Full offline capability: log workouts anywhere, with or without network access.
- Complete data export/import: Universal CSV, full ZIP backups (including media), and Garmin `.fit` exports for Strava.
- One-tap GDPR account deletion: completely purges handles, friendship links, and remote data from cloud servers.

---

## Platforms

- Android 7.0+ (API 21–36) — Supported
- Wear OS 3+ (Standalone smartwatch logging) — Supported
- iOS 15+ — In progress

---

## Getting Started

### Prerequisites
- Flutter SDK `^3.11.5`
- Dart SDK `^3.11.5`
- Android SDK (API 35+)

### Build from Source

```bash
git clone https://github.com/krreeshhh/Keizoku.git
cd Keizoku
flutter pub get
flutter build apk --release
```

The compiled release APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Testing

Keizoku includes an automated test suite covering unit math, state transitions, backup serialization, and live sessions:

```bash
flutter test
```

---

## Documentation

Exhaustive technical specifications and file-by-file breakdowns are available in the `codebase_docs/` folder:
- [File & Folder Architecture Breakdown](codebase_docs/file_and_folder_breakdown.md)
- [Non-Technical Product & Athlete Guide](codebase_docs/non_technical_summary.md)
- [Technical Architecture Specification](codebase_docs/technical_summary.md)

---

## License

Keizoku is licensed under the GNU General Public License v3.0 (GPLv3). See [LICENSE](LICENSE) and [ADDITIONAL_TERMS.md](ADDITIONAL_TERMS.md) for full terms.
