# Keizoku Technical Architecture Specification

> **Target Application:** Keizoku  
> **Package Identifier:** `com.keizoku.app` (`keizoku`)  
> **Version:** `1.0.0+1`  
> **Language & Framework:** Dart `^3.11.5` / Flutter SDK (Material 3)  
> **Platforms:** Android (Mobile API 21–36 & Wear OS Standalone), iOS  
> **Cloud Backend:** Firebase (Cloud Firestore & Anonymous Authentication)  
> **Document Status:** Authoritative Engineering Reference  

---

## 1. System Architecture & Tech Stack

### 1.1 Platform & Runtime Environment
Keizoku is engineered as a high-performance, privacy-first, hybrid offline-and-cloud fitness tracking and gym logging platform. It targets standard handheld form factors (Android smartphones and iPhones) as well as wearable hardware (standalone Wear OS smartwatches).

```
+---------------------------------------------------------------------------------------------------+
|                                            Keizoku App                                            |
|                                                                                                   |
|  +-------------------------------------+               +------------------------------------+     |
|  |           Mobile Subsystem          |               |          Wear OS Subsystem         |     |
|  |       (lib/app/keizoku_app.dart)    |               |       (lib/wear/wear_app.dart)     |     |
|  |       (lib/app/app_shell.dart)      |               |       (lib/wear/wear_shell.dart)   |     |
|  +-------------------------------------+               +------------------------------------+     |
|                     |                                                     |                       |
|                     +--------------------------+--------------------------+                       |
|                                                |                                                  |
|                                                v                                                  |
|                                +-------------------------------+                                  |
|                                |       Global State Core       |                                  |
|                                |    (FitState / FitCore mixins)|                                  |
|                                +-------------------------------+                                  |
|                                                |                                                  |
|             +----------------------------------+----------------------------------+               |
|             |                                  |                                  |               |
|             v                                  v                                  v               |
|  +---------------------+           +-----------------------+          +--------------------+      |
|  | Local Persistence   |           | Cloud Backend Layer   |          | Hardware & Native  |      |
|  | - Store (JSON/Prefs)|           | - Firebase Auth (Anon)|          | - Method Channels  |      |
|  | - MediaStore (Files)| <=======> | - Cloud Firestore     |          | - Rotary / Haptics |      |
|  | - SqliteDb (Parser) |           | - Handles & Social    |          | - Screen Wake/Dim  |      |
|  | - BackupZip Archive |           | - Shared Routines     |          | - LiveNotifier API |      |
|  +---------------------+           +-----------------------+          +--------------------+      |
+---------------------------------------------------------------------------------------------------+
```

- **Dart SDK Compatibility:** `^3.11.5` leveraging modern Dart language features: pattern matching with exhaustive `switch` expressions, records `(T1, T2)` and typedef records, extension types, sealed hierarchies, and typed binary buffers.
- **Android Target Environment:**
  - `compileSdk = 36`, `targetSdk = 36`, `minSdk = 21` (runtime targeted to API 24–36).
  - Java 17 toolchain (`JavaVersion.VERSION_17`) with Java 8+ API desugaring (`com.android.tools:desugar_jdk_libs:2.1.5`).
  - Standalone Wear OS manifest flag: `<meta-data android:name="com.google.android.wearable.standalone" android:value="true"/>`.
  - Android 16 (API 36) support featuring `Notification.ProgressStyle` with segmented progress bars and `requestPromotedOngoing` notification flags.
- **iOS Target Environment:** Native Swift and Darwin notification layer supporting `InterruptionLevel.timeSensitive` and Live Activities channel hooks (`keizoku/live_activity`).
- **Hardware Integrations:**
  - Rotary dial input via `MotionEvent.AXIS_SCROLL` dispatched through `MethodChannel("keizoku/rotary")`.
  - Screen wake locks (`FLAG_KEEP_SCREEN_ON`) and low-power ambient dimming (`screenBrightness = 0.02f`) via `MethodChannel("keizoku/screen")`.
  - Custom multi-stage haptic vibration patterns via `MethodChannel("keizoku/haptics")`.
  - System MediaStore image saving via `MethodChannel("keizoku/gallery")`.

### 1.2 Modern Hybrid Architecture: Reactive Local State + Cloud Backend
Keizoku combines an instant-launch, zero-latency local reactive state engine with an asynchronous, event-driven Google Cloud Firebase synchronization layer:
1. **Local-First Core:** Every user action (logging a set, reordering routines, adjusting rest timers) mutates in-memory structures and immediately flushes to disk via debounced local JSON serialization (`Store.instance`). The app executes at 120 FPS without waiting for network confirmations.
2. **Asynchronous Cloud Layer:** A dedicated singleton service (`FirebaseService.instance`) runs concurrently in the background. It interfaces with Firebase Authentication and Cloud Firestore to provide global athlete identity, conflict-free handle claims, bidirectional friend connections, live friend activity streaks, and community routine discovery.
3. **Graceful Offline Degradation:** Firestore offline persistence is explicitly configured with `Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)`. When offline, social queries pull from cached snapshots and local mirrors (`cached_friends`), ensuring zero UI stalls or blocking spinners.

### 1.3 Architectural Paradigm: Zero-Overhead Unidirectional Data Flow
Unlike architectures reliant on heavyweight third-party state managers (`flutter_bloc`, `riverpod`, `mobx`, `get`), Keizoku uses **pure Flutter standard library primitives**:
- **Single Source of Truth (`FitState`):** All persistent data, active workout session objects, catalog metadata, user preferences, and statistical aggregations reside in a unified domain coordinator `FitState` extending `FitCore`.
- **Standard Library Reactive Primitives:**
  - `ChangeNotifier`: Dispatches discrete domain lifecycle updates when entities are modified, added, or deleted.
  - `ValueNotifier<int> clock`: Isolates high-frequency 1-Hz timer ticks to prevent widget tree invalidation.
  - `AnimatedBuilder` / `ListenableBuilder`: Subscribes individual views or localized subtrees to state updates.
- **Decoupled Business Logic:** Domain behaviors are partitioned into fine-grained mixins (`WorkoutState`, `LibraryState`, `MeasuresState`, etc.) sharing access to `FitCore` without cyclical module boundaries or service locators.

---

## 2. Cloud Backend & Firestore Data Topology

### 2.1 Firestore Collections Schema & Data Topology
The Keizoku cloud layer is structured around five top-level and subcollection schemas designed for atomic reservations, fast point lookups, and minimal index overhead.

