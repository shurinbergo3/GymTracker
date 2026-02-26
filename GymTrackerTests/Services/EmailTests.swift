//
//  EmailTests.swift
//  GymTrackerTests
//
//  Tests for Email Value Object (TDD)
//

import XCTest
@testable import GymTracker

final class EmailTests: XCTestCase {
    
    // MARK: - Valid Email Tests
    
    func test_validEmail_createsSuccessfully() throws {
        // Arrange & Act
        let email = try Email("test@example.com")
        
        // Assert
        XCTAssertEqual(email.value, "test@example.com")
    }
    
    func test_validEmailWithSubdomain_createsSuccessfully() throws {
        // Arrange & Act
        let email = try Email("user@mail.example.com")
        
        // Assert
        XCTAssertEqual(email.value, "user@mail.example.com")
    }
    
    // MARK: - Invalid Email Tests
    
    func test_emailWithoutAtSign_throwsError() {
        // Arrange & Act & Assert
        XCTAssertThrowsError(try Email("invalid.email.com")) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.invalidEmail)
        }
    }
    
    func test_emailWithoutDot_throwsError() {
        // Arrange & Act & Assert
        XCTAssertThrowsError(try Email("invalid@emailcom")) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.invalidEmail)
        }
    }
    
    func test_emptyEmail_throwsError() {
        // Arrange & Act & Assert
        XCTAssertThrowsError(try Email("")) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.invalidEmail)
        }
    }
    
    // MARK: - Equality Tests
    
    func test_sameEmails_areEqual() throws {
        // Arrange
        let email1 = try Email("test@example.com")
        let email2 = try Email("test@example.com")
        
        // Act & Assert
        XCTAssertEqual(email1, email2)
    }
    
    func test_differentEmails_areNotEqual() throws {
        // Arrange
        let email1 = try Email("test1@example.com")
        let email2 = try Email("test2@example.com")
        
        // Act & Assert
        XCTAssertNotEqual(email1, email2)
    }
}
