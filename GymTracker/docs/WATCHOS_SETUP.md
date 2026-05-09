# Adding the watchOS target to Body Forge

The Swift sources for the watch app already live in
`GymTracker/BodyForgeWatch Watch App/`. They will compile as soon as the
target exists in `Body Forge.xcodeproj`. Editing `project.pbxproj` by hand to
add a watchOS target is fragile — Xcode generates a fair bit of boilerplate
(Watch product bundle, embed-watch-content build phase, watch entitlements,
provisioning) that's easy to corrupt. So do this through the Xcode UI:

## 1. Add the target

1. Open `Body Forge.xcodeproj` in Xcode.
2. **File → New → Target…**
3. Pick the **watchOS** tab → **App** → **Next**.
4. Fill in:
   - **Product Name:** `BodyForgeWatch`
   - **Team:** same Apple ID as the iOS app
   - **Organization Identifier:** same as the iOS app
   - **Bundle Identifier:** `<iOS-bundle-id>.watchkitapp`
     (e.g. `com.antigravity.bodyforge.watchkitapp`)
   - **Interface:** SwiftUI
   - **Storage:** None
   - **Language:** Swift
   - **Project:** Body Forge
   - **Embed in Companion Application:** Body Forge
5. Click **Finish**. Confirm scheme creation if prompted.

Xcode now creates a folder like `BodyForgeWatch Watch App/` with template
sources (`BodyForgeWatchApp.swift`, `ContentView.swift`, `Assets.xcassets`,
`Info.plist`).

## 2. Replace the template sources with ours

We've shipped real sources next to the generated folder. Apply them:

1. Delete the auto-generated `ContentView.swift` and `BodyForgeWatchApp.swift`
   from the new target (move to trash).
2. In Finder, copy/move our pre-built files into the target's folder so they
   replace the generated ones:
   - `BodyForgeWatchApp.swift`
   - `WatchWorkoutModel.swift`
   - `WatchRootView.swift`
   - `Info.plist` (replace the generated one)
3. Drag the three Swift files into the Watch App group in Xcode's project
   navigator and tick the **BodyForgeWatch Watch App** target.

> If Xcode created the watchOS folder name with different spacing
> (e.g. `BodyForgeWatch Watch App`), keep our pre-built folder name aligned
> with whatever Xcode used and only **copy the Swift files into it**.

## 3. Verify capabilities

Both iOS and watch targets must have **Background Modes** with at least one
mode enabled (or, simpler, none — `WCSession.updateApplicationContext`
delivers in the background regardless). No special capability is required for
the bridge to work, but check:

- Both targets share the same **Team**.
- Both bundle IDs follow the `<parent>.watchkitapp` convention.
- The watch target's `Info.plist` has `WKApplication = YES` (already set in
  our copy) — this is the SwiftUI-only watchOS app marker.

## 4. Run

1. Pair an Apple Watch with the iPhone (or use a paired Watch simulator).
2. Build and run the **Body Forge** scheme on iPhone — the watch app
   auto-installs in the background.
3. Switch the active scheme to **BodyForgeWatch Watch App** and run on the
   watch (or just open the app on the watch directly).
4. Start a workout on the iPhone — the watch should switch to the active
   workout view within ~1 second:
   - exercise name
   - set X / Y
   - heart rate, calories
   - rest timer countdown when the iPhone-side rest timer runs
5. The watch fires its own haptic when the rest timer hits zero.

## 5. Troubleshooting

- **Watch shows the idle screen:** confirm `WCSession.isPaired` and
  `isWatchAppInstalled` are true on the iPhone side. Rebuild the iOS app
  after pairing.
- **State desync after the watch app sleeps:** `updateApplicationContext`
  always replays the most recent payload at activation, so opening the watch
  app should refresh within a frame. If not, check that the iOS app calls
  `WatchSyncBridge.shared.activate()` once at launch — it's wired in
  `WorkoutTrackerApp.init()`.
- **Rest haptic fires twice:** the watch dedupes by exact `restEndsAt`. If
  the iOS side restarts a rest with a slightly different end timestamp the
  haptic will replay — that's by design.

## 6. App Store description

Once the target is shipped, the App Store text is now accurate as written:
- Dynamic Island + lock screen show the active exercise and rest countdown.
- Rest end fires haptics on iPhone and the paired Apple Watch (no audio).
- Apple Watch mirrors the workout: exercise, set progress, heart rate, rest
  timer.