```
cloud_firestore/
├── handles/ {cleanHandle}                 <-- Unique Handle Registry (Atomic Reservations)
│   ├── uid: String
│   ├── handle: String
│   ├── backupCode: String
│   └── claimedAt: Timestamp
│
├── users/ {uid}                           <-- Online Athlete Profile & Cloud Sync
│   ├── uid: String
│   ├── handle: String
│   ├── displayName: String
│   ├── badge: String ("blue", "gold", etc.)
│   ├── streak: int
│   ├── maxStreak: int
│   ├── weeklyGoal: int
│   ├── workoutsCompleted: int
│   ├── lastWorkoutDate: ISO8601 String?
│   ├── updatedAt: ISO8601 String
│   ├── backupCode: String ("GYM-XXXX-XXXX")
│   ├── sex: String ("male" | "female")
│   ├── age: int
│   ├── heightCm: double
│   ├── weightKg: double
│   ├── units: String ("kg" | "lb")
│   ├── routines: List<Map> [Routine JSON]
│   ├── customExercises: List<Map> [Exercise JSON]
│   ├── weeklyPlan: Map<String, String> [dayIndex -> routineId]
│   ├── lastSync: Timestamp
│   │
│   └── friends/ {friendUid}               <-- Subcollection: Mutual Friends
│       ├── friendUid: String
│       └── addedAt: ISO8601 String
│
├── friend_requests/ {reqId}               <-- Friend Request Pipeline ({fromUid}_{toUid})
│   ├── fromUid: String
│   ├── toUid: String
│   ├── fromHandle: String
│   ├── fromName: String
│   ├── fromBadge: String
│   ├── fromStreak: int
│   ├── status: String ("pending")
│   └── createdAt: ISO8601 String
│
└── shared_routines/ {docId}               <-- Community Routine Sharing Hub
    ├── id: String (Firestore Doc ID)
    ├── code: String ("GYM-XXXX")
    ├── title: String
    ├── description: String
    ├── authorUid: String
    ├── authorName: String
    ├── authorHandle: String
    ├── authorBadge: String
    ├── daysCount: int
    ├── exercisesCount: int
    ├── downloads: int (Atomic FieldValue.increment)
    ├── sharedAt: ISO8601 String
    └── routineData: Map<String, dynamic> [Serialized Routine]
```

### 2.2 Anonymous Authentication Lifecycle
Keizoku delivers zero-friction onboarding by authenticating athletes immediately upon launch without requiring emails, passwords, OAuth redirects, or phone numbers.
- **Initialization Sequence:** `FirebaseService.instance.initialize()` checks `Firebase.apps`. If empty, it initializes the platform-specific options via `DefaultFirebaseOptions.currentPlatform`.
- **Anonymous Sign-In:** 
  ```dart
  if (_auth?.currentUser == null) {
    await _auth?.signInAnonymously();
  }
  ```
  This provisions a unique, persistent Firebase `User.uid`. If network connectivity is unavailable, the service logs a fallback notice, marks `_initialized = false`, and allows the app to function normally in pure offline mode.
- **Persistence Settings:** The Firestore instance is configured with unlimited local caching:
  ```dart
  _firestore?.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  ```

### 2.3 Atomic Handle Claiming Engine
Athletes identify themselves across the community via unique `@handle` strings (e.g., `@iron_beast`, `@krish`). To prevent race conditions, handle hijacking, and split-brain reservations, claiming is executed using Firestore atomic transactions (`runTransaction`):

```dart
Future<bool> claimHandle(String requestedHandle) async {
  if (!_initialized || _firestore == null || currentUid == null) return false;
  final clean = requestedHandle.trim().toLowerCase().replaceAll('@', '').replaceAll(RegExp(r'[^a-z0-9_]'), '');
  if (clean.isEmpty) return false;

  try {
    final success = await _firestore!.runTransaction<bool>((tx) async {
      final handlesCol = _firestore!.collection('handles');
      final targetRef = handlesCol.doc(clean);
      final targetSnap = await tx.get(targetRef);

      if (targetSnap.exists) {
        final owner = targetSnap.data()?['uid'] as String?;
        if (owner != currentUid) {
          // Already taken by another athlete
          return false;
        }
      }

      // Release previous handle if changed
      final userRef = _firestore!.collection('users').doc(currentUid);
      final userSnap = await tx.get(userRef);
      final oldHandle = userSnap.data()?['handle'] as String?;
      if (oldHandle != null && oldHandle.isNotEmpty && oldHandle != clean) {
        tx.delete(handlesCol.doc(oldHandle));
      }

      // Claim target handle reservation
      tx.set(targetRef, {
        'uid': currentUid,
        'handle': clean,
        'backupCode': fit.backupCode,
        'claimedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update user document
      tx.set(userRef, {
        'handle': clean,
        'backupCode': fit.backupCode,
      }, SetOptions(merge: true));

      return true;
    });

    return success;
  } catch (e) {
    debugPrint('Error claiming handle: $e');
    return false;
  }
}
```

#### Launch Conflict Resolution (`_checkHandleConflictOnLaunch`)
When an athlete launches Keizoku, `AppShell.initState()` triggers a post-frame callback to verify ownership of the active handle via `_checkHandleConflictOnLaunch()`.
- If another athlete has restored or claimed that handle (e.g., after a multi-device account migration), `isCurrentHandleClaimedByOther()` returns `true`.
- The app immediately presents a non-dismissible modal `showHandlePromptDialog()` prompting the user to select a new unique handle before resuming interaction, completely eliminating ghost handles.

### 2.4 Zero-Password Account Recovery Algorithm
Traditional fitness applications mandate email verification or social logins to support cross-device restoration. Keizoku resolves this via an automated, zero-password cryptographic secret: the **Backup Code**.

#### Backup Code Generation Specification
- Generated automatically on first launch or account reset in `SettingsState.generateBackupCode()`.
- Format: `GYM-XXXX-XXXX` (13 characters).
- Alphabet: Unambiguous Base-32 alphanumeric charset (`ABCDEFGHJKLMNPQRSTUVWXYZ23456789`), excluding visually confusing characters (`0`, `O`, `1`, `I`).
- Entropy: $32^8 \approx 1.099 \times 10^{12}$ distinct combinations, preventing brute-force enumeration.

#### Restoration State Machine (`restoreAccountWithBackupCode`)
When an athlete enters their handle and backup code in the Restore Account bottom sheet or Onboarding flow:

```
[Athlete Input: Handle & Backup Code]
               |
               v
[Input Sanitization: Trim, Lowercase Handle, Normalize Hyphens]
               |
               v
[Firestore Query: Point-lookup handles/{cleanHandle}]
   |                                 |
   | Not Found                       | Found
   v                                 v
[Fallback Query: users where handle]  [Extract stored UID & backupCode]
   |                                 |
   +----------------+----------------+
                    |
                    v
[Validate Backup Code: normInput == normStored]
   |
   |-- Mismatch --> Abort with Error
   |
   v
[Step 1: Hydrate Local Profile & Biometrics]
  (displayName, badge, weeklyGoal, sex, age, heightCm, weightKg, units, backupCode)
   |
   v
[Step 2: Merge Routines & Custom Exercises]
  (Deduplicate via Routine.id & Exercise.id to protect existing local items)
   |
   v
[Step 3: Restore Weekly Split Plan]
   |
   v
[Step 4: Social Graph Migration & Ownership Transfer]
  if (currentUid != targetUid) {
     - Batch copy all docs from users/{targetUid}/friends to users/{currentUid}/friends
     - Mutate all mutual friends: point their reverse relationship to currentUid
     - Transfer handles/{cleanHandle} reservation doc to currentUid
  }
   |
   v
[Step 5: Persist Local State & Trigger Background syncUserProfile()]
```

