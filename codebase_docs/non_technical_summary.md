# Keizoku: The Non-Technical Product & Athlete Guide

> **"Lift. Log it. Grow."**  
> *A comprehensive guide to the philosophy, athlete experience, cloud connectivity, end-to-end user journeys, and feature architecture of Keizoku.*

---

## 1. Executive Summary & Identity

### What is Keizoku?
**Keizoku** (継続 — Japanese for *continuity*, *persistence*, and *unbroken consistency*) is an open-source, high-performance, privacy-first hybrid fitness suite built for Android, iOS, and Wear OS. Rooted in the timeless principle that real physical transformation is forged through relentless consistency rather than fleeting motivation, Keizoku is designed for athletes who take their training seriously.

Where mainstream fitness applications have devolved into bloated ad networks, subscription paywalls, and noisy social feeds designed to hijack your dopamine between sets, Keizoku adopts a purist, distraction-free ethos. It reconciles zero-bloat, ad-free fitness with modern cloud connectivity, getting completely out of your way so you can lift, track your numbers accurately, and observe objective progress over time.

### The Privacy-First Hybrid Fitness Suite
Modern fitness tracking usually forces athletes into an agonizing compromise:
1. **The Pure Offline Silo:** Private and offline, but isolated. You cannot share routines with training partners, see friends' consistency streaks, or restore your training history if you change devices without wrestling with manual file transfers.
2. **The Cloud Social Network:** Connected, but abusive. You are forced to create accounts with email and password traps, endure intrusive ad banners, surrender biometric photos and health data to corporate data-mining servers, and pay recurring monthly subscriptions just to unlock routine slots or plate math.

**Keizoku shatters this false dichotomy with a Hybrid Architecture:**
- **Local-First & Offline-Resilient:** All workout logging, rep counts, barbell math, body metrics, and timer state execute locally at sub-millisecond latency. Whether you train in an underground powerlifting dungeon or a remote basement gym with zero cell signal, Keizoku never lags or fails.
- **Privacy-Bound Cloud Connectivity:** Seamlessly powered by Firebase, Keizoku introduces modern social connectivity—unique athlete `@handle` claiming, friend streak leaderboards, community routine sharing, and instant cross-device account restoration—**without** passwords, emails, advertising, or biometric exposure.

### Core Philosophy & Guiding Principles

1. **Zero-Friction, Zero-Password Identity**
   - Keizoku provides instant, anonymous cloud connectivity from the moment you first open the app. There are no email verification codes, password resets, or spam newsletters. You claim your athlete handle and receive a private 13-character Backup Key.

2. **Absolute Biometric Privacy**
   - Your body is your business. Biometric progress photos, physique comparisons, custom avatar pictures, and profile banners live **strictly on your physical device** in sandboxed local storage (`MediaStore`). They are never uploaded to the cloud or analyzed by remote servers.

3. **100% Free & Open Source (GPL-3.0)**
   - Every single capability—unlimited custom routines, superset chaining, equipment plate calculators, RPE/RIR tracking, Wear OS wrist logging, Strava FIT export, and full data backups—is completely free for every athlete on day one, forever.

4. **Extreme Battery Efficiency & OLED Mastery**
   - Built with native-compiled Flutter and custom hardware-accelerated shaders, Keizoku features true OLED pitch-black styling (`#000000`) that powers down display pixels, drawing minimal battery power during grueling two-hour training sessions.

---

## 2. Target Audience & Fitness Personas

Keizoku is engineered to meet athletes at their exact level of training sophistication while keeping the interface uncluttered for newcomers:

```
┌──────────────────────────────────────────────────────────────────────────┐
│                             KEIZOKU ATHLETES                             │
├─────────────────┬──────────────────┬──────────────────┬──────────────────┤
│   Powerlifter   │   Bodybuilder    │   Calisthenics   │  General Fitness │
│  & Strength     │  & Hypertrophy   │   & Bodyweight   │   & Beginners    │
├─────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ • 1RM Tracker   │ • Muscle Radar   │ • Progression    │ • Pre-built Plans│
│ • RPE / RIR     │ • Volume Heatmap │   Trees          │   (Full Body,PPL)│
│ • Plate Math    │ • Muscle Fatigue │ • No-Kit Routines│ • 500+ Exercise  │
│ • DOTS / Wilks  │ • Drop/Fail Sets │ • Duration/Reps  │   Form Guides    │
│ • Rest Timers   │ • Tape Measures  │ • Rings/Bands    │ • Visual Body    │
│ • Barbell Types │ • Moments Journal│   Support        │   Tap Selection  │
└─────────────────┴──────────────────┴──────────────────┴──────────────────┘
```

