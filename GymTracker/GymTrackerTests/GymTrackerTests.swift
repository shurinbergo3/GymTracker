//
//  GymTrackerTests.swift
//  GymTrackerTests
//
//  E2E and Unit Tests for Body Forge
//

import Testing
import Foundation
import SwiftData
@testable import Body_Forge

// MARK: - CalorieCalculator Tests

@Suite("CalorieCalculator Tests")
struct CalorieCalculatorTests {
    
    @Test("Calculate calories with valid inputs")
    func testCalculateWithValidInputs() {
        let calories = CalorieCalculator.calculate(
            heartRate: 140,
            weightKg: 75,
            age: 30,
            durationMinutes: 60
        )
        
        #expect(calories > 0, "Calories should be positive with valid inputs")
        #expect(calories > 300, "60 min workout at HR 140 should burn > 300 cal")
        #expect(calories < 1000, "60 min workout should burn < 1000 cal")
    }
    
    @Test("Calculate calories with zero heart rate")
    func testCalculateWithZeroHeartRate() {
        let calories = CalorieCalculator.calculate(
            heartRate: 0,
            weightKg: 75,
            age: 30,
            durationMinutes: 60
        )
        
        #expect(calories == 0, "Zero heart rate should return 0 calories")
    }
    
    @Test("Calculate calories with zero weight")
    func testCalculateWithZeroWeight() {
        let calories = CalorieCalculator.calculate(
            heartRate: 140,
            weightKg: 0,
            age: 30,
            durationMinutes: 60
        )
        
        #expect(calories == 0, "Zero weight should return 0 calories")
    }
    
    @Test("Calculate calories with zero duration")
    func testCalculateWithZeroDuration() {
        let calories = CalorieCalculator.calculate(
            heartRate: 140,
            weightKg: 75,
            age: 30,
            durationMinutes: 0
        )
        
        #expect(calories == 0, "Zero duration should return 0 calories")
    }
    
    @Test("Calculate calories with negative inputs")
    func testCalculateWithNegativeInputs() {
        let calories = CalorieCalculator.calculate(
            heartRate: -10,
            weightKg: 75,
            age: 30,
            durationMinutes: 60
        )
        
        #expect(calories == 0, "Negative heart rate should return 0 calories")
    }
    
    @Test("Calculate calories scales with duration")
    func testCaloriesScaleWithDuration() {
        let calories30 = CalorieCalculator.calculate(
            heartRate: 140,
            weightKg: 75,
            age: 30,
            durationMinutes: 30
        )
        
        let calories60 = CalorieCalculator.calculate(
            heartRate: 140,
            weightKg: 75,
            age: 30,
            durationMinutes: 60
        )
        
        let ratio = calories60 / calories30
        #expect(abs(ratio - 2.0) < 0.01, "60 min should burn 2x calories of 30 min")
    }
}

// MARK: - WorkoutSet Model Tests

@Suite("WorkoutSet Model Tests")
struct WorkoutSetTests {
    
    @Test("Create WorkoutSet with valid data")
    func testCreateWorkoutSet() {
        let set = WorkoutSet(
            exerciseName: "Жим лёжа",
            weight: 80,
            reps: 10,
            setNumber: 1
        )
        
        #expect(set.exerciseName == "Жим лёжа")
        #expect(set.weight == 80)
        #expect(set.reps == 10)
        #expect(set.setNumber == 1)
        #expect(set.isCompleted == false)
    }
    
    @Test("WorkoutSet weight cannot be negative")
    func testWorkoutSetWeightValidation() {
        let set = WorkoutSet(
            exerciseName: "Присед",
            weight: -50,
            reps: 10,
            setNumber: 1
        )
        
        #expect(set.weight == 0, "Negative weight should be clamped to 0")
    }
    
