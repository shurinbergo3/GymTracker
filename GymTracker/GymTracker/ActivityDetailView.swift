//
//  ActivityDetailView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import HealthKit

struct ActivityDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var move: Double = 0
    @State private var moveGoal: Double = 600
    @State private var exercise: Double = 0
    @State private var exerciseGoal: Double = 30
    @State private var stand: Double = 0
    @State private var standGoal: Double = 12
    @State private var steps: Int = 0
    @State private var distance: Double = 0
    @State private var selectedDate: Date = Date()
    @State private var weeklyData: [DailyActivityData] = []
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Large Rings
                    largeRingsSection
                    
                    // Metrics with Charts
                    metricsSection
                    
                    // Steps & Distance
                    stepsAndDistanceSection
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Color.black)
            .navigationTitle(formatDateTitle(selectedDate))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            fetchData()
        }
    }
    
    // MARK: - Weekly Rings
    private var weeklyRingsSection: some View {
        HStack(spacing: 12) {
            ForEach(-6...0, id: \.self) { dayOffset in
                let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
                let isToday = dayOffset == 0
                
                VStack(spacing: 6) {
                    Text(dayAbbrev(date))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isToday ? .white : .gray)
                    
                    // Mini ring placeholder
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: isToday ? min(move / moveGoal, 1.0) : Double.random(in: 0.3...1.0))
                            .stroke(Color(red: 1.0, green: 0.2, blue: 0.4), lineWidth: 3)
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 36, height: 36)
                    .overlay {
                        if isToday {
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Large Rings
    private var largeRingsSection: some View {
        ZStack {
            // Outer ring (Move - Red)
            Circle()
                .stroke(Color.red.opacity(0.2), lineWidth: 28)
            Circle()
                .trim(from: 0, to: min(move / moveGoal, 1.0))
                .stroke(Color(red: 1.0, green: 0.2, blue: 0.4), style: StrokeStyle(lineWidth: 28, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // Middle ring (Exercise - Green)
            Circle()
                .stroke(Color.green.opacity(0.2), lineWidth: 28)
                .padding(32)
            Circle()
                .trim(from: 0, to: min(exercise / exerciseGoal, 1.0))
                .stroke(Color(red: 0.4, green: 1.0, blue: 0.2), style: StrokeStyle(lineWidth: 28, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(32)
            
            // Inner ring (Stand - Blue)
            Circle()
                .stroke(Color.cyan.opacity(0.2), lineWidth: 28)
                .padding(64)
            Circle()
                .trim(from: 0, to: min(stand / standGoal, 1.0))
                .stroke(Color(red: 0.2, green: 0.8, blue: 1.0), style: StrokeStyle(lineWidth: 28, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(64)
            
            // Center icons
            VStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
                Image(systemName: "arrow.right.arrow.left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
                Image(systemName: "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan)
            }
        }
        .frame(width: 220, height: 220)
        .padding(.vertical, 20)
    }
    
    // MARK: - Metrics Section
    private var metricsSection: some View {
        VStack(spacing: 24) {
            // Move
            metricRow(
                title: "Подвижность",
                value: "\(Int(move))/\(Int(moveGoal)) ККАЛ",
                color: Color(red: 1.0, green: 0.2, blue: 0.4),
                total: "ВСЕГО 1 558 ККАЛ"
            )
            
            // Exercise
            metricRow(
                title: "Упражнения",
                value: "\(Int(exercise))/\(Int(exerciseGoal)) МИН",
                color: Color(red: 0.4, green: 1.0, blue: 0.2),
                total: "ВСЕГО 8 Ч 20 МИН"
            )
            
            // Stand
            metricRow(
                title: "С разминкой",
                value: "\(Int(stand))/\(Int(standGoal)) Ч",
                color: Color(red: 0.2, green: 0.8, blue: 1.0),
                total: "4 Ч БЕЗ РАЗМИНКИ"
            )
        }
    }
    
    private func metricRow(title: String, value: String, color: Color, total: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            // Bar chart placeholder
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<24, id: \.self) { hour in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 8, height: CGFloat.random(in: 5...50))
                }
            }
            .frame(height: 50)
            
            // Time axis
            HStack {
                Text("00:00")
                Spacer()
                Text("06:00")
                Spacer()
                Text("12:00")
                Spacer()
                Text("18:00")
            }
            .font(.system(size: 10))
            .foregroundColor(.gray)
            
            Text(total)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
        }
    }
    
    // MARK: - Steps & Distance
    private var stepsAndDistanceSection: some View {
        HStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Шаги".localized())
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Text("\(steps.formatted())")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Дистанция".localized())
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Text(String(format: "%.2f КМ", distance))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.top, 16)
    }
    
    // MARK: - Helpers
    private func formatDateTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "'Сегодня,' d MMM yyyy 'г.'"
        return formatter.string(from: date)
    }
    
    private func dayAbbrev(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EE"
        return formatter.string(from: date).prefix(2).capitalized
    }
    
    private func fetchData() {
        Task {
            // Fetch activity summary
            if let summary = await HealthManager.shared.fetchActivitySummary() {
                await MainActor.run {
                    move = summary.activeEnergyBurned.doubleValue(for: .kilocalorie())
                    moveGoal = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())
                    exercise = summary.appleExerciseTime.doubleValue(for: .minute())
                    exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: .minute())
                    stand = summary.appleStandHours.doubleValue(for: .count())
                    standGoal = summary.appleStandHoursGoal.doubleValue(for: .count())
                }
            }
            
            // Fetch steps and distance
            let fetchedSteps = await HealthManager.shared.fetchTodaySteps()
            let fetchedDistance = await HealthManager.shared.fetchTodayDistance()
            await MainActor.run {
                steps = fetchedSteps
                distance = fetchedDistance
            }
        }
    }
}

struct DailyActivityData: Identifiable {
    let id = UUID()
    let date: Date
    let move: Double
    let exercise: Double
    let stand: Double
}

#Preview {
    ActivityDetailView()
}
