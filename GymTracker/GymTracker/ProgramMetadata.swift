//
//  ProgramMetadata.swift
//  GymTracker
//
//  Categorization, level and visual metadata for programs.
//  Derived from program.name (raw key) without DB migration.
//

import SwiftUI

// MARK: - Program Category

enum ProgramCategory: String, CaseIterable, Identifiable {
    case all
    case massGain
    case strength
    case fatLoss
    case cardio
    case calisthenics
    case glutes
    case mobility

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:          return "Все".localized()
        case .massGain:     return "Масса".localized()
        case .strength:     return "Сила".localized()
        case .fatLoss:      return "Жиросжигание".localized()
        case .cardio:       return "Кардио".localized()
        case .calisthenics: return "Воркаут".localized()
        case .glutes:       return "Ягодицы".localized()
        case .mobility:     return "Мобильность".localized()
        }
    }

    var icon: String {
        switch self {
        case .all:          return "square.grid.2x2.fill"
        case .massGain:     return "figure.strengthtraining.traditional"
        case .strength:     return "dumbbell.fill"
        case .fatLoss:      return "flame.fill"
        case .cardio:       return "heart.fill"
        case .calisthenics: return "figure.gymnastics"
        case .glutes:       return "figure.cooldown"
        case .mobility:     return "figure.flexibility"
        }
    }

    var color: Color {
        switch self {
        case .all:          return DesignSystem.Colors.neonGreen
        case .massGain:     return Color(red: 0.40, green: 0.72, blue: 1.00) // blue
        case .strength:     return Color(red: 1.00, green: 0.45, blue: 0.30) // red-orange
        case .fatLoss:      return Color(red: 1.00, green: 0.60, blue: 0.20) // orange
        case .cardio:       return Color(red: 1.00, green: 0.30, blue: 0.50) // pink-red
        case .calisthenics: return Color(red: 0.60, green: 0.40, blue: 1.00) // purple
        case .glutes:       return Color(red: 1.00, green: 0.40, blue: 0.75) // pink
        case .mobility:     return Color.mint
        }
    }
}

// MARK: - Program Level

enum ProgramLevel: String, CaseIterable {
    case beginner
    case intermediate
    case advanced
    case any

    var displayName: String {
        switch self {
        case .beginner:     return "Новичок".localized()
        case .intermediate: return "Средний".localized()
        case .advanced:     return "Продвинутый".localized()
        case .any:          return "Любой".localized()
        }
    }

    var icon: String {
        switch self {
        case .beginner:     return "1.circle.fill"
        case .intermediate: return "2.circle.fill"
        case .advanced:     return "3.circle.fill"
        case .any:          return "star.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .beginner:     return Color.green
        case .intermediate: return Color.orange
        case .advanced:     return Color.red
        case .any:          return DesignSystem.Colors.neonGreen
        }
    }
}

// MARK: - Program Metadata

struct ProgramMetadata {
    let category: ProgramCategory
    let level: ProgramLevel
    let estimatedMinutes: Int
    /// Минимальный рекомендуемый стаж в месяцах. 0 = без опыта.
    let experienceMonths: Int

    /// Короткая подпись опыта: "0+", "6+ мес", "1.5+ года", "2+ года".
    var experienceLabel: String {
        switch experienceMonths {
        case 0:       return "Без опыта".localized()
        case 1..<12:  return String(format: "%d+ мес".localized(), experienceMonths)
        case 12:      return "1+ год".localized()
        case 13..<24:
            let years = Double(experienceMonths) / 12.0
            return String(format: "%.1f+ года".localized(), years)
                .replacingOccurrences(of: ".0", with: "")
        case 24:      return "2+ года".localized()
        case 25..<60: return String(format: "%d+ года".localized(), experienceMonths / 12)
        default:      return String(format: "%d+ лет".localized(), experienceMonths / 12)
        }
    }

    /// Look up metadata by raw program name (the seed key).
    /// Falls back to neutral defaults for user-created programs.
    static func metadata(for programName: String) -> ProgramMetadata {
        if let exact = lookupTable[programName] { return exact }
        // Try case-insensitive match for safety
        if let entry = lookupTable.first(where: { $0.key.caseInsensitiveCompare(programName) == .orderedSame }) {
            return entry.value
        }
        return ProgramMetadata(category: .massGain, level: .any, estimatedMinutes: 60, experienceMonths: 0)
    }

