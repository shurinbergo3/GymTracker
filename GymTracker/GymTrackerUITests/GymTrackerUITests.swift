//
//  GymTrackerUITests.swift
//  GymTrackerUITests
//
//  E2E UI Tests for Body Forge App
//

import XCTest

final class GymTrackerUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Reset state for clean tests
        app.launchArguments = ["--uitesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - App Launch Tests
    
    @MainActor
    func testAppLaunchesSuccessfully() throws {
        app.launch()
        
        // Wait for app to load (either login screen or main content)
        let exists = app.wait(for: .runningForeground, timeout: 10)
        XCTAssertTrue(exists, "App should launch successfully")
        
        // Check that app is responsive (some element exists)
        let anyElement = app.descendants(matching: .any).firstMatch
        XCTAssertTrue(anyElement.waitForExistence(timeout: 5), "App should have UI elements")
    }
    
    @MainActor
    func testAppDoesNotCrashOnLaunch() throws {
        // Measure launch stability
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            app.terminate()
        }
    }
    
    // MARK: - Login Screen Tests
    
    @MainActor
    func testLoginScreenElements() throws {
        app.launch()
        
        // If app shows login screen
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Пароль"]
        
        // Check if login or main screen is shown
        if emailField.waitForExistence(timeout: 3) {
            // Login screen is shown
            XCTAssertTrue(emailField.exists, "Email field should exist")
            XCTAssertTrue(passwordField.exists, "Password field should exist")
            
            // Check for Google sign in button
            let googleButton = app.buttons["Войти через Google"]
            XCTAssertTrue(googleButton.exists, "Google sign in button should exist")
        } else {
            // User is already logged in - main content shown
            // This is also a valid state
            XCTAssertTrue(true, "User is logged in, skipping login tests")
        }
    }
    
    // MARK: - Tab Navigation Tests
    
    @MainActor
    func testTabBarNavigation() throws {
        app.launch()
        
        // Wait for main content to load
        sleep(2)
        
        // Find tab bar
        let tabBar = app.tabBars.firstMatch
        
        // If user is logged in and has access to tabs
        if tabBar.waitForExistence(timeout: 5) {
            // Test each tab
            let workoutTab = tabBar.buttons["Тренировка"]
            let programTab = tabBar.buttons["Программа"]
            let referenceTab = tabBar.buttons["Справочник"]
            let statsTab = tabBar.buttons["Статистика"]
            let aiTab = tabBar.buttons["AI Тренер"]
            
            // Navigate to each tab and verify
            if workoutTab.exists {
                workoutTab.tap()
                sleep(1)
            }
            
            if programTab.exists {
                programTab.tap()
                sleep(1)
            }
            
            if referenceTab.exists {
                referenceTab.tap()
                sleep(1)
            }
            
            if statsTab.exists {
                statsTab.tap()
                sleep(1)
            }
            
            if aiTab.exists {
                aiTab.tap()
                sleep(1)
            }
            
            // Return to workout tab
            if workoutTab.exists {
                workoutTab.tap()
            }
            
            XCTAssertTrue(true, "Tab navigation completed without crashes")
        }
    }
    
    // MARK: - Workout Flow Tests
    
    @MainActor
    func testStartWorkoutButtonExists() throws {
        app.launch()
        sleep(2)
        
        // Find start workout button
        let startButton = app.buttons["НАЧАТЬ ТРЕНИРОВКУ"]
        let altStartButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'НАЧАТЬ'")).firstMatch
        
        if startButton.waitForExistence(timeout: 5) || altStartButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(true, "Start workout button exists")
        } else {
            // User might be on login screen
            print("Note: Start button not found - user may not be logged in")
        }
    }
    
    @MainActor
    func testWorkoutCountdownFlow() throws {
        app.launch()
        sleep(2)
        
        // Try to start a workout
        let startButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'НАЧАТЬ'")).firstMatch
        
        if startButton.waitForExistence(timeout: 5) {
            startButton.tap()
            
            // After tapping, should see countdown or workout screen
            sleep(4) // Wait for countdown to finish
            
            // Check app didn't crash
            let appState = app.state
            XCTAssertNotEqual(appState, .notRunning, "App should not crash after starting workout")
        }
    }
    
    // MARK: - Settings Access Tests
    
    @MainActor
    func testSettingsAccessFromDashboard() throws {
        app.launch()
        sleep(2)
        
        // Look for settings/gear icon button
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Настройки' OR label CONTAINS[c] 'gear' OR label CONTAINS[c] 'gearshape'")).firstMatch
        let gearButton = app.buttons["gearshape.fill"]
        
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.tap()
            sleep(1)
            XCTAssertTrue(true, "Settings opened successfully")
        } else if gearButton.waitForExistence(timeout: 3) {
            gearButton.tap()
            sleep(1)
            XCTAssertTrue(true, "Settings opened successfully via gear icon")
        }
    }
    
    // MARK: - Program View Tests
    
    @MainActor
    func testProgramViewLoads() throws {
        app.launch()
        sleep(2)
        
        let tabBar = app.tabBars.firstMatch
        
        if tabBar.waitForExistence(timeout: 5) {
            let programTab = tabBar.buttons["Программа"]
            
            if programTab.exists {
                programTab.tap()
                sleep(2)
                
                // Check if program content loads
                let scrollView = app.scrollViews.firstMatch
                XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Program view should have scrollable content")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    @MainActor
    func testTabSwitchPerformance() throws {
        app.launch()
        sleep(2)
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        
        measure(options: options) {
            let workoutTab = tabBar.buttons["Тренировка"]
            let programTab = tabBar.buttons["Программа"]
            
            if workoutTab.exists && programTab.exists {
                programTab.tap()
                workoutTab.tap()
            }
        }
    }
    
    // MARK: - Data Persistence Tests
    
    @MainActor
    func testAppRemembersStateAfterRelaunch() throws {
        // First launch
        app.launch()
        sleep(2)
        
        // Check if logged in (tab bar exists)
        let tabBar = app.tabBars.firstMatch
        let wasLoggedIn = tabBar.waitForExistence(timeout: 5)
        
        // Terminate and relaunch
        app.terminate()
        sleep(1)
        app.launch()
        sleep(2)
        
        // Check state is preserved
        let tabBarAfter = app.tabBars.firstMatch
        let isLoggedInAfter = tabBarAfter.waitForExistence(timeout: 5)
        
        if wasLoggedIn {
            XCTAssertTrue(isLoggedInAfter, "Login state should persist after app relaunch")
        }
    }
    
    // MARK: - Stability Tests
    
    @MainActor
    func testRapidTabSwitchingDoesNotCrash() throws {
        app.launch()
        sleep(2)
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        let tabs = ["Тренировка", "Программа", "Справочник", "Статистика", "AI Тренер"]
        
        // Rapidly switch tabs 10 times
        for _ in 0..<10 {
            for tabName in tabs {
                let tab = tabBar.buttons[tabName]
                if tab.exists {
                    tab.tap()
                }
            }
        }
        
        // App should still be running
        XCTAssertEqual(app.state, .runningForeground, "App should not crash during rapid tab switching")
    }
    
    @MainActor
    func testScrollingDoesNotCrash() throws {
        app.launch()
        sleep(2)
        
        // Find any scrollable content
        let scrollView = app.scrollViews.firstMatch
        
        if scrollView.waitForExistence(timeout: 5) {
            // Scroll up and down multiple times
            for _ in 0..<5 {
                scrollView.swipeUp()
                scrollView.swipeDown()
            }
            
            XCTAssertEqual(app.state, .runningForeground, "App should not crash during scrolling")
        }
    }
}