### 2.5 Privacy & Security Boundary
Keizoku enforces an inviolable separation between public social metadata and private biometric media:
1. **Cloud-Isolated Data:**
   - **Progress Photos:** Biometric physique photos taken in `TimelineScreen` are written directly to `<ApplicationDocumentsDirectory>/exercise_media/` via `MediaStore`. They are **never** uploaded to Firestore or Firebase Storage.
   - **Profile Picture & Custom Banners:** Local avatars (`fit.profilePhoto`, `fit.profileBanner`) remain stored on-device in `SharedPreferences` or local storage as Base64/file buffers. They are omitted from `UserProfileOnline.toMap()` and `syncUserProfile()`.
   - **Workout Media:** Exercise demo clips and execution attachments stay strictly local.
2. **Cloud-Synced Data:** Only sanitized text metadata is transmitted: display name, handle, active streak count, routine structures (exercise IDs, sets, target reps, rest timers), custom exercise names/categories, and mutual friendship graph pointers.

### 2.6 GDPR Account Wiping & Self-Sovereignty (`deleteAccountAndAllData`)
In compliance with global data privacy standards (GDPR, CCPA), Keizoku provides complete, irreversible cloud self-erasure. Executing "Delete Account" in Settings runs a comprehensive Firestore batch deletion:
1. Deletes the handle claim document in `handles/{cleanHandle}`.
2. Deletes the user profile document in `users/{uid}`.
3. Queries and deletes all mutual friendship documents in `users/{uid}/friends/*` and the reverse friend documents in `users/{friendUid}/friends/{uid}`.
4. Deletes all outgoing and incoming friend requests in `friend_requests` where `fromUid == uid` or `toUid == uid`.
5. Deletes all community routines published by this athlete in `shared_routines` where `authorUid == uid`.
6. Invokes `FirebaseAuth.instance.currentUser?.delete()`. If the credential token is stale, it falls back to `signOut()`.
7. Signs in anonymously with a fresh, clean UID and generates a new local backup code.

---

## 3. Custom State Management & Domain Architecture

### 3.1 Controller Hierarchy: `FitCore` and `FitState`
The application state is organized as a single global singleton `fit` backed by a modular mixin pipeline.

```
                            +--------------------+
                            |   ChangeNotifier   |
                            +--------------------+
                                      |
                                      v
                            +--------------------+
                            |      FitCore       |
                            +--------------------+
                                      |
         +----------------------------+----------------------------+
         |                            |                            |
  (State Mixins)                      |                            |
  - ToolsState                        |                            |
  - LibraryState                      |                            |
  - SettingsState                     |                            |
  - NotesState                        |                            |
  - PlacesState                       |                            |
  - MeasuresState                     |                            |
  - MomentsState                      |                            |
  - TimelineState                     |                            |
  - StatsState                        |                            |
  - RoutinesState                     |                            |
  - WorkoutState                      |                            |
         |                            |                            |
         +----------------------------+----------------------------+
                                      |
                                      v
                            +--------------------+
                            |      FitState      |
                            +--------------------+
                                      |
                               (Global Instance)
                                  final fit
```

#### `FitCore` (`lib/state/fit_core.dart`)
`FitCore` establishes base storage fields, routing stacks, unit conversions, and the persistence contract:
- **Internal Route Stack:** Manages navigation via `String route` and `List<String> _routeStack`. Core bottom-bar routes (`home`, `progress`, `exercises`, `settings`) maintain a zero depth, whereas sub-screens (`train`, `session`, `timeline`, `measures`, `note-edit`, `ai-plan`) push and pop with history tracking.
- **Unit Conversions:** Centralized imperial/metric mathematics:
  - Weight factor: $1\text{ kg} = 2.20462\text{ lb}$ (`toDisplayWeight`, `fromDisplayWeight`, `weightLabel`, `weightStep`).
  - Distance factor: $1\text{ mi} = 1.609344\text{ km}$ (`toDisplayKm`, `fromDisplayKm`, `distanceLabel`, `distanceStep`).
- **Debounced Persistence Engine:**
  ```dart
  void _persist() {
    if (_loading) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), persistNow);
  }
  ```
  Mutations schedule a 400ms debounced disk flush via `persistNow()`, coalescing rapid UI events (e.g., ticking sets, dragging sliders) into single atomic I/O writes.

#### `FitState` (`lib/state/fit_state.dart`)
`FitState` composes eleven modular domain controllers using Dart mixin application:
```dart
class FitState extends FitCore
    with ToolsState, LibraryState, SettingsState, NotesState, PlacesState,
         MeasuresState, MomentsState, TimelineState, StatsState,
         RoutinesState, WorkoutState { ... }
```
It handles bootstrap hydration (`loadFromStore`), schema migration, JSON serialization (`toJson`), reset sequences (`resetAllData`), and system-level brightness transitions.

### 3.2 Decomposition of Modular Domain Controllers

