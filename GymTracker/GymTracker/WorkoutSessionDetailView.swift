//
//  WorkoutSessionDetailView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct WorkoutSessionDetailView: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Stats
                    headerSection
                    
                    // Exercises List
                    exercisesSection
                    
                    // Summary Stats
                    summarySection
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Color.black)
            .navigationTitle(session.workoutDayName.localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Date
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(DesignSystem.Colors.neonGreen)
                Text(formatDate(session.date))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
            
            // Stats Grid
            HStack(spacing: 16) {
                statBox(
                    title: "Время".localized(),
                    value: formatDuration(session.endTime?.timeIntervalSince(session.date) ?? 0),
                    icon: "timer",
                    color: .blue
                )
                
                statBox(
                    title: "Калории".localized(),
                    value: "\(session.calories ?? 0)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                statBox(
                    title: "Подходов".localized(),
                    value: "\(session.sets.count)",
                    icon: "checkmark.circle.fill",
                    color: DesignSystem.Colors.neonGreen
                )
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }
    
    private func statBox(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Exercises Section
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Упражнения".localized())
                .font(.headline)
                .foregroundColor(.white)
            
            if exercisesByName.isEmpty {
                Text("Нет записанных упражнений".localized())
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(exercisesByName.keys.sorted(), id: \.self) { exerciseName in
                    if let sets = exercisesByName[exerciseName] {
                        exerciseCard(name: exerciseName, sets: sets)
                    }
                }
            }
        }
    }
    
    private var exercisesByName: [String: [WorkoutSet]] {
        Dictionary(grouping: session.sets, by: { $0.exerciseName })
    }
    
    private func exerciseCard(name: String, sets: [WorkoutSet]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Name
            Text(name.localized())
                .font(.headline)
                .foregroundColor(.white)
            
            // Sets
            ForEach(Array(sets.sorted(by: { 
                // Сортируем по времени создания, потом по номеру подхода
                if $0.date != $1.date {
                    return $0.date < $1.date
                }
                return $0.setNumber < $1.setNumber
            }).enumerated()), id: \.offset) { index, set in
                HStack {
                    Text("Подход \(set.setNumber)".localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(width: 70, alignment: .leading)
                    
                    Spacer()
                    
                    // Show based on workout type
                    if set.weight > 0 {
                        Text("\(Int(set.weight)) кг".localized())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("×")
                            .foregroundColor(.gray)
                        
                        Text("\(set.reps)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                    } else if (set.duration ?? 0) > 0 {
                        Text(formatSetDuration(set.duration ?? 0))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                    } else {
                        Text("\(set.reps) раз".localized())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                    }
                }
                .padding(.vertical, 4)
                
                if index < sets.count - 1 {
                    Divider().background(Color.white.opacity(0.1))
                }
            }
            
            // Volume for this exercise
            let volume = sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            if volume > 0 {
                HStack {
                    Text("volume_colon".localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(Int(volume)) кг".localized())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Итого за тренировку".localized())
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                summaryRow(title: "Общий объём".localized(), value: "\(Int(totalVolume)) \("кг".localized())")
                Divider().background(Color.white.opacity(0.1))
                summaryRow(title: "Упражнений выполнено".localized(), value: "\(exercisesByName.count)")
                Divider().background(Color.white.opacity(0.1))
                summaryRow(title: "Всего подходов".localized(), value: "\(session.sets.count)")
                Divider().background(Color.white.opacity(0.1))
                summaryRow(title: "Средний вес".localized(), value: "\(Int(averageWeight)) \("кг".localized())")
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Computed Properties
    private var totalVolume: Double {
        session.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
    }
    
    private var averageWeight: Double {
        let weightsUsed = session.sets.filter { $0.weight > 0 }
        guard !weightsUsed.isEmpty else { return 0 }
        return weightsUsed.map { $0.weight }.reduce(0, +) / Double(weightsUsed.count)
    }
    
    // MARK: - Formatters
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        return formatter.string(from: date).capitalized
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)ч \(minutes)м"
        }
        return "\(minutes) мин"
    }
    
    private func formatSetDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins > 0 {
            return "\(mins)м \(secs)с"
        }
        return "\(Int(seconds))с"
    }
}

#Preview {
    WorkoutSessionDetailView(session: WorkoutSession(date: Date(), workoutDayName: "День 1", programName: "Test Program"))
}
