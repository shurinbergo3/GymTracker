//
//  StressService.swift
//  GymTracker
//
//  Pulls ~30 days of recovery signals from HealthKit + SleepService and runs
//  them through `StressEngine`. Computed live (a handful of fast daily-stat
//  queries) — no on-disk cache, so the number can never go stale behind the
//  user's actual Health data. The latest report is kept in memory so the AI
//  coach can reuse it within a session without re-querying.
//

import Foundation

@MainActor
final class StressService: ObservableObject {
    static let shared = StressService()
    private init() {}

    /// Last computed report (nil until first load). Reused by the AI builder.
    private(set) var lastReport: StressReport?

    @discardableResult
    func loadReport(days: Int = 30) async -> StressReport {
        guard HealthManager.shared.isAuthorized else {
            lastReport = .empty
            return .empty
        }

        async let hrv = HealthManager.shared.fetchDailyHRV(days: days)
        async let rhr = HealthManager.shared.fetchDailyRestingHR(days: days)
        async let resp = HealthManager.shared.fetchDailyRespiratoryRate(days: days)
        async let sleep = SleepService.shared.fetchSleepHistory(for: .month)

        let cal = Calendar.current
        let sleepHours = (await sleep)
            .filter { $0.totalDuration > 0 }
            .map { DailyHealthValue(date: cal.startOfDay(for: $0.date), value: $0.totalDuration / 3600) }

        let inputs = StressEngine.Inputs(
            hrv: await hrv,
            rhr: await rhr,
            sleepHours: sleepHours,
            respiratory: await resp
        )

        let report = StressEngine.compute(inputs: inputs)
        lastReport = report
        return report
    }
}