| Mixin | Source File | Core Responsibilities & Controlled State |
| :--- | :--- | :--- |
| **`WorkoutState`** | `lib/state/workout_state.dart` | Active `WorkoutSession? session`, muscle selection (`selectedMuscles`), exercise picks, rest timers, live session pause/resume, lock guard, and the 1-Hz `clock` notifier. |
| **`LibraryState`** | `lib/state/library_state.dart` | Built-in catalog lookups, custom exercises (`customExercises`), exercise aliases, favorites, exercise media attachments (`exerciseMedia`), bar weights, and video bookmarks. |
| **`MeasuresState`** | `lib/state/measures_state.dart` | Body metric tracking (`List<BodyMeasure> measures`) across 11 key zones, bodyweight log (`List<BodyweightEntry> bodyweight`), imperial conversions, and delta analysis. |
| **`NotesState`** | `lib/state/notes_state.dart` | Rich gym notes (`List<GymNote> notes`), general vs exercise-specific notes, categorization (`note`, `plan`, `done`, `pain`), and image attachments. |
| **`PlacesState`** | `lib/state/places_state.dart` | Multi-gym profile management (`List<GymPlace> places`), equipment availability filters, location plate inventories (`plates`), and place-specific barbell tare weights. |
| **`MomentsState`** | `lib/state/moments_state.dart` | Achievement check-in photos (`List<Moment> moments`), streak records, celebration cards, and social sharing payloads. |
| **`StatsState`** | `lib/state/stats_state.dart` | 84-day rolling heatmap (`kHeatmapDays = 84`, 4 heat tiers), muscle group recovery indexes (0.0 to 1.0), cumulative tonnage, set counts, and personal record (PR) calculations. |
| **`SettingsState`** | `lib/state/settings_state.dart` | Visual theme (`dark`, `oled`, `light`, `system`), Material You dynamic color switch (`materialYou`), custom alarm sounds, screen wake locks, and secret backup codes. |
| **`TimelineState`** | `lib/state/timeline_state.dart` | Photographic progress tracking (`List<ProgressEntry> shots`), pose mapping (`front`, `side`, `back`), comparison sliders, and reminder schedules (`photoIntervalDays`). |
| **`ToolsState`** | `lib/state/tools_state.dart` | Biometric and athletic calculators: 1RM equations, Mifflin-St Jeor caloric expenditure, US Navy body fat %, plate loading visualizer, and warmup ladder generator. |
| **`RoutinesState`** | `lib/state/routines_state.dart` | Multi-week routine templates (`List<Routine> routines`), daily workout splits (`weeklyPlan`), and program share links. |

### 3.3 Minimizing Repaint Churn & GPU Invalidation
Keizoku delivers smooth 120 FPS rendering on mobile and sub-watt efficiency on Wear OS by applying strict rendering isolation techniques:
1. **High-Frequency Timer Isolation:**
   During a live session, the workout timer runs continuously. Calling `notifyListeners()` on `FitState` every second would trigger an expensive reconciliation and repaint of the entire widget hierarchy. Instead, `WorkoutState` uses a detached `ValueNotifier<int> clock`:
   ```dart
   _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) => clock.value++);
   ```
   Only lightweight consumer widgets (e.g., `StopwatchCard`, `TimerPanel`, or `WearClock`) listen to `clock`, while the remaining UI remains completely idle.
2. **Granular `RepaintBoundary` Wrapping:**
   `RepaintBoundary` widgets are placed at high-complexity boundaries:
   - Vector canvas layers: `BodyPainter` and `MuscleFigurePainter`.
   - Backdrop glassmorphism filters: `GlassSurface` and `EdgeBlur`.
   - Dynamic page routes: `_animatedScreen()` in `AppShell`.
   - Navigation pills: `_LiquidPill` and `_ParkedPill`.
3. **Tupled Theme & Locale Subscriptions:**
   `KeizokuApp` listens to `fit` changes but filters rebuilds through a tuple equality check:
   ```dart
   final look = (fit.themePref, fit.themeMode, fit.oled, fit.locale, fit.materialYou);
   if (look != _look) setState(() => _look = look);
   ```
   Data mutations elsewhere in `fit` (such as logging a set or saving a note) bypass `MaterialApp` rebuilds entirely.
4. **Scroll Notification Decoupling:**
   Top-edge app bar blurring (`EdgeBlur`) reacts to `ScrollNotification` metrics above a 6px threshold without triggering parent page layout passes.

---

## 4. Storage & Persistence Subsystem

### 4.1 Storage Architecture
Keizoku implements a multi-tier local storage subsystem:
1. **Primary State Document (`Store` via `lib/services/local_store.dart`):** Serializes the entire application state tree into a single atomic JSON document persisted in `SharedPreferences` under the key `'keizoku_v1'`. It includes a sanitizing transformer `Store.finite(data)` that guards against `double.nan` and `double.infinity`.
2. **Media Storage System (`MediaStore` via `lib/services/media_store.dart`):** Stores raw user photos, workout moment snapshots, and video bookmarks under `<ApplicationDocumentsDirectory>/exercise_media/`. Generates unique timestamped IDs: `'$exerciseId-${microseconds}-${_seq++}.$ext'`.
3. **Alarm Sound Vault (`AlarmStore` via `lib/services/alarm_store.dart`):** Manages custom user-imported ringtones and alarm audio files in `<ApplicationDocumentsDirectory>/custom_alarms/`.

```
+---------------------------------------------------------------------------------------------------+
|                                     Application Storage Layer                                     |
|                                                                                                   |
|  +--------------------------+   +-------------------+   +-------------------+   +---------------+ |
|  |    SharedPreferences     |   |   exercise_media/ |   |   custom_alarms/  |   | Cloud Storage | |
|  |     'keizoku_v1' JSON    |   |  (Progress & Vids)|   |   (Alarm Audio)   |   |   Firestore   | |
|  +--------------------------+   +-------------------+   +-------------------+   +---------------+ |
|               ^                           ^                       ^                     ^         |
|               |                           |                       |                     |         |
|  +----------------------------------------------------------------------------------------------+ |
|  |                             Backup & Import/Export Pipeline                                  | |
|  |                                                                                              | |
|  |  +-------------------+  +-------------------+  +-----------------------+  +----------------+ | |
|  |  |  ZipEncoder/Dec   |  |   Garmin .FIT     |  | Pure Dart SqliteDb    |  | Third-Party CSV| | |
|  |  |  (backup_zip.dart)|  | (fit_export.dart) |  | (sqlite_reader.dart)  |  | (Hevy, Strong) | | |
|  |  +-------------------+  +-------------------+  +-----------------------+  +----------------+ | |
|  +----------------------------------------------------------------------------------------------+ |
+---------------------------------------------------------------------------------------------------+
```

### 4.2 Pure Dart SQLite B-Tree Parser (`sqlite_reader.dart`)
A notable architectural feature is `SqliteDb`: a **zero-dependency, native Dart binary SQLite format 3 reader**. It does not use native SQLite C libraries or the `sqflite` Flutter plugin. Instead, it directly parses binary SQLite files:
- **Magic Signature:** Validates header bytes against `SQLite format 3\x00`.
- **Page Header & Cell Pointers:** Reads 100-byte database headers, page sizes (typically 4096 bytes), reserved spaces, cell counts, and b-tree interior/leaf layouts.
- **Variable-Length Integers (Varints):** Implements Huffman-style 1-to-9 byte integer decoding:
  ```dart
  static _Varint _varint(Uint8List b, int at) {
    var v = 0;
    for (var i = 0; i < 8; i++) {
      final byte = b[at + i];
      v = (v << 7) | (byte & 0x7F);
      if ((byte & 0x80) == 0) return _Varint(v, i + 1);
    }
    return _Varint((v << 8) | b[at + 8], 9);
  }
  ```
- **Record Serialization:** Decodes serial type codes ($0 \dots 9$, strings, and blobs) to parse SQLite schema b-trees (`sqlite_master`) and dynamic data tables.