    // MARK: Lookup table — каждая программа размечена честно по реальному содержанию.
    // Уровень = техническая сложность + объем + требования к восстановлению.
    // experienceMonths = реалистичный минимальный стаж до начала.
    private static let lookupTable: [String: ProgramMetadata] = [

        // === FULL BODY / BEGINNER FOUNDATIONS ===
        "Full Body: Fundamental":
            .init(category: .massGain,     level: .beginner,     estimatedMinutes: 50, experienceMonths: 0),
        "High Frequency Full Body":
            .init(category: .massGain,     level: .intermediate, estimatedMinutes: 65, experienceMonths: 6),

        // === SPLITS / HYPERTROPHY ===
        "Aesthetics & Balance":
            .init(category: .massGain,     level: .intermediate, estimatedMinutes: 60, experienceMonths: 6),
        "Upper/Lower Hypertrophy":
            .init(category: .massGain,     level: .intermediate, estimatedMinutes: 60, experienceMonths: 6),
        "Push Pull Legs (PPL)":
            .init(category: .massGain,     level: .intermediate, estimatedMinutes: 70, experienceMonths: 9),
        "Bro Split":
            .init(category: .massGain,     level: .intermediate, estimatedMinutes: 60, experienceMonths: 6),
        "Arnold Split":
            .init(category: .massGain,     level: .advanced,     estimatedMinutes: 80, experienceMonths: 24),
        "Объемный Сплит":
            .init(category: .massGain,     level: .advanced,     estimatedMinutes: 75, experienceMonths: 18),
        "Pre-Exhaustion":
            .init(category: .massGain,     level: .intermediate, estimatedMinutes: 60, experienceMonths: 12),
        "EDT Плотность":
            .init(category: .massGain,     level: .advanced,     estimatedMinutes: 50, experienceMonths: 18),
        "PHA (Сердце)":
            .init(category: .massGain,     level: .intermediate, estimatedMinutes: 55, experienceMonths: 6),
        "Комплекс Медведь (The Bear)":
            .init(category: .massGain,     level: .advanced,     estimatedMinutes: 70, experienceMonths: 24),
        "Продвинутый DUP":
            .init(category: .massGain,     level: .advanced,     estimatedMinutes: 80, experienceMonths: 24),
        "Core Crusher":
            .init(category: .massGain,     level: .beginner,     estimatedMinutes: 25, experienceMonths: 0),

        // === STRENGTH / POWERLIFTING ===
        "5/3/1 for Beginners":
            .init(category: .strength,     level: .beginner,     estimatedMinutes: 60, experienceMonths: 1),
        "GZCLP Linear Progression":
            .init(category: .strength,     level: .beginner,     estimatedMinutes: 65, experienceMonths: 1),
        "StrongLifts 5x5":
            .init(category: .strength,     level: .beginner,     estimatedMinutes: 55, experienceMonths: 0),
        "Upper/Lower Strength":
            .init(category: .strength,     level: .intermediate, estimatedMinutes: 75, experienceMonths: 9),
        "Madcow 5x5":
            .init(category: .strength,     level: .intermediate, estimatedMinutes: 70, experienceMonths: 12),
        "Powerbuilding 4-Day":
            .init(category: .strength,     level: .intermediate, estimatedMinutes: 75, experienceMonths: 12),
        "nSuns 5/3/1 LP":
            .init(category: .strength,     level: .advanced,     estimatedMinutes: 75, experienceMonths: 24),

        // === CARDIO / CONDITIONING ===
        "LISS Elliptical":
            .init(category: .cardio,       level: .beginner,     estimatedMinutes: 50, experienceMonths: 0),
        "Couch to 5K":
            .init(category: .cardio,       level: .beginner,     estimatedMinutes: 35, experienceMonths: 0),
        "HIIT Pyramid":
            .init(category: .cardio,       level: .intermediate, estimatedMinutes: 25, experienceMonths: 3),
        "Norwegian 4x4":
            .init(category: .cardio,       level: .advanced,     estimatedMinutes: 35, experienceMonths: 18),

        // === FAT LOSS / METABOLIC ===
        "Tabata Total Body":
            .init(category: .fatLoss,      level: .intermediate, estimatedMinutes: 30, experienceMonths: 3),
        "EMOM Conditioning":
            .init(category: .fatLoss,      level: .intermediate, estimatedMinutes: 35, experienceMonths: 6),

        // === CALISTHENICS ===
        "Street Workout: Beginner":
            .init(category: .calisthenics, level: .beginner,     estimatedMinutes: 40, experienceMonths: 0),
        "Street Workout: Intermediate":
            .init(category: .calisthenics, level: .advanced,     estimatedMinutes: 55, experienceMonths: 18),

        // === GLUTES ===
        "Glute Builder":
            .init(category: .glutes,       level: .beginner,     estimatedMinutes: 50, experienceMonths: 1),
        "Booty Builder Pro":
            .init(category: .glutes,       level: .intermediate, estimatedMinutes: 60, experienceMonths: 9),
        "Stairmaster Glutes":
            .init(category: .glutes,       level: .intermediate, estimatedMinutes: 40, experienceMonths: 3),

        // === MOBILITY / RECOVERY ===
        "Mobility Flow":
            .init(category: .mobility,     level: .beginner,     estimatedMinutes: 20, experienceMonths: 0),
        "Yoga Flow Recovery":
            .init(category: .mobility,     level: .beginner,     estimatedMinutes: 30, experienceMonths: 0),

        // === HYBRID & VOLUME ===
        "German Volume Training (10×10)":
            .init(category: .massGain,     level: .intermediate, estimatedMinutes: 75, experienceMonths: 12),
        "Hybrid Athlete":
            .init(category: .strength,     level: .intermediate, estimatedMinutes: 70, experienceMonths: 9),
    ]
}