    @Test("WorkoutSet reps cannot be negative")
    func testWorkoutSetRepsValidation() {
        let set = WorkoutSet(
            exerciseName: "Подтягивания",
            weight: 0,
            reps: -5,
            setNumber: 1
        )
        
        #expect(set.reps == 0, "Negative reps should be clamped to 0")
    }
    
    @Test("WorkoutSet weight setter validates input")
    func testWorkoutSetWeightSetter() {
        let set = WorkoutSet(
            exerciseName: "Становая тяга",
            weight: 100,
            reps: 5,
            setNumber: 1
        )
        
        set.weight = -20
        #expect(set.weight == 0, "Setting negative weight should clamp to 0")
        
        set.weight = 150
        #expect(set.weight == 150, "Setting positive weight should work")
    }
}

// MARK: - WorkoutSession Model Tests

@Suite("WorkoutSession Model Tests")
struct WorkoutSessionTests {
    
    @Test("Create WorkoutSession")
    func testCreateWorkoutSession() {
        let session = WorkoutSession(
            workoutDayName: "День груди",
            programName: "Push/Pull/Legs"
        )
        
        #expect(session.workoutDayName == "День груди")
        #expect(session.programName == "Push/Pull/Legs")
        #expect(session.isCompleted == false)
        #expect(session.isSynced == false)
        #expect(session.needsSync == false, "Incomplete session doesn't need sync")
    }
    
    @Test("WorkoutSession needsSync logic")
    func testWorkoutSessionNeedsSync() {
        let session = WorkoutSession(
            workoutDayName: "День спины"
        )
        
        // Incomplete session doesn't need sync
        #expect(session.needsSync == false)
        
        // Completed but not synced needs sync
        session.isCompleted = true
        #expect(session.needsSync == true)
        
        // Synced session doesn't need sync
        session.isSynced = true
        #expect(session.needsSync == false)
    }
}

// MARK: - Program Model Tests

@Suite("Program Model Tests")
struct ProgramTests {
    
    @Test("Create Program with days")
    func testCreateProgram() {
        let program = Program(
            name: "Push/Pull/Legs",
            desc: "Классическая программа",
            isActive: true
        )
        
        #expect(program.name == "Push/Pull/Legs")
        #expect(program.isActive == true)
        #expect(program.days.isEmpty)
    }
    
    @Test("Program current day index cycles correctly")
    func testProgramCurrentDayIndex() {
        let program = Program(name: "Test", isActive: true)
        
        // Empty program returns 0
        let indexEmpty = program.currentDayIndex()
        #expect(indexEmpty == 0)
    }
}

// MARK: - MeasurementType Tests

@Suite("MeasurementType Tests")
struct MeasurementTypeTests {
    
    @Test("All measurement types have Russian names")
    func testMeasurementTypeNames() {
        for type in MeasurementType.allCases {
            #expect(!type.rawValue.isEmpty, "\(type) should have a name")
        }
        
        #expect(MeasurementType.biceps.rawValue == "Бицепс")
        #expect(MeasurementType.chest.rawValue == "Грудь")
        #expect(MeasurementType.waist.rawValue == "Талия")
    }
    
    @Test("MeasurementType count is correct")
    func testMeasurementTypeCount() {
        #expect(MeasurementType.allCases.count == 8)
    }
}

// MARK: - WorkoutType Tests

@Suite("WorkoutType Tests")
struct WorkoutTypeTests {
    
    @Test("WorkoutType has display names")
    func testWorkoutTypeDisplayNames() {
        #expect(WorkoutType.strength.displayName == "Силовая")
        #expect(WorkoutType.repsOnly.displayName == "Свой вес")
        #expect(WorkoutType.duration.displayName == "На время / Кардио")
    }
    
    @Test("WorkoutType has icons")
    func testWorkoutTypeIcons() {
        #expect(WorkoutType.strength.icon == "dumbbell.fill")
        #expect(WorkoutType.repsOnly.icon == "figure.walk")
        #expect(WorkoutType.duration.icon == "stopwatch.fill")
    }
}
