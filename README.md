# Body Forge

**Body Forge** is a modern iOS fitness tracking app built for serious athletes. It combines intelligent workout logging, real-time biometric data from Apple Health, and a clean Bento Grid UI to keep you focused on performance.

## Features

### Workout Tracking
- Create and manage workout programs with custom days and exercise splits
- Log sets, reps, weight, and rest time with live comparison to your previous session
- Superset support and multiple workout types: Strength, Cardio, Circuit
- Built-in exercise technique reference library

### HealthKit Integration
- Real-time heart rate and active calorie display during workouts
- Activity rings closure synced with Apple Watch
- Step count and sleep data tracking

### Live Activities & Dynamic Island
- Rest timer and workout status visible on the Lock Screen and Dynamic Island while the app is backgrounded

### Analytics & Progress
- Strength progress charts per exercise with trend indicators
- Body measurements tracker with visual progress over time
- Weight tracking with history graph
- Workout volume and session comparison

### Nutrition & Supplements
- Calorie calculator with macro guidance
- Nutrition guide and supplement tracker with detailed views

### AI Trainer
- In-app AI coaching view for workout advice and guidance

### Authentication & Sync
- Google Sign-In via Firebase Authentication
- Cloud sync with Firestore
- Local persistence with SwiftData

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9+ |
| UI | SwiftUI |
| Architecture | MVVM |
| Local Storage | SwiftData |
| Health Data | HealthKit |
| Live Activities | ActivityKit |
| Charts | Swift Charts |
| Backend | Firebase Firestore + Auth |
| Async | Swift Concurrency (`async/await`, `@MainActor`) |
| Localization | String Catalogs (`.xcstrings`) |

## Project Structure

```
GymTracker/
├── GymTracker/
│   ├── Models/               # SwiftData & domain models
│   ├── Services/             # AnalyticsService, SleepService, CalorieCalculator
│   ├── Protocols/            # Shared protocols
│   ├── DI/                   # Dependency injection
│   ├── *View.swift           # SwiftUI screens and components
│   ├── *ViewModel.swift      # View-specific logic
│   ├── *Manager.swift        # Singletons: HealthManager, WorkoutManager, LiveActivityManager, SyncManager, AuthManager
│   └── DesignSystem.swift    # Colors, fonts, reusable modifiers
├── GymTrackerWidget/         # Widget + Live Activity target
├── GymTrackerTests/
└── GymTrackerUITests/
```

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Getting Started

```bash
git clone https://github.com/shurinbergo3/GymTracker.git
cd GymTracker
open "Body Forge.xcodeproj"
```

1. Select your development team in the **GymTracker** and **GymTrackerWidget** target signing settings.
2. Add your own `GoogleService-Info.plist` from the Firebase console.
3. Run on an iPhone 15 Pro / 16 Pro simulator or a real device to test Dynamic Island.
4. Press `Cmd + R`.

## License

MIT — see [LICENSE](LICENSE).

---

*Developed by Antigravity*
