//
//  SchemaVersions.swift
//  GymTracker
//
//  SwiftData schema versioning for safe migrations
//

import SwiftData
import Foundation

// MARK: - Schema V1 (Original)

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            WorkoutSession.self,
            WorkoutSet.self,
            BodyMeasurement.self,
            WeightRecord.self,
            Program.self,
            WorkoutDayV1.self,
            ExerciseTemplate.self
        ]
    }
    
    @Model
    final class WorkoutDayV1 {
        var name: String
        var orderIndex: Int
        var _workoutType: WorkoutType?
        
        var workoutType: WorkoutType {
            get { _workoutType ?? .strength }
            set { _workoutType = newValue }
        }
        
        // NO rest timer fields in V1
        
        var program: Program?
        
        @Relationship(deleteRule: .cascade, inverse: \ExerciseTemplate.workoutDay)
        var exercises: [ExerciseTemplate]
        
        init(name: String, orderIndex: Int, workoutType: WorkoutType = .strength) {
            self.name = name
            self.orderIndex = orderIndex
            self._workoutType = workoutType
            self.exercises = []
        }
    }
}

// MARK: - Schema V2 (With Rest Timer)

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            WorkoutSession.self,
            WorkoutSet.self,
            BodyMeasurement.self,
            WeightRecord.self,
            Program.self,
            WorkoutDay.self,  // Uses current WorkoutDay with new fields
            ExerciseTemplate.self
        ]
    }
}

// MARK: - Migration Plan

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // Optional: Pre-migration tasks
            print("🔄 Starting migration from V1 to V2...")
        },
        didMigrate: { context in
            // Set default values for new fields
            let descriptor = FetchDescriptor<WorkoutDay>()
            let workoutDays = try context.fetch(descriptor)
            
            for day in workoutDays {
                // Set defaults for new fields
                day.defaultRestTime = 90
                day.restTimerEnabled = true
            }
            
            try context.save()
            print("✅ Migration V1→V2 complete: \(workoutDays.count) days updated")
        }
    )
}
