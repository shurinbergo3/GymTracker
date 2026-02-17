//
//  SessionId.swift
//  GymTracker
//
//  Value Object for Workout Session ID
//

import Foundation

/// Type-safe wrapper for Session ID
struct SessionId: Hashable, Codable {
    let value: String
    
    init(_ value: String) {
        self.value = value
    }
    
    /// Generate new unique session ID
    static func generate() -> SessionId {
        SessionId(UUID().uuidString)
    }
}

extension SessionId: CustomStringConvertible {
    var description: String {
        value
    }
}
