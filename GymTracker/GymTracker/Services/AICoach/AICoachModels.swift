//
//  AICoachModels.swift
//  GymTracker
//
//  Persistent SwiftData models for the AI coach + their Firestore DTOs.
//
//  • AICoachMessage          — every chat turn (user + assistant)
//  • AICoachWeeklySummary    — cached digest of the last 7 days, fed into
//                               new prompts to keep token cost low.
//
//  Both have an optional `isSynced` flag used by SyncManager to push them
//  to Firestore (`users/{uid}/aiCoachMessages` and `aiCoachSummaries`).
//

import Foundation
import SwiftUI
import SwiftData
import FirebaseFirestore

// MARK: - Message

@Model
final class AICoachMessage {

    /// Use raw values instead of an enum for SwiftData/CloudKit friendliness.
    static let kindUser = "user"
    static let kindAssistant = "assistant"

    @Attribute(.unique) var id: UUID
    var kind: String
    var text: String
    var timestamp: Date

    /// Identifies the workout cycle this message belongs to. Format:
    /// `<sessionDate.timeIntervalSince1970>|<workoutDayName>` — same scheme
    /// used by `AICoachStore.signature(for:)`. nil for free-floating chat.
    var workoutSignature: String?

    /// True for the very first assistant message of each cycle (the analysis).
    /// Lets the history view highlight it.
    var isCycleAnalysis: Bool

    /// Optional so adding the field doesn't trigger a SwiftData migration.
    /// nil ⇒ never tried; false ⇒ tried and failed; true ⇒ in Firestore.
    var isSynced: Bool?

    init(kind: String,
         text: String,
         timestamp: Date = Date(),
         workoutSignature: String? = nil,
         isCycleAnalysis: Bool = false,
         id: UUID = UUID()) {
        self.id = id
        self.kind = kind
        self.text = text
        self.timestamp = timestamp
        self.workoutSignature = workoutSignature
        self.isCycleAnalysis = isCycleAnalysis
        self.isSynced = false
    }
}

extension AICoachMessage {
    var isUser: Bool { kind == AICoachMessage.kindUser }
    var isAssistant: Bool { kind == AICoachMessage.kindAssistant }
}

// MARK: - Weekly summary cache

@Model
final class AICoachWeeklySummary {

    @Attribute(.unique) var id: UUID
    var generatedAt: Date
    var coversFrom: Date
    var coversTo: Date
    var text: String
    /// Number of source messages this summary was built from. We rebuild
    /// when this number changes meaningfully (more chat happened since).
    var sourceMessageCount: Int

    var isSynced: Bool?

    init(coversFrom: Date,
         coversTo: Date,
         text: String,
         sourceMessageCount: Int,
         id: UUID = UUID()) {
        self.id = id
        self.generatedAt = Date()
        self.coversFrom = coversFrom
        self.coversTo = coversTo
        self.text = text
        self.sourceMessageCount = sourceMessageCount
        self.isSynced = false
    }
}

// MARK: - Preference keys

/// Centralised UserDefaults / @AppStorage keys for AI-coach preferences.
/// Kept here so the same key is referenced from Settings and the
/// notification service without typos drifting between files.
enum AICoachPrefs {
    /// Master kill-switch for AI-generated push notifications. Default: true.
    static let kAIPushEnabled = "aiCoach.pushEnabled"
}

// MARK: - Coach style

/// Selectable persona for the AI coach. Picked during onboarding, editable in
/// Settings. The raw value is what we persist; the prompt fragment is injected
/// into the system prompt so every reply mirrors the chosen tone.
enum AICoachStyle: String, CaseIterable, Identifiable, Codable {
    case strict
    case friendly
    case technical
    case motivator

    var id: String { rawValue }

    /// Short user-facing label (Russian source — String Catalog will localise).
    var titleKey: LocalizedStringKey {
        switch self {
        case .strict:    return "Жёсткий"
        case .friendly:  return "Дружелюбный"
        case .technical: return "Технарь"
        case .motivator: return "Мотиватор"
        }
    }

    var subtitleKey: LocalizedStringKey {
        switch self {
        case .strict:    return "Без сантиментов. Ты не на отдыхе."
        case .friendly:  return "Поддержка и спокойный тон."
        case .technical: return "Цифры, биомеханика, RPE."
        case .motivator: return "Эмоции и энергия. Поджигает."
        }
    }

