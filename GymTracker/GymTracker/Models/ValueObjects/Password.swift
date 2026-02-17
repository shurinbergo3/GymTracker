//
//  Password.swift
//  GymTracker
//
//  Value Object for Password with validation
//

import Foundation

/// Type-safe wrapper for Password with validation
/// Does not conform to Hashable/Codable for security
struct Password {
    private let value: String
    
    init(_ value: String) throws {
        guard value.count >= 6 else {
            throw ValidationError.passwordTooShort
        }
        self.value = value
    }
    
    /// Get raw value for authentication APIs
    var rawValue: String {
        value
    }
}
