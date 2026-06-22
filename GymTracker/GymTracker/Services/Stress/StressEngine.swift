//
//  StressEngine.swift
//  GymTracker
//
//  A personalised daily stress / recovery index built from the autonomic
//  signals HealthKit actually exposes — HRV (SDNN), resting heart rate, sleep
//  duration and (when available) respiratory rate.
//
//  Apple Watch never reports "stress" directly and, unlike Garmin, doesn't
//  expose a continuous beat-to-beat stream, so a true all-day curve is
//  impossible. What IS sound — and what apps like Harvee/Welltory do — is a
//  per-day score that compares each signal to the user's OWN 30-day baseline
//  (a z-score), not to fixed population thresholds. Higher score = more strain.
//

import SwiftUI

// MARK: - Band

/// Semantic + visual band for a stress score (0–100, higher = more stress).
enum StressBand: Int, CaseIterable, Identifiable {
    case calm, balanced, elevated, high
    var id: Int { rawValue }

    static func forScore(_ score: Int) -> StressBand {
        switch score {
        case ..<25: return .calm
        case ..<50: return .balanced
        case ..<75: return .elevated
        default:    return .high
        }
    }

    var title: String {
        switch self {
        case .calm:     return "Спокойствие".localized()
        case .balanced: return "Баланс".localized()
        case .elevated: return "Повышенный".localized()
        case .high:     return "Высокий".localized()
        }
    }

    /// Stable English tag fed to the AI prompt (never localised).
    var promptTag: String {
        switch self {
        case .calm:     return "calm"
        case .balanced: return "balanced"
        case .elevated: return "elevated"
        case .high:     return "high"
        }
    }

    var color: Color {
        switch self {
        case .calm:     return Color(red: 0.36, green: 0.84, blue: 0.55)  // green
        case .balanced: return Color(red: 0.86, green: 0.82, blue: 0.30)  // yellow
        case .elevated: return Color(red: 1.0,  green: 0.60, blue: 0.20)  // orange
        case .high:     return Color(red: 1.0,  green: 0.36, blue: 0.42)  // red
        }
    }
}

// MARK: - Driver

/// One signal's contribution to a day's score. `z` is signed so that a
/// positive value always pushes stress UP, regardless of the metric.
struct StressDriver: Identifiable {
    enum Metric { case hrv, rhr, sleep, respiratory }
    let metric: Metric
    let z: Double

    var id: String { String(describing: metric) }
    var raisesStress: Bool { z > 0 }

    /// True when the measured value sits below the personal norm (independent
    /// of whether that raises or lowers stress).
    var measuredBelowNorm: Bool {
        switch metric {
        case .hrv, .sleep:        return z > 0   // less HRV / less sleep
        case .rhr, .respiratory:  return z < 0   // lower HR / slower breathing
        }
    }

    var metricName: String {
        switch metric {
        case .hrv:         return "ВРС".localized()
        case .rhr:         return "Пульс покоя".localized()
        case .sleep:       return "Сон".localized()
        case .respiratory: return "Дыхание".localized()
        }
    }

    var relationText: String {
        measuredBelowNorm ? "ниже нормы".localized() : "выше нормы".localized()
    }

    /// Stable English phrase for the AI prompt.
    var promptPhrase: String {
        let name: String
        switch metric {
        case .hrv:         name = "HRV"
        case .rhr:         name = "resting HR"
        case .sleep:       name = "sleep"
        case .respiratory: name = "breathing rate"
        }
        return "\(name) \(measuredBelowNorm ? "below" : "above") norm"
    }
}

// MARK: - Per-day score

struct DailyStressScore: Identifiable {
    enum Confidence { case high, low }
    let date: Date
    let score: Int
    let confidence: Confidence
    let drivers: [StressDriver]   // strongest first

    var band: StressBand { StressBand.forScore(score) }
    var id: Date { date }

    /// Drivers worth surfacing in the UI / prompt (filters out noise).
    var significantDrivers: [StressDriver] {
        drivers.filter { abs($0.z) >= 0.4 }
    }
}

// MARK: - Report

struct StressReport {
    let daily: [DailyStressScore]   // chronological; only days that had data
    let latest: DailyStressScore?
    let monthAverage: Int?
    let trend: Trend
    /// True once the baseline is solid enough to trust the numbers.
    let hasData: Bool

    /// Most recent day we can show with confidence — the headline reading.
    var headline: DailyStressScore? { daily.last { $0.confidence == .high } }

    enum Trend {
        case rising, falling, steady, unknown
        var promptTag: String {
            switch self {
            case .rising:  return "rising"
            case .falling: return "falling"
            case .steady:  return "steady"
            case .unknown: return "unknown"
            }
        }
    }

    init(daily: [DailyStressScore]) {
        self.daily = daily
        self.latest = daily.last
        let confident = daily.filter { $0.confidence == .high }
        self.hasData = !confident.isEmpty
        if confident.isEmpty {
            self.monthAverage = nil
            self.trend = .unknown
        } else {
            self.monthAverage = confident.reduce(0) { $0 + $1.score } / confident.count
            self.trend = StressReport.computeTrend(confident)
        }
    }

