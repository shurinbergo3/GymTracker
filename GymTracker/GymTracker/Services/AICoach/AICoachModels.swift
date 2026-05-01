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
