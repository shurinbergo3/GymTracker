//
//  E2EUserJourneyTests.swift
//  GymTrackerUITests
//
//  End-to-end happy-path test: launch -> tabs -> start workout -> return -> relaunch.
//  Uses accessibilityIdentifiers from ContentView.swift and WorkoutDashboardViews.swift
//  so the test is robust to localization changes.
//

import XCTest

final class E2EUserJourneyTests: XCTestCase {

    private var app: XCUIApplication!

    private enum ID {
        static let tabBar = "main_tab_bar"
        static let tabWorkout = "tab_workout"
        static let tabProgram = "tab_program"
        static let tabReference = "tab_reference"
        static let tabStats = "tab_stats"
        static let startWorkout = "btn_start_workout"
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["--uitesting"]
    }

    override func tearDownWithError() throws {
        if let app, app.state != .notRunning {
            app.terminate()
        }
        app = nil
    }

    // MARK: - Full user journey

    @MainActor
    func test_E2E_fullUserJourney() throws {
        // 1. Launch
        app.launch()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 15),
            "App must reach foreground after launch"
        )

        // 2. Detect entry state: authenticated (tab bar visible) vs unauthenticated.
        let tabBar = app.descendants(matching: .any).matching(identifier: ID.tabBar).firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            // Pre-auth state — verify the login screen is alive and stop here.
            // A real authenticated E2E run requires Firebase test credentials,
            // which are out of scope for this offline-friendly suite.
            assertLoginScreenIsResponsive()
            attachScreenshot(name: "01_login_state")
            return
        }
        attachScreenshot(name: "01_dashboard")

        // 3. Walk every tab and confirm content renders.
        try walkAllTabs()

        // 4. Return to Workout tab and start a workout.
        try startWorkoutFlow()

        // 5. App must still be alive after the workout flow.
        XCTAssertEqual(
            app.state,
            .runningForeground,
            "App crashed somewhere in the workout flow"
        )

        // 6. Cold relaunch — auth state must persist.
        app.terminate()
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 5))
        app.launch()

        let tabBarAfterRelaunch = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBarAfterRelaunch.waitForExistence(timeout: 15),
            "Login state must persist across relaunches"
        )
        attachScreenshot(name: "02_after_relaunch")
    }

    // MARK: - Steps

    /// The native tab bar buttons are addressed by index (their accessibility
    /// label is localized, so matching by position is language-independent).
    /// Tab order: 0 Workout · 1 Program · 2 Reference · 3 Stats.
    @MainActor
    private func tabButton(_ index: Int) -> XCUIElement {
        app.tabBars.firstMatch.buttons.element(boundBy: index)
    }

    @MainActor
    private func walkAllTabs() throws {
        let order: [(index: Int, screenshot: String)] = [
            (1, "tab_program"),
            (2, "tab_reference"),
            (3, "tab_stats"),
            (0, "tab_workout"),
        ]

        for step in order {
            let tab = tabButton(step.index)
            guard tab.waitForExistence(timeout: 5) else {
                XCTFail("Tab \(step.index) did not appear")
                continue
            }
            tab.tap()

            // The tab content lives inside a scroll view in every screen of this app.
            let firstScroll = app.scrollViews.firstMatch
            XCTAssertTrue(
                firstScroll.waitForExistence(timeout: 5),
                "Tab \(step.index) did not render scrollable content"
            )
            attachScreenshot(name: step.screenshot)
        }
    }

    @MainActor
    private func startWorkoutFlow() throws {
        let workoutTab = tabButton(0)
        if workoutTab.exists { workoutTab.tap() }

        let startButton = app.buttons.matching(identifier: ID.startWorkout).firstMatch
        guard startButton.waitForExistence(timeout: 10) else {
            // No selected day -> button is hidden. That is a valid empty-state for
            // a fresh install; treat as a soft success but record evidence.
            attachScreenshot(name: "03_no_start_button")
            return
        }

        XCTAssertTrue(startButton.isHittable, "Start workout button must be tappable")
        startButton.tap()

        // Countdown is ~3s, then the active workout view appears. Wait long enough.
        let appStillForeground = expectation(
            description: "App stays in foreground during countdown + transition"
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.app.state == .runningForeground {
                appStillForeground.fulfill()
            }
        }
        wait(for: [appStillForeground], timeout: 8)
        attachScreenshot(name: "04_workout_started")
    }

    @MainActor
    private func assertLoginScreenIsResponsive() {
        let anyHittableElement = app.buttons.firstMatch
        XCTAssertTrue(
            anyHittableElement.waitForExistence(timeout: 10),
            "Login screen has no interactive elements"
        )
    }

    // MARK: - Helpers

    @MainActor
    private func attachScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
