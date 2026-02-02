//
//  WorkoutSession+Volume.swift
//  GymTracker
//
//  Created by Antigravity
//

import Foundation

extension WorkoutSession {
    /// Calculates the total volume of the workout session.
    /// Volume is calculated as the sum of (weight * reps) for all sets.
    var volume: Double {
        sets.reduce(0.0) { total, set in
            total + (set.weight * Double(set.reps))
        }
    }
}
