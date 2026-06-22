import Foundation
import StoreKit
import UIKit

/// Triggers the native App Store review sheet at emotional peaks - right after
/// a finished workout, and harder on a workout where the user hit a new PR.
/// Heavily self-throttled on top of Apple's own 3-per-year cap so we never
/// nag: once per app version, and never twice inside a month.
@MainActor
final class ReviewRequestManager {
    static let shared = ReviewRequestManager()
    private init() {}

    private let defaults = UserDefaults.standard

    /// Numeric App Store ID for Body Forge (com.alex.GymTracker2026).
    static let appStoreID = "6761138589"

    /// Deep link that opens the "Write a Review" screen straight away. The
    /// storefront is resolved from the user's Apple ID, so this one URL works
    /// in every country — no per-region links needed.
    static var writeReviewURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!
    }

    /// Opens the App Store review page — used by the manual "Rate app" row in
    /// Settings (unlike the auto prompt, this always navigates).
    func openWriteReviewPage() {
        UIApplication.shared.open(Self.writeReviewURL)
    }

    private enum Keys {
        static let completedCount = "review_completedWorkoutCount"
        static let lastVersion = "review_lastPromptedVersion"
        static let lastDate = "review_lastPromptDate"
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    private let minDaysBetweenPrompts: TimeInterval = 30 * 24 * 60 * 60

    /// Called from `WorkoutManager.finishWorkout()` once a session is saved.
    /// `hadPR` is true if any set in the session beat the all-time best.
    func registerWorkoutCompleted(hadPR: Bool) {
        let count = defaults.integer(forKey: Keys.completedCount) + 1
        defaults.set(count, forKey: Keys.completedCount)

        // A PR is the strongest emotional peak - ask right away (still gated).
        // Otherwise wait for the 3rd/5th workout, then occasionally after.
        let milestone = count == 3 || count == 5 || (count > 5 && count % 10 == 0)
        guard hadPR || milestone else { return }

        requestReviewIfAllowed()
    }

    private func requestReviewIfAllowed() {
        // One ask per shipped version - matches how the prompt actually behaves.
        guard defaults.string(forKey: Keys.lastVersion) != appVersion else { return }

        if let last = defaults.object(forKey: Keys.lastDate) as? Date,
           Date().timeIntervalSince(last) < minDaysBetweenPrompts {
            return
        }

        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }

        // Small delay so the summary screen settles before the sheet appears.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            AppStore.requestReview(in: scene)
        }

        defaults.set(appVersion, forKey: Keys.lastVersion)
        defaults.set(Date(), forKey: Keys.lastDate)
    }
}
