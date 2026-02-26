//
//  PasswordTests.swift
//  GymTrackerTests
//
//  Tests for Password Value Object (TDD)
//

import XCTest
@testable import GymTracker

final class PasswordTests: XCTestCase {
    
    // MARK: - Valid Password Tests
    
    func test_validPassword_createsSuccessfully() throws {
        // Arrange & Act
        let password = try Password("password123")
        
        // Assert
        XCTAssertEqual(password.rawValue, "password123")
    }
    
    func test_passwordWithMinimumLength_createsSuccessfully() throws {
        // Arrange & Act
        let password = try Password("123456")
        
        // Assert
        XCTAssertEqual(password.rawValue, "123456")
    }
    
    // MARK: - Invalid Password Tests
    
    func test_passwordTooShort_throwsError() {
        // Arrange & Act & Assert
        XCTAssertThrowsError(try Password("12345")) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.passwordTooShort)
        }
    }
    
    func test_emptyPassword_throwsError() {
        // Arrange & Act & Assert
        XCTAssertThrowsError(try Password("")) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.passwordTooShort)
        }
    }
}