### 1. Powerlifters & Strength Athletes
- **Core Needs:** Precise barbell math, micro-loading tracking, RPE (Rate of Perceived Exertion) and RIR (Reps in Reserve) auto-regulation, DOTS/Wilks competitive scoring, dedicated warm-up pyramid ramps, and customizable rest timer alerts.
- **Why Keizoku Wins:** Automatically computes exact barbell plate loading per side from the specific plate inventory configured for your gym. Tracks actual "Best Set" weight records alongside RPE and calculates percentage-based target tables on the fly.

### 2. Bodybuilders & Hypertrophy Enthusiasts
- **Core Needs:** High-volume tracking, muscle fatigue visualization, superset and drop-set logging, body composition measurements, and physique progression journals.
- **Why Keizoku Wins:** The interactive anatomical Muscle Radar and Body Heatmap reveal neglected muscle heads at a glance. Granular set categories (Normal, Warm-up, Drop Set, Failure, Rest-Pause) ensure true effective working volume is separated from warm-up sets.

### 3. Calisthenics & Bodyweight Athletes
- **Core Needs:** Progression tracking (e.g., from Incline Push-Up to Regular, Diamond, Dip, and Weighted Dip), duration-based holds (planks, L-sits), and resistance band integration.
- **Why Keizoku Wins:** Built-in support for the renowned *r/bodyweightfitness Recommended Routine*, exercise progression suggestions, and native handling of bodyweight-plus-load and isometric seconds.

### 4. General Gym-Goers & Beginners
- **Core Needs:** Clear visual form instructions, easy routine templates, intuitive tap-to-select body mapping, and an interface that does not overwhelm.
- **Why Keizoku Wins:** Beginners do not need to memorize anatomical Latin names—they simply tap on the chest, back, or quads on the visual body map to discover all corresponding movements with looping demonstration art.

---

### Why Athletes Migrate to Keizoku

| Pain Point in Competitors | Hevy / Strong / JEFIT / FitNotes | Keizoku Hybrid Solution |
|---|---|---|
| **Subscription Paywalls** | Restrict routine limits (e.g., 3 routines max on free tiers), charge monthly fees for basic charting or dark mode. | **100% Free & Open Source.** Unlimited routines, custom exercises, plate math, and charts forever. |
| **Intrusive Social Feeds** | Forcing users into algorithmic feeds, follower counts, sponsored ads, and clutter between sets. | **Pure Focus Community.** No algorithmic feed. Follow friends by handle, celebrate active workout streaks, and share routines cleanly. |
| **Account & Password Friction** | Tedious registration forms, forgotten passwords, email verification links, and account locks. | **Zero-Password Anonymous Auth.** Start lifting instantly. Claim your `@handle` and secure your account with a 13-character Backup Key. |
| **Cloud Dependency & Lag** | Sluggish load times; workouts fail to load when cell signal drops in underground gym facilities. | **Instantaneous Offline Operation.** Local SQLite/Store execution with unlimited Firestore offline caching. Zero lag between sets. |
| **Biometric Privacy Exploitation** | Uploading private physique photos and bodyweight logs to corporate cloud buckets. | **Strict Local Invariant.** Biometric photos and profile media stay strictly in device sandbox storage. Never uploaded to the cloud. |
| **Data Lock-In** | Exporting workout history is paywalled, throttled, or locked into proprietary formats. | **Radical Open Data.** Full one-tap ZIP backup with media, standard CSV export, Strava FIT export, and 1-click import from all major apps. |

---

## 3. The Online & Social Experience (Cloud Done Differently)

Keizoku brings lifters together without the toxicity or privacy abuses of typical fitness social networks.

