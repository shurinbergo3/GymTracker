//
//  Gamification.swift
//  GymTracker
//
//  Unified XP / level / form-state math. Models physiological detraining:
//  XP within the current level can decay during inactivity, but the level
//  itself is permanent ("hard-earned, locked in"). Based on detraining science:
//  meaningful adaptation loss starts after ~3-7 days of full inactivity.
//

import SwiftUI

// MARK: - Form state

enum FormState {
    case peak        // 0-2 days since last workout
    case stable      // 3-7 days
    case warning     // 8-14 days
    case declining   // 15+ days

    var title: String {
        switch self {
        case .peak:      return "На пике".localized()
        case .stable:    return "Стабильно".localized()
        case .warning:   return "Пора размяться".localized()
        case .declining: return "Время вернуться".localized()
        }
    }

    var subtitle: String {
        switch self {
        case .peak:      return "Свежая мышечная адаптация".localized()
        case .stable:    return "Удерживаешь форму".localized()
        case .warning:   return "Мышцы соскучились по нагрузке".localized()
        case .declining: return "Тело отдохнуло — готово к работе".localized()
        }
    }

    var color: Color {
        switch self {
        case .peak:      return DesignSystem.Colors.neonGreen
        case .stable:    return Color(red: 1.0, green: 0.82, blue: 0.20)
        case .warning:   return .orange
        case .declining: return Color(red: 1.0, green: 0.60, blue: 0.25) // warm amber — invite, not alarm
        }
    }

    var icon: String {
        switch self {
        case .peak:      return "bolt.heart.fill"
        case .stable:    return "heart.fill"
        case .warning:   return "heart.fill"
        case .declining: return "bolt.heart.fill"
        }
    }

    /// 0…1 health bar fill — visual representation of current form.
    var fillFraction: Double {
        switch self {
        case .peak:      return 1.00
        case .stable:    return 0.72
        case .warning:   return 0.40
        case .declining: return 0.15
        }
    }
}

// MARK: - Calculator

enum GamificationCalculator {

    /// XP needed to advance to the next level.
    static let xpPerLevel: Int = 5

    /// Days of inactivity after which decay kicks in.
    private static let graceDays: Int = 3

    // MARK: Days since last workout

    static func daysSinceLastWorkout(from lastWorkoutDate: Date?) -> Int? {
        guard let last = lastWorkoutDate else { return nil }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: Date())).day ?? 0
        return max(0, days)
    }

    // MARK: Level / XP — peak (trophy) vs effective (current)

    /// Peak/trophy level — calculated from totalWorkouts, **never decays**.
    /// Displayed as "Был: УРОВЕНЬ X" badge when current level dropped below.
    static func peakLevel(totalWorkouts: Int) -> Int {
        max(1, totalWorkouts / xpPerLevel + 1)
    }

    /// Raw XP within peak level (0..<5).
    static func rawXPInLevel(totalWorkouts: Int) -> Int {
        max(0, totalWorkouts % xpPerLevel)
    }

    /// XP loss from inactivity — intentionally DISABLED.
    ///
    /// Decay punished returning users (the "all is lost" effect) and leaned on
    /// guilt-driven motivation instead of the durable competence/progress drivers
    /// we want. Levels now only grow — what you earn stays yours. Kept as a no-op
    /// so existing callers (effectiveTotalXP / currentLevel / visibleDecay /
    /// hasLostLevels) keep compiling and simply resolve to "no decay", which makes
    /// every decay chip / "level at risk" message disappear without touching the
    /// many view call-sites.
    static func decay(daysSinceLastWorkout days: Int?) -> Double {
        return 0
    }

    /// Effective total XP after decay — drives current level. Floor at 0.
    static func effectiveTotalXP(totalWorkouts: Int, daysSinceLastWorkout days: Int?) -> Double {
        let lost = decay(daysSinceLastWorkout: days)
        return max(0, Double(totalWorkouts) - lost)
    }

    /// Current (decayed) level — can drop. Floor at level 1.
    static func currentLevel(totalWorkouts: Int, daysSinceLastWorkout days: Int?) -> Int {
        let effective = effectiveTotalXP(totalWorkouts: totalWorkouts, daysSinceLastWorkout: days)
        return max(1, Int(effective / Double(xpPerLevel)) + 1)
    }

    /// True if the user has lost levels — used to decide whether to show the trophy badge.
    static func hasLostLevels(totalWorkouts: Int, daysSinceLastWorkout days: Int?) -> Bool {
        peakLevel(totalWorkouts: totalWorkouts) > currentLevel(totalWorkouts: totalWorkouts, daysSinceLastWorkout: days)
    }

    /// Effective XP within the **current** level (0…5), continuous.
    static func effectiveXPInLevel(totalWorkouts: Int, daysSinceLastWorkout days: Int?) -> Double {
        let effective = effectiveTotalXP(totalWorkouts: totalWorkouts, daysSinceLastWorkout: days)
        let lvl = currentLevel(totalWorkouts: totalWorkouts, daysSinceLastWorkout: days)
        let levelFloor = Double((lvl - 1) * xpPerLevel)
        return max(0, effective - levelFloor)
    }

    /// Total XP visibly lost — for the chip "−2.5 XP".
    static func visibleDecay(totalWorkouts: Int, daysSinceLastWorkout days: Int?) -> Double {
        let lost = decay(daysSinceLastWorkout: days)
        return min(Double(totalWorkouts), lost)
    }

    /// XP-bar progress 0…1 within the current (decayed) level.
    static func xpProgress(totalWorkouts: Int, daysSinceLastWorkout days: Int?) -> Double {
        effectiveXPInLevel(totalWorkouts: totalWorkouts, daysSinceLastWorkout: days) / Double(xpPerLevel)
    }

    /// Days remaining until the user crosses into the next decay phase
    /// (peak→stable, stable→warning, warning→declining). Used for warnings.
    static func daysUntilNextPhase(daysSinceLastWorkout days: Int?) -> Int? {
        guard let d = days else { return nil }
        switch d {
        case 0..<graceDays: return graceDays - d           // until decay starts
        case graceDays..<8: return 8 - d                   // until warning
        case 8..<15:        return 15 - d                  // until declining
        default:            return nil                     // already declining
        }
    }

    // MARK: Form state

    static func formState(daysSinceLastWorkout days: Int?) -> FormState {
        guard let d = days else { return .peak }
        switch d {
        case 0..<graceDays: return .peak
        case graceDays..<8: return .stable
        case 8..<15:        return .warning
        default:            return .declining
        }
    }

    // MARK: Athlete title

    static func athleteTitle(for level: Int) -> String {
        switch level {
        case 1...2:   return "Новичок".localized()
        case 3...5:   return "Любитель".localized()
        case 6...10:  return "Атлет".localized()
        case 11...20: return "Профи".localized()
        default:      return "Легенда".localized()
        }
    }
}