    static let empty = StressReport(daily: [])

    private static func computeTrend(_ days: [DailyStressScore]) -> Trend {
        guard days.count >= 6 else { return .steady }
        let sorted = days.sorted { $0.date < $1.date }
        let cut = max(1, sorted.count / 3)
        let recent = Array(sorted.suffix(cut))
        let earlier = Array(sorted.prefix(sorted.count - cut))
        guard !earlier.isEmpty else { return .steady }
        let recentAvg = Double(recent.reduce(0) { $0 + $1.score }) / Double(recent.count)
        let earlierAvg = Double(earlier.reduce(0) { $0 + $1.score }) / Double(earlier.count)
        let delta = recentAvg - earlierAvg
        if delta >= 6 { return .rising }
        if delta <= -6 { return .falling }
        return .steady
    }
}

// MARK: - Engine

enum StressEngine {

    struct Inputs {
        var hrv: [DailyHealthValue] = []
        var rhr: [DailyHealthValue] = []
        var sleepHours: [DailyHealthValue] = []
        var respiratory: [DailyHealthValue] = []
    }

    private struct Baseline {
        let mean: Double
        let sd: Double
        let n: Int
    }

    /// Relative weights, re-normalised over whichever signals are present.
    private static let weights: [StressDriver.Metric: Double] = [
        .hrv: 0.45, .rhr: 0.25, .sleep: 0.20, .respiratory: 0.10
    ]
    /// Days of baseline needed before a score is treated as trustworthy.
    static let minBaselineDays = 10
    /// z → points. ±2.7 SD spans roughly the full 0…100 range around 50.
    private static let scoreSlope = 18.0

    static func compute(inputs: Inputs, calendar: Calendar = .current) -> StressReport {
        let bHRV = baseline(inputs.hrv)
        let bRHR = baseline(inputs.rhr)
        let bSleep = baseline(inputs.sleepHours)
        let bResp = baseline(inputs.respiratory)

        func indexed(_ values: [DailyHealthValue]) -> [Date: Double] {
            var map: [Date: Double] = [:]
            for v in values where v.value > 0 { map[calendar.startOfDay(for: v.date)] = v.value }
            return map
        }
        let iHRV = indexed(inputs.hrv)
        let iRHR = indexed(inputs.rhr)
        let iSleep = indexed(inputs.sleepHours)
        let iResp = indexed(inputs.respiratory)

        let baselineDays = max(bHRV?.n ?? 0, bRHR?.n ?? 0, bSleep?.n ?? 0)
        let confidentBaseline = baselineDays >= minBaselineDays

        let allDays = Set(iHRV.keys)
            .union(iRHR.keys).union(iSleep.keys).union(iResp.keys)

        var daily: [DailyStressScore] = []
        for day in allDays.sorted() {
            var drivers: [StressDriver] = []
            var weightedZ = 0.0
            var totalWeight = 0.0

            func add(_ metric: StressDriver.Metric, _ z: Double) {
                let w = weights[metric] ?? 0
                drivers.append(StressDriver(metric: metric, z: z))
                weightedZ += z * w
                totalWeight += w
            }

            if let v = iHRV[day], let b = bHRV   { add(.hrv,   clampZ((b.mean - v) / b.sd)) }
            if let v = iRHR[day], let b = bRHR   { add(.rhr,   clampZ((v - b.mean) / b.sd)) }
            if let v = iSleep[day], let b = bSleep { add(.sleep, clampZ((b.mean - v) / b.sd)) }
            if let v = iResp[day], let b = bResp { add(.respiratory, clampZ((v - b.mean) / b.sd)) }

            guard totalWeight > 0 else { continue }
            let z = weightedZ / totalWeight
            let score = min(100, max(0, Int((50.0 + scoreSlope * z).rounded())))

            // A score is only "high confidence" with a real baseline AND a
            // primary autonomic signal (HRV or RHR) that day — sleep alone is
            // too weak to call stress.
            let hasPrimary = iHRV[day] != nil || iRHR[day] != nil
            let confidence: DailyStressScore.Confidence =
                (confidentBaseline && hasPrimary) ? .high : .low

            daily.append(DailyStressScore(
                date: day,
                score: score,
                confidence: confidence,
                drivers: drivers.sorted { abs($0.z) > abs($1.z) }
            ))
        }

        return StressReport(daily: daily)
    }

    // MARK: - Helpers

    private static func baseline(_ values: [DailyHealthValue]) -> Baseline? {
        let xs = values.map { $0.value }.filter { $0 > 0 }
        guard !xs.isEmpty else { return nil }
        let mean = xs.reduce(0, +) / Double(xs.count)
        let variance = xs.count > 1
            ? xs.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(xs.count - 1)
            : 0
        // Floor SD so a tight baseline can't blow z out of proportion and a
        // single-sample baseline still yields a finite, sane z.
        let sd = max(variance.squareRoot(), mean * 0.04, 0.0001)
        return Baseline(mean: mean, sd: sd, n: xs.count)
    }

    private static func clampZ(_ z: Double) -> Double { min(max(z, -3.0), 3.0) }
}