```
┌────────────────────────────────────────────────────────────────────────┐
│                      KEIZOKU HYBRID CLOUD ENGINE                       │
├──────────────────────────────────┬─────────────────────────────────────┤
│        LOCAL DEVICE ENGINE       │          ONLINE FIREBASE HUB        │
├──────────────────────────────────┼─────────────────────────────────────┤
│ • Sub-millisecond set logging    │ • Anonymous Instant Auth            │
│ • Private progress photos        │ • Unique Athlete @handle Claiming   │
│ • Local profile avatar & banner  │ • Secret Recovery Key (GYM-XX-XX)   │
│ • Custom gym plate inventories   │ • Real-Time Friends & Streak Board  │
│ • Offline workout store cache    │ • Community Routines Hub (GYM-8X2A) │
│ • Complete offline resilience    │ • One-Tap Right to be Forgotten     │
└──────────────────────────────────┴─────────────────────────────────────┘
```

### 1. Zero-Friction Passwordless Access
When you open Keizoku for the first time, the app connects silently to Firebase using Anonymous Authentication (`FirebaseAuth.instance.signInAnonymously()`). You are never prompted to enter an email address, configure a password, or verify a confirmation link. You are ready to log workouts immediately.

### 2. Unique Athlete Handles
Lifters can establish their social identity by choosing a unique athlete handle (e.g., `@alex_lifts`).
- **Live Debounced Validation:** Keizoku checks handle availability in real time as you type.
- **Atomic Claiming Transactions:** Handles are claimed using atomic cloud transactions (`runTransaction`), ensuring that no two athletes can ever register the same handle.
- **Easy Updating:** You can refine your handle or display name at any time from Settings.

### 3. The Secret Recovery Backup Code (`GYM-XXXX-XXXX`)
How do you restore your cloud account and friends when switching phones without a password or email?
- Keizoku automatically generates a cryptographically random, 13-character master key formatted as `GYM-XXXX-XXXX` (persisted securely in local storage as `fit.backupCode`).
- This code acts as your private recovery key.
- Whenever you switch phones or reinstall the app, simply tap **"Restore Account"** on the onboarding screen or in Settings, type your `@handle` and your backup code, and Keizoku instantly restores your cloud identity, claimed handle, weekly workout goals, active training streak, and friend roster.

### 4. Community Social Network
The Social screen (`social_screen.dart`) is divided into an athlete-centric two-tab experience:

- **Athlete Search & Friend Requests:**
  - Search for training partners directly by `@handle`.
  - Send friend requests with real-time status tracking.
  - Incoming friend requests trigger instant alerts and liquid notch notifications, allowing you to accept or decline with a single tap.
- **Friends Tab & Live Streak Leaderboard:**
  - View your connected friends alongside their current weekly workout streaks.
  - A subtle streak flame lights up when an athlete maintains their consistency, creating positive, healthy accountability without toxic algorithmic commentary.
  - **Offline Friends Caching:** Even if you launch the Social tab in an underground gym with no reception, Keizoku displays your locally cached friends list (`cached_friends`).

### 5. Community Routines Hub
Keizoku makes sharing and discovering training programs seamless and open:
- **Share with 6-Character Codes:** Publish any of your custom-engineered routines to the community with one tap. Keizoku generates a unique 6-character alphanumeric routine code (e.g., `GYM-8X2A`).
- **Explore Community Routines:** Browse community-created splits streamed in real time from lifters worldwide, complete with target muscle categories and exercise counts.
- **One-Tap Routine Import:** Enter a code or tap "Import" on any community routine. Keizoku immediately resolves the exercise list and saves the routine straight into your local routine library, ready for your next workout session.

---

## 4. The Strict Privacy & Local-First Invariant

