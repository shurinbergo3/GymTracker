//
//  AICoachFirestore.swift
//  GymTracker
//
//  Firestore I/O for the AI Coach. Mirrors the WorkoutSession sync style:
//  upload-on-write, fetch-on-launch, delete-all on wipe.
//
//  Collections (per signed-in user):
//    users/{uid}/aiCoachMessages/{messageUUID}
//    users/{uid}/aiCoachSummaries/{summaryUUID}
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

extension FirestoreManager {

    private var db: Firestore { Firestore.firestore() }

    // MARK: - Messages

    func saveAsync(coachMessage: AICoachMessage) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirestoreManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        let dto = AICoachMessageDTO(from: coachMessage)
        let path = "users/\(uid)/aiCoachMessages"
        let docId = coachMessage.id.uuidString
        let ref = db.collection(path).document(docId)
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            do {
                try ref.setData(from: dto, merge: true) { error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    func fetchAllCoachMessages() async throws -> [AICoachMessageDTO] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        let path = "users/\(uid)/aiCoachMessages"
        let snap = try await db.collection(path).getDocuments()
        return snap.documents.compactMap { try? $0.data(as: AICoachMessageDTO.self) }
    }

    func deleteAllCoachMessages() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let path = "users/\(uid)/aiCoachMessages"
        let snap = try await db.collection(path).getDocuments()
        guard !snap.documents.isEmpty else { return }

        // Firestore batch is capped at 500 ops.
        let chunks = snap.documents.chunked(into: 400)
        for chunk in chunks {
            let batch = db.batch()
            for doc in chunk { batch.deleteDocument(doc.reference) }
            try await batch.commit()
        }
    }

    // MARK: - Weekly summaries

    func saveAsync(coachSummary: AICoachWeeklySummary) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let dto = AICoachWeeklySummaryDTO(from: coachSummary)
        let path = "users/\(uid)/aiCoachSummaries"
        let docId = coachSummary.id.uuidString
        let ref = db.collection(path).document(docId)
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            do {
                try ref.setData(from: dto, merge: true) { error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    func deleteAllCoachSummaries() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let path = "users/\(uid)/aiCoachSummaries"
        let snap = try await db.collection(path).getDocuments()
        guard !snap.documents.isEmpty else { return }
        let batch = db.batch()
        for doc in snap.documents { batch.deleteDocument(doc.reference) }
        try await batch.commit()
    }
}

// MARK: - Tiny array chunking helper (kept private to this file to avoid clashes).

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
