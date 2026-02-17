//
//  UserId.swift
//  GymTracker
//
//  Value Object for User ID (prevents primitive obsession)
//

import Foundation

/// Type-safe wrapper for User ID
struct UserId: Hashable, Codable {
    let value: String
    
    init(_ value: String) {
        self.value = value
    }
}

extension UserId: CustomStringConvertible {
    var description: String {
        value
    }
}
