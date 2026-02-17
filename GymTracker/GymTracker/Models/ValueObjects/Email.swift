//
//  Email.swift
//  GymTracker
//
//  Value Object for Email with validation
//

import Foundation

/// Type-safe wrapper for Email with validation
struct Email: Hashable, Codable {
    let value: String
    
    init(_ value: String) throws {
        guard Self.isValid(value) else {
            throw ValidationError.invalidEmail
        }
        self.value = value
    }
    
    private static func isValid(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }
}

extension Email: CustomStringConvertible {
    var description: String {
        value
    }
}

enum ValidationError: Error {
    case invalidEmail
    case passwordTooShort
    case emptyValue
}