In Keizoku, privacy is not a marketing checkbox—it is a fundamental software architectural guarantee.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        DATA PRIVACY BOUNDARY                           │
├──────────────────────────────────┬─────────────────────────────────────┤
│         SYNCED TO CLOUD          │      STRICTLY LOCAL ON-DEVICE       │
├──────────────────────────────────┼─────────────────────────────────────┤
│ • Public Athlete @handle         │ • Biometric Progress Photos         │
│ • Display Name & Bio             │ • Personal Workout Notes            │
│ • Weekly Workout Target & Streak │ • Profile Picture & Custom Banners  │
│ • Public Shared Routine Code     │ • Video Form Check Recordings       │
│ • Friend Connections & Requests  │ • Detailed Raw Set History Logs     │
│ • Secret Recovery Key (Encrypted)│ • Gym Place Plate Inventory         │
└──────────────────────────────────┴─────────────────────────────────────┘
```

1. **Strict Local Biometric Storage:**
   - Your body progression photos, side-by-side comparison shots, profile avatar, and banner images are stored strictly in your device's private sandboxed directory (`MediaStore`).
   - They are **never** uploaded to Firebase, cloud storage buckets, or external servers. If an athlete takes a physique check in their gym locker room, it stays on their phone.
2. **Offline-First Resilience:**
   - The app enables unlimited Firestore offline persistence (`Settings.CACHE_SIZE_UNLIMITED`) alongside local database storage.
   - If network connectivity drops entirely, you can log sets, run rest timers, create routines, and browse cached friends without a hiccup. The app seamlessly syncs public profile stats the next time an internet connection is detected.
3. **GDPR "Right to be Forgotten" (One-Tap Account Purge):**
   - Keizoku respects total athlete sovereignty. If you ever decide to delete your cloud profile, tapping **"Delete Account & All Data"** in Settings triggers `firebaseService.deleteAccountAndAllData()`.
   - This atomically purges your user document from Firestore, releases your claimed `@handle` back to the public pool, deletes all outgoing and incoming friend requests, severs all friendships, removes your shared community routines, and wipes your local cloud session.

---

## 5. End-to-End Athlete User Journey

Keizoku’s user experience is designed around the natural lifecycle of an athlete's training: from onboarding to routine design, gym floor execution, and post-workout reflection.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ATHLETE TRAINING LIFECYCLE                          │
└──────┬───────────────────┬───────────────────┬───────────────────┬──────────┘
       │                   │                   │                   │
       ▼                   ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  1. Setup &  │───>│2. Routine    │───>│3. Live Gym   │───>│4. Review &   │
│  Onboarding  │    │   Design     │    │   Session    │    │   Moments    │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

---

### Step 1: Onboarding, Handle Claiming & Instant Recovery
When you open Keizoku for the first time, you are guided through a sleek 60-second onboarding flow:
1. **Welcome & Philosophy:** A brief introduction outlining Keizoku’s ad-free, privacy-first commitment.
2. **Choose Your Handle or Restore:**
   - **New Lifter:** Choose your unique `@handle` with live availability feedback. Keizoku generates your 13-character Backup Key (`GYM-XXXX-XXXX`) and instructs you to store it safely.
   - **Returning Lifter:** Tap **"Restore Account"** (`showRestoreAccountSheet`) to enter your existing handle and backup key, instantly recovering your profile and friend connections.
3. **Unit Preferences:** Choose between Metric (**Kilograms & Centimeters**) and Imperial (**Pounds & Inches**).
4. **Tactile Body Calibration:** Dial in your current weight, height, age, biological sex, and baseline activity level using fluid rolling ruler dials (`BodyRulerPicker`).
5. **Weekly Goal:** Select your weekly workout frequency goal (e.g., 3, 4, or 5 days) to activate home screen streak counters.

---

### Step 2: Routine Design, AI Planner & Routine Hub
Athletes can build their training schedule with unmatched flexibility:

```
                      ┌──────────────────────────────────────┐
                      │          Routine Creation            │
                      └──────────────────┬───────────────────┘
                                         │
         ┌───────────────────────────────┼──────────────────────────────┐
         ▼                               ▼                              ▼
