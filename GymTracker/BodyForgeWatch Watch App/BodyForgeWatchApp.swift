//
//  BodyForgeWatchApp.swift
//  BodyForgeWatch Watch App
//
//  watchOS companion that mirrors the live workout state from the iPhone:
//  current exercise, set progress, rest timer countdown, and heart rate.
//

import SwiftUI

@main
struct BodyForgeWatch_Watch_AppApp: App {
    // One observable model owned by the app — picks up state via WCSession
    // and keeps the view tree reactive without sprinkling singletons around.
    @StateObject private var model = WatchWorkoutModel()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(model)
        }
    }
}