    var emoji: String {
        switch self {
        case .strict:    return "🪖"
        case .friendly:  return "🤝"
        case .technical: return "🧪"
        case .motivator: return "🔥"
        }
    }

    /// Injected into the system prompt under "TONE:". English so the model
    /// understands it regardless of the user's language.
    var promptDirective: String {
        switch self {
        case .strict:
            return "Tone: drill-sergeant. Direct, no fluff, no compliments. Call out laziness. Be brief."
        case .friendly:
            return "Tone: warm, supportive coach. Encouraging but honest. Celebrate small wins."
        case .technical:
            return "Tone: precise sport-scientist. Use RPE, %1RM, tempo, bar speed. Cite mechanics. Numbers first."
        case .motivator:
            return "Tone: high-energy hype coach. Short punchy lines, emotional triggers, fire emoji allowed but sparingly. Make the user feel unstoppable."
        }
    }
}

// MARK: - User profile (singleton)

/// Long-term memory for the AI coach. One row per device — we use a fixed UUID
/// so SwiftData treats it as a singleton (upserted on every change).
///
/// What lives here:
/// • The user's chosen coach **style**.
/// • Free-form **goals** and **injury** notes the user can edit and the coach
///   keeps in mind across cycles.
/// • Timestamps used by background features (weekly wrapped, plateau detection)
///   to avoid spamming the user.
@Model
final class AICoachUserProfile {

    /// Stable singleton id. Hard-coded so we always upsert into the same row.
    static let singletonID = UUID(uuidString: "00000000-0000-0000-0000-A1C0ACABCDEF")!

    @Attribute(.unique) var id: UUID
    var coachStyleRaw: String
    var goalsNote: String
    var injuriesNote: String
    var lastWrappedShownAt: Date?
    var lastPlateauNotifiedAt: Date?
    var lastPreBriefAt: Date?
    var updatedAt: Date
    var isSynced: Bool?

    init(coachStyle: AICoachStyle = .friendly,
         goalsNote: String = "",
         injuriesNote: String = "",
         id: UUID = AICoachUserProfile.singletonID) {
        self.id = id
        self.coachStyleRaw = coachStyle.rawValue
        self.goalsNote = goalsNote
        self.injuriesNote = injuriesNote
        self.updatedAt = Date()
        self.isSynced = false
    }

    var coachStyle: AICoachStyle {
        get { AICoachStyle(rawValue: coachStyleRaw) ?? .friendly }
        set { coachStyleRaw = newValue.rawValue; updatedAt = Date() }
    }
}

// MARK: - Firestore DTOs

struct AICoachMessageDTO: Codable, Identifiable {
    /// We use the SwiftData `AICoachMessage.id` (UUID string) as the Firestore
    /// document ID — gives us idempotent uploads and trivial deduplication
    /// on download.
    @DocumentID var id: String?
    var kind: String
    var text: String
    var timestamp: Date
    var workoutSignature: String?
    var isCycleAnalysis: Bool

    init(from m: AICoachMessage) {
        self.id = m.id.uuidString
        self.kind = m.kind
        self.text = m.text
        self.timestamp = m.timestamp
        self.workoutSignature = m.workoutSignature
        self.isCycleAnalysis = m.isCycleAnalysis
    }

    /// Build a SwiftData object from a Firestore doc. Returns nil if the
    /// doc id isn't a valid UUID.
    func toModel() -> AICoachMessage? {
        guard let id, let uuid = UUID(uuidString: id) else { return nil }
        let m = AICoachMessage(
            kind: kind,
            text: text,
            timestamp: timestamp,
            workoutSignature: workoutSignature,
            isCycleAnalysis: isCycleAnalysis,
            id: uuid
        )
        m.isSynced = true  // it came from cloud
        return m
    }
}

struct AICoachWeeklySummaryDTO: Codable, Identifiable {
    @DocumentID var id: String?
    var generatedAt: Date
    var coversFrom: Date
    var coversTo: Date
    var text: String
    var sourceMessageCount: Int

    init(from s: AICoachWeeklySummary) {
        self.id = s.id.uuidString
        self.generatedAt = s.generatedAt
        self.coversFrom = s.coversFrom
        self.coversTo = s.coversTo
        self.text = s.text
        self.sourceMessageCount = s.sourceMessageCount
    }
}