This engine allows instant, crash-proof importation of **FitNotes backups** (`.fitnotes`) directly on Android, iOS, or desktop without database drivers.

### 4.3 Backup, Restoration, & Export Engines
1. **Full Archive Backup (`backup_zip.dart`):** Compresses the complete application state and all associated media into a portable `.zip` archive:
   - Root configuration: `keizoku.json`.
   - Media subdirectories: `media/images/`, `media/videos/`, `media/notes/`, `timeline/`, `moments/`, `alarm/`.
   - Slugification: Transliterates accented Unicode characters into ASCII-safe slugs via `slugify()`.
2. **Garmin FIT Binary Generator (`fit_export.dart`):** Emits compliant binary `.FIT` workout files for Garmin Connect, Strava, and training suites:
   - Sets FIT Epoch baseline: `631065600` (Dec 31, 1989, 00:00:00 UTC).
   - Maps Keizoku exercise types to official Garmin category enumerations (bench press, squat, deadlift, row, curl, etc.).
   - Computes standard 16-bit CRC check values via CRC polynomial lookup `_crcTable`.
3. **Multi-Platform Workout Importer (`workout_import.dart`):** Auto-detects and ingests CSV/JSON workout exports from:
   - `Hevy`, `Strong`, `Lyfta`, `Fitbod`, `FitNotes`, `OpenGym`, and generic CSV formats.

### 4.4 Storage Key Compression Strategy
To minimize memory overhead and JSON serialization cost in SharedPreferences, SQLite, and network payloads, domain keys are aggressively aliased:

```dart
// LoggedSet.toJson()
Map<String, dynamic> toJson() => {
  'r': reps,
  'w': weight,
  if (kind != SetKind.normal) 'k': kind.index,
  if (rpe != null) 'e': rpe,
  if (sec != null) 't': sec,
  if (km != null) 'km': km,
};

// LoggedExercise.toJson()
Map<String, dynamic> toJson() => {
  'id': id,
  'n': name,
  'p': primary,
  's': sets.map((s) => s.toJson()).toList(),
};

// LoggedSession.toJson()
Map<String, dynamic> toJson() => {
  'd': date.toIso8601String(),
  'dur': durationSec,
  'ex': exercises.map((e) => e.toJson()).toList(),
};
```

---

## 5. Background Execution, Wear OS, & Sensory Subsystem

### 5.1 Real-Time Session Lifecycle & State Machine
A live session transitions through deterministic lifecycle phases:

```
[Start Workout / Routine]
          |
          v
+-------------------+      Pause
|   Active Session  | --------------> +-------------------+
|  (Timer Ticking)  | <-------------- |   Paused Session  |
+-------------------+      Resume     |  (Frozen Clocks)  |
   |             ^                    +-------------------+
   | Complete    | Add Rest (+15s)              |
   | Set         | Skip Rest                    |
   v             |                              | Discard
+-------------------+                           v
|   Rest Countdown  |                   [Session Aborted]
|  (Alarm Scheduled)|
+-------------------+
          |
          | Finish All Exercises
          v
+-------------------+
| Summary & Review  |
+-------------------+
          | Save
          v
[LoggedSession Persisted to Store]
```

- When sets are completed, `WorkoutState` schedules a rest window (`restEndsAt = DateTime.now().add(Duration(seconds: restSeconds))`).
- If paused, `_elapsedBefore` records elapsed workout time while `_sessionTimer` is paused.
- When backgrounded, `didChangeAppLifecycleState` invokes `fit.persistNow()`, snapshotting in-progress state to disk. If the app is killed by the OS low-memory killer (LMK), `_restoreLiveSession` automatically recovers the active workout on next launch.

### 5.2 Foreground Service & Android System Notifications
Keizoku integrates with Android system notification architecture via `MainActivity.kt`, `LiveNotifier.kt`, and `LiveActionReceiver.kt`:
1. **Android 16 (API 36) Promoted Ongoing Support:**
   When running on Android 16+, Keizoku configures enhanced ongoing notifications:
   ```kotlin
   val style = Notification.ProgressStyle()
       .setStyledByProgress(true)
       .setProgressTrackerIcon(Icon.createWithResource(ctx, R.drawable.ic_live_tracker))

   style.setProgressSegments(segs.map {
       Notification.ProgressStyle.Segment(it.value).setColor(if (finished) green else accent)
   })
   b.setStyle(style)
   b.extras.putBoolean("android.requestPromotedOngoing", true)
   b.setShortCriticalText(shortText)
   ```
2. **Legacy Android Notifications (API < 36):**
   Utilizes custom `RemoteViews` (`R.layout.live_small`, `R.layout.live_big`) styled via `Notification.DecoratedCustomViewStyle()`.
3. **Interactive Lock-Screen Broadcast Actions:**
   Notification action buttons (`+15 s`, `Skip Rest`, `✓ Done Set`, `❚❚ Pause`, `▶ Resume`) dispatch pending intents to `LiveActionReceiver`, which routes the events through `LiveNotifier.dart.invokeMethod("action", id)` back into `LiveWorkout._act(id)` in Flutter.

### 5.3 Wear OS Standalone Subsystem (`wear_app.dart`, `wear_shell.dart`)
Keizoku runs as a standalone Wear OS experience without requiring a companion phone connection:

```
+-----------------------------------------------------------------------------------+
|                              Wear OS Architecture                                 |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  |                             WearShell Host                                  |  |
|  |                                                                             |  |
|  |  +------------------------+   +-------------------+   +------------------+  |  |
|  |  |       WearHome         |   |    WearSession    |   |     WearDim      |  |  |
|  |  | - Circular Week Ring   |   | - Large Tap Target|   | - Low-Power OLED |  |  |
|  |  | - Routine Quick-Launch |   | - Rest Countdown  |   | - Pure Black     |  |  |
|  |  | - Volume Metrics       |   | - Weight Steppers |   | - 15s Auto-Dim   |  |  |
|  |  +------------------------+   +-------------------+   +------------------+  |  |
|  +-----------------------------------------------------------------------------+  |
|                                         |                                         |
|                                         v                                         |
|  +-----------------------------------------------------------------------------+  |
|  |                           WearRotary Hardware Driver                        |  |
|  |       MethodChannel('keizoku/rotary') -> List<ScrollController> Stack       |  |
|  +-----------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------+
```

- **Hardware Rotary Dial Handling (`WearRotary`):**
  Navigating lists on small smartwatch displays via finger dragging can obscure screen content. Keizoku maps physical rotating bezels and digital crowns directly to active scroll views:
  1. `MainActivity.kt` overrides `dispatchGenericMotionEvent`:
     ```kotlin
     val axis = event.getAxisValue(MotionEvent.AXIS_SCROLL)
     val factor = ViewConfiguration.get(this).scaledVerticalScrollFactor
     rotaryChannel?.invokeMethod("scroll", -axis * factor)
     ```
  2. `WearRotary` maintains an internal controller stack (`List<ScrollController> _stack`). Active screens attach during mount and detach during disposal.
  3. Turning the physical dial adjusts the active scroll position smoothly (`jumpTo((p.pixels + delta).clamp(...))`) and resets display sleep timers.
