# Body Forge

> **Log your lifts. Track your body. Close your rings. All in one place — built natively for iOS 17.**

A performance-first fitness tracking app for iOS. Body Forge combines intelligent workout logging, real-time biometric data from Apple Health, and a Bento Grid interface designed to surface what matters during a session — not after it.

---

## Core Design Philosophy

Body Forge is built around one idea: **remove friction from the moment you touch iron to the moment you rack it.**

Every screen is optimized for single-hand use mid-set. The data model is local-first with optional cloud sync. HealthKit reads happen in the background so heart rate and calorie data are ready the moment you need them.

---

## How It Works

```
┌─────────────────┐    ┌──────────────────────┐    ┌────────────────────────┐
│   Program View   │───▶│   Active Workout      │───▶│   Completion + History │
│                  │    │                       │    │                        │
│  Browse & select │    │  Log sets in real-    │    │  Volume summary,       │
│  your program    │    │  time. Rest timer on  │    │  PRs flagged,          │
│  for the day     │    │  Dynamic Island.      │    │  HealthKit write.      │
└─────────────────┘    │  Live HR + Calories.  │    └────────────────────────┘
                        └──────────────────────┘
                                   │
                        ┌──────────▼───────────┐
                        │   SwiftData (Local)   │
                        │   Firestore (Cloud)   │
                        └──────────────────────┘
```

1. **Select a program** — browse your training plans, pick the day's session
2. **Log in real-time** — enter sets, reps, and weight with instant comparison to your last session
3. **Rest timer** — fires automatically after each set; appears on Dynamic Island and Lock Screen via Live Activities
4. **HealthKit sync** — heart rate, active calories, and workout metadata are written to Apple Health at session close
5. **Analyze progress** — per-exercise strength charts, body measurement trends, and weight history are updated automatically

---

## Features

### Workout Engine
- Create and manage multi-day training programs with full exercise customization
- Log sets, reps, weight, and rest time with per-set trend indicators (up/down vs previous session)
- Superset support with linked exercise display
- Workout types: Strength, Cardio, Circuit
- Built-in exercise technique reference for 100+ movements

### HealthKit Integration
- Live heart rate and active calorie feed during sessions
- Activity rings displayed and closeable from within the app
- Step count and sleep data pulled automatically
- Workouts written back to Apple Health on completion

### Live Activities & Dynamic Island
- Rest timer persists on Dynamic Island and Lock Screen while the app is backgrounded
- Current exercise name and set count visible without unlocking the phone
- Timer fires a haptic alert when rest is complete

### Analytics & Progress

| View | What It Shows |
|---|---|
| **Workout History** | Chronological log of all sessions with volume and duration |
| **Progress Charts** | Per-exercise 1RM trend over time using Swift Charts |
| **Body Measurements** | Tracked metrics (chest, waist, arms, etc.) with delta visualization |
| **Weight Tracker** | Daily weigh-in log with rolling average graph |

### Nutrition & Health
- Calorie calculator with TDEE and macro breakdown
- Nutrition guide with food reference data
- Supplement tracker with dosing and timing views
- Hormones reference view

### AI Trainer
- In-app AI coaching panel for workout programming advice and technique guidance

### Authentication & Sync
- Google Sign-In via Firebase Authentication
- Cloud sync with Firestore for multi-device access
- Local persistence via SwiftData — fully functional offline

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Language** | Swift 5.9+ | — |
| **UI** | SwiftUI | All screens and components |
| **Architecture** | MVVM | ViewModels + Managers pattern |
| **Local Storage** | SwiftData | Offline-first persistence |
| **Health Data** | HealthKit | Biometrics read/write |
| **Live Activities** | ActivityKit | Dynamic Island + Lock Screen widget |
| **Charts** | Swift Charts | Progress and trend visualization |
| **Backend** | Firebase Firestore | Cloud sync |
| **Auth** | Firebase Authentication + Google Sign-In | User identity |
| **Async** | Swift Concurrency (`async/await`, `@MainActor`) | All async operations |
| **Localization** | String Catalogs (`.xcstrings`) | Multi-language support |

---

## Project Structure

```
GymTracker/
├── GymTracker/
│   ├── Models/                   # SwiftData schemas and domain models
│   │   ├── AnalyticsModels.swift
│   │   ├── ProgramModels.swift
│   │   └── SleepModels.swift
│   ├── Services/                 # Business logic services
│   │   ├── AnalyticsService.swift
│   │   ├── CalorieCalculator.swift
│   │   └── SleepService.swift
│   ├── Protocols/                # Shared protocols
│   ├── DI/                       # Dependency injection container
│   ├── *View.swift               # SwiftUI screens and reusable components
│   ├── *ViewModel.swift          # View-scoped logic
│   ├── WorkoutManager.swift      # Active session state machine
│   ├── HealthManager.swift       # HealthKit read/write
│   ├── LiveActivityManager.swift # ActivityKit session lifecycle
│   ├── SyncManager.swift         # Firestore sync orchestration
│   ├── AuthManager.swift         # Firebase authentication
│   └── DesignSystem.swift        # Colors, typography, shared modifiers
├── GymTrackerWidget/             # Widget extension + Live Activity UI
├── GymTrackerTests/
└── GymTrackerUITests/
```

---

## Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ device or simulator
- Apple Developer account (for HealthKit and Live Activities entitlements)
- Firebase project with Firestore and Google Sign-In enabled

### 1. Clone

```bash
git clone https://github.com/shurinbergo3/GymTracker.git
cd GymTracker
open "Body Forge.xcodeproj"
```

### 2. Configure Firebase

Add your `GoogleService-Info.plist` from the Firebase console into the `GymTracker/GymTracker/` target folder. The file is git-ignored and required for auth and sync to function.

### 3. Signing

In Xcode, select your development team for both the **GymTracker** and **GymTrackerWidget** targets under *Signing & Capabilities*.

### 4. Run

Select an **iPhone 15 Pro** or **iPhone 16 Pro** simulator (or a real device) to test Dynamic Island.

```
Cmd + R
```

---

## Requirements

- iOS 17.0+
- Xcode 15.0+

---

## License

MIT

---

*Developed by Antigravity*
