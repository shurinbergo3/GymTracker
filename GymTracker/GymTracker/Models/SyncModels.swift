
import Foundation

// MARK: - DTO Structs

struct WeightRecordDTO: Codable, Sendable {
    let weight: Double
    let date: Date
}

struct BodyMeasurementDTO: Codable, Sendable {
    let date: Date
    let type: String // MeasurementType raw value
    let value: Double
}

struct UserProfileData: Codable, Sendable {
    let height: Double
    let weight: Double
    let age: Int
    let activeProgramName: String?
    let lastUpdated: Date
    let weightHistory: [WeightRecordDTO]?
    let bodyMeasurements: [BodyMeasurementDTO]?
}