- **15-Second Idle Watchdog & Low-Power Ambient Mode:**
  If an active workout session is running with screen wake lock enabled, `_WearShellState` triggers an idle timer:
  ```dart
  _idle = Timer(const Duration(seconds: 15), () {
    if (mounted && _canDim) _setDim(true);
  });
  ```
  When `_dim = true`, `ScreenAwake.dim(true)` drops display panel brightness to `0.02f` on Android, and the UI replaces the standard session with `WearDim`: a stark, monochromatic, high-contrast clock face displaying only current exercise, set progress, rest countdown, and time.
- **Radial Geometry Optimization:** Large touch targets (`WearButton`, `WearIconButton`) provide a minimum 48dp tapping area to ensure error-free set logging during intense exercise.

### 5.4 Rest Alarms & Algorithmic Audio Synthesis
Rest timing utilizes a dual notification and audio architecture:
- **Exact Alarms (`rest_alarm.dart`):** Enqueues notifications via `flutter_local_notifications` with `AndroidScheduleMode.exactAllowWhileIdle` using `SCHEDULE_EXACT_ALARM` permissions to ensure reliable triggering during Android Doze mode.
- **Notification Channels:** Supports three distinct modes:
  - `rest_timer` (Loud): `AndroidNotificationCategory.alarm`, `AudioAttributesUsage.alarm`, `fullScreenIntent = true`.
  - `rest_timer_quiet`: Category reminder, standard notification sound.
  - `rest_timer_vibrate`: Soundless channel using a multi-pulse haptic pattern: `[0, 350, 180, 350, 180, 600]`.
- **Runtime Algorithmic Audio Synthesizer (`beeper.dart`):**
  Rather than relying solely on bundled audio files, `Beeper` synthesizes 16-bit 44.1 kHz PCM `.WAV` audio in-memory:
  - `chimeWav()`: Generates a harmonic two-tone chime ($1046.5\text{ Hz}$ [C6] and $1568.0\text{ Hz}$ [G6]) with an attack envelope ($a^2 \cdot (3 - 2a)$) and second/third harmonic overtones.
  - `_tone(hz, secs)`: Generates custom sine waves with fundamental and harmonic envelopes directly into `ByteData` buffers, providing zero-latency auditory feedback for countdown timers.

---

## 6. Custom Rendering, Shaders, & Canvas Components

### 6.1 Anatomical Muscle Mapping & Hit-Testing (`body_svg.dart`, `body_map.dart`)
Keizoku features an interactive vector-based anatomical muscle map:
- **Coordinate Space:** Rendered across a fixed `535 x 462` viewBox (`bodyViewW`, `bodyViewH`).
- **Anterior & Posterior Projections:** Composed of base skin paths (`bodyBaseMain`, `bodyBaseLite`) overlaid with muscle bezier paths (`muscleFills`) representing 13 muscle zones.
- **Coordinate Hit-Testing:**
  ```dart
  String? muscleAt(Offset p) {
    for (final id in muscleFills.keys) {
      final hits = muscleHits[id];
      final probes = (hits != null && hits.isNotEmpty) ? hits : muscleFills[id]!;
      for (final d in probes) {
        if (svgPath(d).contains(p)) return id;
      }
    }
    return null;
  }
  ```
  Tap coordinates are transformed into the SVG viewBox, and `Path.contains(point)` evaluates ray-casting point-in-polygon containment against simplified hit paths (`muscleHits`).

```
+-----------------------------------------------------------------------------------+
|                        535 x 462 Anatomical Canvas                                |
|                                                                                   |
|      [Anterior View (Front)]                     [Posterior View (Back)]          |
|      X: 0 -> 262                                 X: 270 -> 535                    |
|                                                                                   |
|           ( ) Head                                    ( ) Head                    |
|          / | \ Traps / Shoulders                     / | \ Trapezius              |
|         /  |  \ Chest                               /  |  \ Upper Back / Lats     |
|        |   |   | Biceps / Core                     |   |   | Triceps              |
|        |   |   | Forearms                          |   |   | Lower Back           |
|         \ / \ /  Quads                              \ / \ /  Glutes / Hamstrings  |
|          |   |   Calves                              |   |   Calves               |
|                                                                                   |
|  * User Tap Event -> Local Offset transformed to 535x462 coordinates             |
|  * Evaluated across muscleHits paths using svgPath(d).contains(p)                 |
|  * Triggers instant toggleMuscle(id) state mutation                               |
+-----------------------------------------------------------------------------------+
```

### 6.2 Dynamic Radar Charting (`muscle_radar.dart`)
The muscle balance radar visualizes training volume across 12 axes (`chest`, `shoulders`, `trapezius`, `back`, `triceps`, `biceps`, `forearm`, `abdomen`, `quads`, `calves`, `hamstrings`, `glutes`):
- **Concentric Grid:** Computes polar coordinate vertices at $\theta = -\frac{\pi}{2} + i \cdot \frac{2\pi}{N}$ and draws isometric polygon rings at 25%, 50%, 75%, and 100% radii.
- **Data Polygon:** Maps set counts into normalized vectors ($[0.0, 1.0]$), drawing dynamic filled polygons with accent strokes and interactive vertex node circles.
- **Micro-Figure Previews:** `MuscleFigurePainter` uses `PathMetric.getTangentForOffset()` to determine bounding boxes around specific muscle paths, clipping and rendering miniature vector body representations around radar vertices.

### 6.3 Fragment Shaders (`assets/shaders/edge_fade.frag`)
Keizoku compiles custom GLSL fragment shaders with support for the Flutter Impeller rendering backend:
```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uReach;
uniform float uFrom;
uniform float uTo;
uniform float uTop;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 uv = p / uSize;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  float d = uTop > 0.5 ? p.y : uSize.y - p.y;
  float k = clamp(d / max(uReach, 1.0), 0.0, 1.0);
  float a = 1.0 - smoothstep(uFrom, uTo, k);
  vec4 c = texture(uTexture, uv);
  if (c.a > 0.004) c /= c.a;
  fragColor = c * a;
}
```
This shader applies an anti-aliased non-linear alpha attenuation curve (`smoothstep`) across list boundaries, preventing hard visual cut-offs under system status bars.