┌──────────────────┐           ┌──────────────────┐           ┌──────────────────┐
│ Curated Programs │           │ AI Plan Generator│           │ Community Hub    │
├──────────────────┤           ├──────────────────┤           ├──────────────────┤
│ • Push Pull Legs │           │ • Export Prompt  │           │ • 6-Char Code    │
│ • Upper / Lower  │           │ • Paste into LLM │           │   (GYM-8X2A)     │
│ • StrongLifts 5x5│           │ • Parse JSON Back│           │ • Stream Routines│
│ • Calisthenics RR│           │ • 100% Private   │           │ • 1-Tap Import   │
└──────────────────┘           └──────────────────┘           └──────────────────┘
```

- **Curated Golden-Standard Templates:** Pre-loaded with battle-tested strength programs including Push-Pull-Legs (PPL), Upper/Lower 4-day split, Full Body 3-day split, StrongLifts 5×5, Starting Strength, and the Calisthenics Recommended Routine.
- **Custom Routine Builder:** Create custom folders (e.g., "Hypertrophy Block A", "Strength Peaking"), configure default rest times, assign supersets, and link routines to recurring days of the week.
- **Privacy-First AI Routine Generator (`ai_plan_screen.dart`):**
  - Instead of streaming your private fitness data to expensive third-party AI APIs, Keizoku compiles your equipment and target split into an optimized system prompt.
  - You copy the prompt into any LLM of your choice (ChatGPT, Claude, Gemini, or a local offline Ollama instance).
  - You paste the generated JSON back into Keizoku, which validates the structure, matches exercises against its 500+ database, and imports the full routine instantly.
- **Community Routine Codes:** Enter a 6-character routine share code (`GYM-8X2A`) shared by a friend to add their exact routine into your library in seconds.

---

### Step 3: Gym Places & Equipment Setup (`places_screen.dart`)
Never do plate math in your head again:
- **Location Profiles:** Configure customized profiles for each place you train (e.g., "Downtown Powerlifting Club", "Home Garage Gym", "Hotel Travel Kit").
- **Barbell Specification:** Set the default bar weight for that facility (e.g., standard 20kg Olympic bar, 15kg women's bar, or 10kg EZ-curl bar).
- **Plate Inventory Management:** Enter the exact plate pairs available at that specific gym (e.g., four pairs of 20kg, two pairs of 10kg, four pairs of 5kg, and micro-plates).
- **Filtered Exercise Discovery:** Setting your active Gym Place automatically filters Keizoku's 500+ exercise library to display only movements you have the physical equipment to perform!

---

### Step 4: The Live Workout Session & Sensory Flow
Once you step onto the gym floor, Keizoku shifts into live training mode:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   ACTIVE LIVE SESSION ARCHITECTURE                     │
├────────────────────────────────────────────────────────────────────────┤
│  [Top Bar]  Elapsed Time  ·  Session Lock 🔒  ·  Plate Calc 🧮         │
│  [Strip]    Bench Press ──▶ Incline DB ──▶ Cable Fly ──▶ Triceps       │
│  [Demo]     Looping Vector Animation / Video Form Check                │
│  [Table]                                                               │
│   Set  Kind    Previous     Weight      Reps    RPE     Done           │
│    1   [ W ]   60 kg x 10   [ 60 kg ]   [ 10 ]  [ 7 ]   [ ✓ ] ──▶ REST │
│    2   [   ]   90 kg x 8    [ 90 kg ]   [ 8  ]  [ 8 ]   [ ✓ ]   TIMER  │
│    3   [ D ]   100 kg x 6   [ 75 kg ]   [ 12 ]  [ 9.5]  [   ]   RINGS  │
├────────────────────────────────────────────────────────────────────────┤
│  [Notification Tray]  ✓ Done Set  |  ❚❚ Pause  |  +15s  |  Skip Rest › │
│  [Wear OS Watch]      Rotary dial weight tweak  ·  Wrist vibration tap │
└────────────────────────────────────────────────────────────────────────┘
```

- **Ghost Performance Watermarks:** Previous workout performances appear as subtle watermarks in the input fields, showing you the exact target needed for progressive overload.
- **Granular Set Classification:** Categorize any set as **Normal**, **Warm-up** (excluded from volume and fatigue math), **Drop Set**, **Failure**, or **Rest-Pause**.
- **Effort Auto-Regulation (RPE / RIR):** Record Rate of Perceived Exertion ($6.0$–$10.0$) or Reps in Reserve ($0$–$4+$) alongside your weights to manage central nervous system fatigue.
- **Superset Chaining:** Link exercises into supersets. Ticking a set on Exercise A automatically navigates you to Exercise B, delaying the rest timer until the full circuit is completed.
- **Dynamic Rest Timer & Audio Chimes:**
  - Checking off a set automatically launches the rest countdown banner.
  - Crisp synthesized audio chimes (`Beeper` frequency tones) and tactile haptics cue you when it is time to lift, gracefully dipping background music without cutting it off.
