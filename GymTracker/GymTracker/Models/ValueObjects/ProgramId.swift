//
//  ProgramId.swift
//  GymTracker
//
//  Value Object for Program ID
//

import Foundation

/// Type-safe wrapper for Program ID
struct ProgramId: Hashable, Codable {
    let value: String
    
    init(_ value: String) {
        self.value = value
    }
    
    /// Generate new unique program ID
    static func generate() -> ProgramId {
        ProgramId(UUID().uuidString)
    }
}

extension ProgramId: CustomStringConvertible {
    var description: String {
        value
    }
}