### 6.4 Liquid Notch Physics (`liquid_notch.dart`)
The `LiquidNotch` component creates a fluid, drop-style toast notification originating from the hardware camera cutout:
- **Metaball Interpolation (`LiquidNotchFrame`):** Uses an empirical 13-stage keyframe table (`_enter`, `_exit`) defining notch width, height, y-position, neck radius, shoulder radius, and opacity.
- **Geometric Bridge Blending:** `_LiquidPainter` constructs a cubic bezier bridge connecting the camera cutout rectangle with the expanding toast pill, blending them into a single continuous path using `PathOperation.union`.

### 6.5 Theme Engine & Expressive Typography (`app_theme.dart`)
Keizoku's typographic layout uses strict proportional calibrations:
- **Display & Body Font:** `DarkerGrotesque` applied with a global `fontScale = 1.18`.
- **Monospace Font:** `SpaceMono` applied with a global `monoScale = 1.08`.
- **Theme Modes:**
  - `dark`: High-contrast dark gray palette (`bg = #0C0B0A`, `bgRaised = #181614`).
  - `oled`: Pure black palette (`bg = #000000`, `bgRaised = #121212`) designed for zero-power OLED display pixels.
  - `light`: Warm paper-like canvas (`bg = #F5F3EF`, `bgRaised = #FFFFFF`).
  - `Material You`: Dynamic tonal palettes extracted from system wallpaper colors using `dynamic_color`.

---

## 7. Testing Architecture & Quality Assurance

Keizoku maintains **68 automated test suites** in `test/`, with zero reliance on external mocking frameworks (no `mockito`, no `mocktail`). Business logic, data models, calculations, backup restoration, and rendering pipelines are verified against live, in-memory state engines.

```
test/
├── Cloud & Identity / Backup Tests (4 suites)
│   ├── backup_code_test.dart       # GYM-XXXX-XXXX format, persistence, & reload validation
│   ├── backup_complete_test.dart   # Multi-year 104-week full data roundtrip & media verification
│   ├── backup_zip_test.dart        # Full ZIP archive generation & restore verification
│   └── plan_share_test.dart        # Shared routine plan URL codecs & routine payloads
│
├── Data & State Invariants (16 suites)
│   ├── persistence_test.dart       # JSON roundtrip & data integrity
│   ├── session_test.dart           # Workout session creation & completion
│   ├── live_session_test.dart      # Live active session state transitions
│   ├── live_update_test.dart       # Real-time state updates
│   ├── continue_session_test.dart  # Session resumption & recovery
│   ├── editing_test.dart           # Workout record modification
│   ├── logged_edit_test.dart       # Historic workout modifications
│   ├── measures_test.dart          # Body measurement entries & units
│   ├── places_test.dart            # Gym location CRUD & filtering
│   ├── profile_test.dart           # Athlete profiles & defaults
│   ├── timeline_test.dart          # Photo timeline sequences
│   ├── timeline_body_test.dart     # Body timeline mode switching
│   ├── note_calendar_test.dart     # Date-associated note indexing
│   ├── exercise_notes_test.dart    # Exercise-specific note associations
│   ├── checkin_test.dart           # Daily gym check-in records
│   └── route_stack_test.dart       # Navigation stack push/pop invariants
│
├── Exercise Catalog & Routines (11 suites)
│   ├── catalog_test.dart           # Built-in exercise library consistency
│   ├── exercise_alias_test.dart    # Exercise alias lookups
│   ├── exercise_kind_test.dart     # Category mapping (cardio/strength)
│   ├── merged_ids_test.dart        # Deprecated exercise ID migration
│   ├── custom_exercise_extras_test.dart # User custom exercise flags
│   ├── swap_exercise_test.dart     # In-session exercise substitution
│   ├── recommended_routine_test.dart # Default routine recommendations
│   ├── reps_only_test.dart         # Calisthenics reps-only tracking
│   ├── level_up_test.dart          # Gamification level progression
│   ├── routine_rest_test.dart      # Rest timer overrides per routine
│   └── routine_session_edit_test.dart # Editing active routine sessions
│
├── Math, Science, & Calculators (8 suites)
│   ├── calculators_test.dart       # Epley 1RM, Mifflin-St Jeor, BMI, US Navy BF
│   ├── rpe_test.dart               # Borg RPE / RIR percentage tables
│   ├── set_kinds_test.dart         # Volume logic: Warmup, Drop, Failure
│   ├── units_test.dart             # Metric/Imperial conversion precision
│   ├── new_tools_test.dart         # Plate calculator & warmup ladder
│   ├── progress_strength_test.dart # Strength progression curves
│   ├── progress_order_test.dart    # Sorting and chronological ordering
│   └── stats_realdata_test.dart    # Tonnage & volume metrics
│
├── Storage, Interoperability, & Export (6 suites)
│   ├── export_test.dart            # CSV data exporter verification
│   ├── fit_export_test.dart        # Garmin binary FIT format & CRC validation
│   ├── fitnotes_backup_test.dart   # SQLite B-tree parsing & restoration
│   ├── import_test.dart            # CSV parser autodetection
│   ├── import_real_files_test.dart # Fixture testing: Hevy, Strong, Lyfta
│   └── save_guard_test.dart        # Guarding against data loss on exit
│
├── Rendering, Canvas, & Theming (6 suites)
│   ├── body_hit_test.dart          # 5px grid point-in-path vector scan
│   ├── muscle_map_test.dart        # Heatmap color interpolation
│   ├── theme_scaling_test.dart     # 1.18 fontScale & 1.08 monoScale
│   ├── shell_repaint_test.dart     # Zero-churn RepaintBoundary audit
│   ├── shell_transition_test.dart  # Route transition slide animations
│   └── scroll_keep_test.dart       # Scroll position preservation
│
├── Hardware, Alarms, & Wear OS (6 suites)
│   ├── alarm_sound_test.dart       # Alarm audio playback configuration
│   ├── rest_alarm_test.dart        # Rest timer notification scheduling
│   ├── wear_test.dart              # Wear OS app shell & rotary handling
│   ├── home_widgets_test.dart      # Android AppWidget synchronization
│   ├── session_lock_test.dart      # Accidental-touch lock screen guard
│   └── profile_photo_test.dart     # Avatar image handling
│
└── Regressions, User Scenarios, & I18n (11 suites)
    ├── reddit_requests_test.dart   # Real-world community feature requests
    ├── requests_18sep_test.dart    # Sprint regression test suite 1
    ├── requests_19sep_test.dart    # Sprint regression test suite 2
    ├── requests_27sep_test.dart    # Sprint regression test suite 3
    ├── requests_29sep_test.dart    # Sprint regression test suite 4
    ├── flow_test.dart              # End-to-end workout logging workflow
    ├── smoke_test.dart             # Application initialization smoke test
    ├── audit_test.dart             # Catalog and database sanity audit
    ├── polish_test.dart            # Edge-case UI polish verification
    ├── train_step2_test.dart       # Workout selection flow step 2
    └── i18n_test.dart              # Multi-locale translation coverage
```

