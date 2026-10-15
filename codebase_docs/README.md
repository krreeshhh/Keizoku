# Keizoku Codebase Documentation Suite

This directory contains the comprehensive, authoritative, up-to-date documentation suite for **Keizoku**, a high-performance, ad-free fitness tracking and gym logging platform engineered with Flutter & Dart for Android, iOS, and Wear OS.

Keizoku operates on a **Privacy-First Hybrid Architecture**: it combines zero-latency, offline-first local persistence (atomic JSON and SQLite B-Tree reader) with modern Cloud Firestore & Firebase Auth capabilities (passwordless anonymous login, unique `@handle` registration, secret `GYM-XXXX-XXXX` recovery codes, real-time friend streaks, and community routine sharing), while enforcing a strict local-only security boundary for sensitive biometric photos and videos.

---

## Documentation Index

| Document | Focus & Target Audience | Description |
| :--- | :--- | :--- |
| **[📁 File & Folder Architecture Breakdown](file_and_folder_breakdown.md)** | **Engineers, Contributors, Code Reviewers** | Exhaustive directory-by-directory and file-by-file audit of the entire repository (2,090+ lines). Covers all root configurations, application shells (`lib/app/`), catalog engine (`lib/catalog/`), l10n architecture (`lib/l10n/`), models (`lib/models/`), all 26 screens (`lib/screens/`), 19 services including Firebase (`lib/services/`), 13 state management files (`lib/state/`), design system (`lib/theme/`), Wear OS smartwatch subsystem (`lib/wear/`), 27 widgets (`lib/widgets/`), all 56+ tests (`test/`), `android/`, and `assets/`. |
| **[🎯 Non-Technical Approach & Product Guide](non_technical_summary.md)** | **Users, Athletes, Product Managers** | Comprehensive non-technical guide explaining Keizoku's mission, meaning of continuity, target athlete personas, end-to-end user journeys (from onboarding & handle selection to live gym logging, rest alarms, and Instagram story sticker generation), the passwordless cloud experience, community routines hub, and data privacy guarantees. |
| **[⚙️ Technical Approach & Architecture Specification](technical_summary.md)** | **Software Architects & Lead Engineers** | In-depth engineering specification detailing the hybrid Flutter + Firebase architecture, Cloud Firestore collections topology (`users`, `handles`, `friend_requests`, `shared_routines`), atomic handle claiming transactions, zero-password recovery algorithm, `FitCore` + 11 domain mixins state engine, pure Dart SQLite B-Tree reader, live workout foreground notifications (Android 16 API 36), algorithmic audio synthesis, Wear OS standalone subsystem, GLSL fragment shaders, and regression test suites. |

---

## System Quick Reference

- **App Name:** Keizoku (継続 — Japanese for continuity/perseverance)
- **Application ID:** `com.keizoku.app` (`keizoku`)
- **Version:** `1.0.0+1`
- **Language / Framework:** Dart `^3.11.5` / Flutter SDK (Material 3)
- **Cloud Backend:** Firebase (Firebase Auth Anonymous, Cloud Firestore with offline cache)
- **Local Storage:** Atomic JSON persistence (`Store.instance`), Media store (`MediaStore`), Pure Dart SQLite B-Tree parser (`sqlite_reader.dart`)
- **Supported Formats:** Keizoku Native JSON, Universal CSV, Garmin FIT binary export, FitNotes SQLite, Strong CSV, Hevy CSV, openGym JSON
- **License:** GNU General Public License v3.0 (GPLv3)
- **Core Design Pillars:** Privacy-first hybrid cloud, zero ads, zero subscriptions, dark/OLED brutalist UI, standalone Wear OS companion.