- **Lock Screen & Notification Controls:** Keep your phone locked or in your pocket. Keizoku's foreground notification service displays the active rest timer and provides quick actions (`✓ Done Set`, `+15s`, `Skip Rest`, `Pause`).
- **Wear OS Wrist Logging:** Leave your phone on the bench. Use the standalone Wear OS companion to tick off sets, adjust weights using the physical rotary crown, and receive wrist vibration cues when rest time expires.
- **Reboot Resilience:** If your phone dies or restarts mid-session, Keizoku restores your active workout down to the exact completed rep upon reopening.

---

### Step 5: Post-Workout Review, Moments & Social Celebration
When you finish your session, Keizoku computes comprehensive analytical breakdowns:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        WORKOUT CELEBRATION                             │
│                  ★ 3 NEW PERSONAL RECORDS BROKEN! ★                    │
│             54 min  ·  18 Working Sets  ·  12,450 kg Lifted            │
├────────────────────────────────────────────────────────────────────────┤
│  [Progression] Actual "Best Set" Strength Curves (TrendChart)          │
│  [Fatigue]     Anatomical Muscle Heatmap & Radar Volume Split          │
│  [Consistency] Multi-Week Heatmap & Training Streak Count              │
│  [Biometrics]  10-Point Body Measurements & Private Progress Photos    │
└────────────────────────────────────────────────────────────────────────┘
```

- **PR Trophies & Actual "Best Set" Tracking:**
  - Celebrates new Personal Records with gold, silver, and bronze badges.
  - Rather than relying on speculative 1RM formulas, Keizoku tracks **actual highest weight successfully lifted** for each movement, opening progression curves via the `TrendChart` in the strength tracker sheet.
- **Anatomical Muscle Radar & Heatmap:** View 12-axis muscle split radar charts and front/back body heatmaps highlighting worked muscle groups over the last 7, 30, or 90 days.
- **Moments Photo Journal (`moments_screen.dart`):**
  - Capture post-workout photos, pump checks, and training notes in an integrated chronological journal.
  - All Moments images remain 100% private in local device storage.
- **Body Composition & Tape Measurements:** Log bodyweight alongside 10 distinct anatomical tape measurement sites (Neck, Shoulders, Chest, Biceps, Forearms, Waist, Hips, Thighs, Calves, and Body Fat %).
- **Aesthetic Workout Story Stickers (`sticker_screen.dart`):**
  - Transform any completed workout into a high-resolution 1080p card for Instagram Stories or messaging apps.
  - Choose from 6 designer layouts (minimalist kicker, big numbers, exercise breakdowns, or streak celebrations) and 6 bespoke color palettes (Clean White, Pitch Dark `#111111`, Ember Orange, Brass Gold, Sage Green, Warm Cream `#E8E1D7`).
  - Overlay the card directly over your gym selfie with two-finger pinch, zoom, and rotate gestures.
- **Strava & Garmin FIT Export (`strava_sheet.dart`, `fit_export.dart`):** Export completed workouts as genuine binary `.fit` files to upload directly to Strava or Garmin Connect with full set, rep, and load metadata.

---

## 6. Deep Feature Guide & Aesthetic Language

### 1. Workout & Routine Architecture
- **Hierarchical Routine Folders:** Group routines by training phase (e.g., "Strength Peaking", "Hypertrophy", "Deload").
- **Flexible Scheduling:** Assign routines to specific weekdays or run an alternating rolling split.
- **Exercise Swapping on the Fly:** Swap occupied equipment in real time without altering your permanent routine template.
- **Universal Importer:** Import historical workout data from Hevy, Strong, FitNotes, Lyfta, or generic CSV files in one click.

### 2. Built-In Fitness Tools & Calculators
Keizoku integrates 8 dedicated athlete calculators directly into the app:

| Calculator | Description | Athlete Benefit |
|---|---|---|
| **1RM Calculator** | Computes theoretical one-rep maximum using Brzycki, Epley, Lombardi, and O'Conner formulas. | Safe benchmark testing without dangerous max-out strain. |
| **Plate Loading Calculator** | Calculates the exact plate stacks required per side based on bar weight and gym inventory. | Eliminates plate math errors when exhausted between heavy working sets. |
| **Warm-Up Ramp Calculator** | Generates a 4-to-5 step progressive ramp-up pyramid (bar $\rightarrow$ 40% $\rightarrow$ 60% $\rightarrow$ 80% $\rightarrow$ working load). | Prepares central nervous system while preventing premature fatigue. |
| **RPE Load Calculator** | Calculates target working weight for target reps and RPE/RIR based on current strength benchmarks. | Essential for auto-regulated powerlifting programs. |
| **DOTS / Wilks Score** | Computes standardized powerlifting strength-to-bodyweight ratios for Squat, Bench, and Deadlift. | Objective comparison of pound-for-pound strength across weight classes. |
| **TDEE & Calorie / Macro** | Computes Total Daily Energy Expenditure using Mifflin-St Jeor and Katch-McArdle formulas. | Precise nutritional guidance tuned to training frequency. |
| **Body Fat Estimator** | US Navy tape circumference method (neck, waist, hip, height). | Track body recomposition progress without expensive DEXA scans. |
| **BMI Calculator** | Standard Body Mass Index tracking with medical classification thresholds. | Baseline demographic reference. |

### 3. Visual Design Language & Tactile Feel

Keizoku combines modern Material 3 expressive design with custom tactile interaction physics:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        DESIGN SYSTEM FOUNDATION                        │
├────────────────────────────────────────────────────────────────────────┤
│  [Dark Surface]     Page: #121316  │ Raised: #1E2026 │ Border: #383B44 │
│  [OLED Black]       Pitch: #000000 │ Card: #121212   │ Ultra Battery   │
│  [Accents]          Ember: #DE5B30 │ Brass: #D9A184  │ Sage: #7FB88A   │
├────────────────────────────────────────────────────────────────────────┤
│  [Typography]       Display: Darker Grotesque (Scale: 1.18)            │
│                     Monospace: Space Mono (Scale: 1.08, Tabular Digits)│
│  [Physics]          Liquid Notch morphing physics                      │
│  [Tactile Touch]    Expressive pressable bouncy haptics                │
│  [Optics]           Custom GLSL Fragment Shader (edge_fade.frag)       │
└────────────────────────────────────────────────────────────────────────┘
```

1. **Dark-Mode First & OLED Pitch-Black Aesthetic**
   - Rich dark charcoal surfaces (`#121316`) paired with an optional **Pure OLED Black Mode (`#000000`)** that powers down pixels on AMOLED displays.
   - Dynamic Color support (Material You) extracts harmonious color palettes from modern Android wallpapers.

2. **Liquid Notch & Morphing Pill UI (`liquid_notch.dart`)**
   - Organic, fluid morphing animation originating from the device camera notch.
   - Rest timer expirations, personal record toasts, and friend request alerts flow downwards with realistic liquid curvature physics.

3. **Bespoke Typography Hierarchy**
   - **Darker Grotesque (`fontScale: 1.18`):** An elegant, humanistic neo-grotesque typeface utilized for screen titles, exercise names, and UI headers.
   - **Space Mono (`monoScale: 1.08`):** A fixed-width monospace font applied to all numerical data (weights, reps, stopwatch clocks, rest timer digits). Tabular figures prevent numbers from jittering during active counting.

4. **Tactile Feedback & Expressive Pressables (`expressive_pressable.dart`)**
   - Buttons, cards, and checkmarks provide micro-scale feedback (scaling down to `0.96` on touch down) paired with calibrated mechanical haptic impulses (`HapticFeedback.selectionClick()` and `heavyImpact()`).

5. **Glassmorphic Depth & Hardware Shaders**
   - Frosted modal sheets (`kSheetBlur: 14`) cast soft blur barriers over background screens to maintain spatial context.
   - A custom GLSL fragment shader (`edge_fade.frag`) provides smooth vignette edge blending for scrolling exercise catalogs.

---

## 7. Summary: The Keizoku Promise

In an app marketplace dominated by venture-backed subscriptions, artificial paywalls, and noisy social clutter, Keizoku represents a return to what truly matters:

> **Honest software for honest work.**  
> No paywalls. No ads. No telemetry. No passwords. No biometric surveillance.  
> Just your body, the iron, your community, and the numbers that prove you were here yesterday—and are stronger today.

**Keizoku (継続) — Lift. Log it. Grow.**