### 7.1 Spotlight Test Suites: Backup Code & Complete Recovery
- **`backup_code_test.dart`:**
  - Verifies automatic generation of the 13-character `GYM-XXXX-XXXX` token conforming to the regular expression `^GYM-[A-Z0-9]{4}-[A-Z0-9]{4}$`.
  - Asserts that backup codes persist across state-to-JSON serialization (`toJson()`) and store hydration cycles (`loadFromStore()`).
  - Confirms custom backup code assignments persist and reload without truncation.
- **`backup_complete_test.dart`:**
  - Seeds a full 2-year workout history (104 calendar weeks, 208 workout sessions, progressive overload weight curves, warmup/normal/failure sets, RPE ratings, bodyweight entries).
  - Creates custom exercises with attached media images, background photos, custom notes, barbell inventory records, and gym places.
  - Generates a full `.zip` archive via `BackupZip.exportZip()`, wipes the local database (`fit.resetAllData()`), and executes a full restoration via `BackupZip.importZip()`.
  - Asserts that all sessions, exercises, sets, weights, profile attributes, and media attachments match the pre-export dataset with zero corruption.

---

## 8. Build, Tooling, & Deployment Pipeline

### 8.1 Android Gradle Build Configuration (`android/app/build.gradle.kts`)
The Android build configuration is written in Kotlin DSL with build optimizations:
- **Core Library Desugaring:**
  ```kotlin
  compileOptions {
      sourceCompatibility = JavaVersion.VERSION_17
      targetCompatibility = JavaVersion.VERSION_17
      isCoreLibraryDesugaringEnabled = true
  }
  dependencies {
      coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
  }
  ```
- **ABI Split Version Code Generation:**
  Overwrites output APK version codes to provide ABI-specific versioning for Google Play:
  ```kotlin
  val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
  android.applicationVariants.configureEach {
      val variant = this
      variant.outputs.forEach { output ->
          val abiVersionCode = abiCodes[output.filters.find { it.filterType == "ABI" }?.identifier]
          if (abiVersionCode != null) {
              (output as ApkVariantOutputImpl).versionCodeOverride =
                  variant.versionCode * 10 + abiVersionCode
          }
      }
  }
  ```
- **Privacy & Binary Hardening:**
  Strips dependency information from release bundles:
  ```kotlin
  dependenciesInfo {
      includeInApk = false
      includeInBundle = false
  }
  ```

### 8.2 Crowdin Localization Workflow
Keizoku supports 16+ languages (including RTL Arabic and Persian):
- **Configuration (`crowdin.yml`):**
  Maps `/lib/l10n/app_en.arb` to `/lib/l10n/app_%two_letters_code%.arb`.
  Handles language mappings for regional Chinese and Portuguese locales (`zh-TW` $\rightarrow$ `zh_Hant`, `es-ES` $\rightarrow$ `es`, `pt-BR` $\rightarrow$ `pt`).
- **Code Generation (`l10n.yaml`):**
  Invokes Flutter's built-in code generator to compile typesafe `AppLocalizations` delegates.

### 8.3 Fastlane Automated Deployment (`fastlane/`)
Google Play Store publishing metadata is structured for automated release workflows via Fastlane Supply:
- **Localized Store Listings:**
  - `fastlane/metadata/android/en-US/`: `title.txt`, `short_description.txt`, `full_description.txt`, feature graphics, and phone screenshots.
  - `fastlane/metadata/android/es-ES/`: Spanish store copy and localized screenshots.
- **Versioned Changelogs:**
  Contains discrete changelog files mapped to APK version codes (`11.txt`, `12.txt`, ..., `53.txt`), providing automated release notes during fastlane deployment runs.

---

## 9. Authoritative Architecture Summary Matrix

| Architectural Layer | Implementation Component | Technical Characteristics |
| :--- | :--- | :--- |
| **State Coordinator** | `FitState` (`lib/state/fit_state.dart`) | Extends `FitCore` with 11 domain mixins. Zero third-party state dependencies. |
| **Cloud Authentication**| `FirebaseAuth` (`lib/services/firebase_service.dart`) | Instant anonymous auth (`signInAnonymously`) provisioning persistent UIDs. |
| **Handle Claim Engine** | `handles/{cleanHandle}` | Atomic Firestore transactions (`runTransaction`) with old handle release and launch conflict resolution. |
| **Zero-Password Recovery**| `restoreAccountWithBackupCode()` | 13-character `GYM-XXXX-XXXX` Base-32 secret key restoring routines, biometrics, streaks, and social graph. |
| **Cloud Community Hub** | `shared_routines` & `friend_requests` | Real-time streams for friend streaks, requests, and 6-char routine sharing codes (`GYM-XXXX`). |
| **Privacy Isolation** | `MediaStore` (`lib/services/media_store.dart`) | Binary photos, avatars, and progress pictures are strictly on-device; omitted from cloud payloads. |
| **GDPR Cloud Purge** | `deleteAccountAndAllData()` | Atomic batch purging handle reservation, user profile, bidirectional friendships, requests, and shared routines. |
| **Timer Isolation** | `clock` (`ValueNotifier<int>`) | 1-Hz ticker decoupled from `notifyListeners()` to eliminate UI repaint churn. |
| **Local Persistence** | `Store` (`lib/services/local_store.dart`) | 400ms debounced atomic JSON serialization into SharedPreferences (`keizoku_v1`). |
| **Binary SQLite** | `SqliteDb` (`lib/services/sqlite_reader.dart`) | Zero-dependency pure Dart B-Tree & Varint parser for reading FitNotes databases. |
| **Binary Export** | `FitWriter` (`lib/services/fit_export.dart`) | Garmin `.FIT` binary generator with official 16-bit CRC checksum validation. |
| **Audio Engine** | `Beeper` (`lib/services/beeper.dart`) | Algorithmic in-memory 16-bit 44.1 kHz PCM `.WAV` synthesis for timer ticks and chimes. |
| **Live Notifications**| `LiveNotifier.kt` (Android Kotlin) | Android 16 API 36 `ProgressStyle` promoted ongoing notifications + legacy `RemoteViews`. |
| **Wear OS** | `WearShell` (`lib/wear/wear_shell.dart`) | Rotary crown scroll stack, 15-second low-power ambient dimming, high-contrast OLED view. |
| **Vector Anatomy** | `BodyPainter` (`lib/widgets/body_map.dart`) | 535x462 SVG coordinate canvas with point-in-polygon ray-cast hit testing. |
| **Typographic Scale**| `AppTheme` (`lib/theme/app_theme.dart`) | `DarkerGrotesque` (+18% scale, `fontScale = 1.18`), `SpaceMono` (+8% scale, `monoScale = 1.08`). |
| **Testing** | 68 Suites (`test/`) | 100% mock-free unit, widget, domain, and mathematical calculation test coverage. |
