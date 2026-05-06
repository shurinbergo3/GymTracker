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

    /// Look up metadata by raw program name (the seed key).
    /// Falls back to neutral defaults for user-created programs.
    static func metadata(for programName: String) -> ProgramMetadata {
        if let exact = lookupTable[programName] { return exact }
        // Try case-insensitive match for safety
        if let entry = lookupTable.first(where: { $0.key.caseInsensitiveCompare(programName) == .orderedSame }) {
            return entry.value
        }
        return ProgramMetadata(category: .massGain, level: .any, estimatedMinutes: 60)
    }

    private static let lookupTable: [String: ProgramMetadata] = [
        // Existing
        "Full Body: Fundamental":       .init(category: .massGain,     level: .beginner,     estimatedMinutes: 50),
        "High Frequency Full Body":     .init(category: .massGain,     level: .intermediate, estimatedMinutes: 65),
        "Aesthetics & Balance":         .init(category: .massGain,     level: .intermediate, estimatedMinutes: 60),
        "Upper/Lower Strength":         .init(category: .strength,     level: .intermediate, estimatedMinutes: 75),
        "5/3/1 for Beginners":          .init(category: .strength,     level: .beginner,     estimatedMinutes: 60),
        "GZCLP Linear Progression":     .init(category: .strength,     level: .beginner,     estimatedMinutes: 65),
        "HIIT Pyramid":                 .init(category: .cardio,       level: .intermediate, estimatedMinutes: 25),
        "LISS Elliptical":              .init(category: .cardio,       level: .beginner,     estimatedMinutes: 50),
        "Street Workout: Beginner":     .init(category: .calisthenics, level: .beginner,     estimatedMinutes: 40),
        "Street Workout: Intermediate": .init(category: .calisthenics, level: .intermediate, estimatedMinutes: 55),

        // New popular programs
        "Push Pull Legs (PPL)":         .init(category: .massGain,     level: .intermediate, estimatedMinutes: 70),
        "Bro Split":                    .init(category: .massGain,     level: .intermediate, estimatedMinutes: 60),
        "Arnold Split":                 .init(category: .massGain,     level: .advanced,     estimatedMinutes: 80),
        "StrongLifts 5x5":              .init(category: .strength,     level: .beginner,     estimatedMinutes: 55),
        "nSuns 5/3/1 LP":               .init(category: .strength,     level: .advanced,     estimatedMinutes: 75),
        "Madcow 5x5":                   .init(category: .strength,     level: .intermediate, estimatedMinutes: 70),
        "Powerbuilding 4-Day":          .init(category: .strength,     level: .intermediate, estimatedMinutes: 75),
        "Glute Builder":                .init(category: .glutes,       level: .any,          estimatedMinutes: 50),
        "Core Crusher":                 .init(category: .massGain,     level: .any,          estimatedMinutes: 25),
        "Tabata Total Body":            .init(category: .fatLoss,      level: .intermediate, estimatedMinutes: 30),
        "Mobility Flow":                .init(category: .mobility,     level: .beginner,     estimatedMinutes: 20),
        "EMOM Conditioning":            .init(category: .fatLoss,      level: .intermediate, estimatedMinutes: 35),

        // v4 — Upper/Lower hypertrophy + glutes/mobility/cardio additions
        "Upper/Lower Hypertrophy":      .init(category: .massGain,     level: .beginner,     estimatedMinutes: 60),
        "Booty Builder Pro":            .init(category: .glutes,       level: .intermediate, estimatedMinutes: 60),
        "Yoga Flow Recovery":           .init(category: .mobility,     level: .any,          estimatedMinutes: 30),
        "Couch to 5K":                  .init(category: .cardio,       level: .beginner,     estimatedMinutes: 35),
        "Norwegian 4x4":                .init(category: .cardio,       level: .advanced,     estimatedMinutes: 35),
    ]
}
