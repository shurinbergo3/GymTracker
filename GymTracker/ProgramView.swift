//
//  ProgramView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct ProgramView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var programs: [Program]
    @State private var showingCreateProgram = false
    
    private var activeProgram: Program? {
        programs.first(where: { $0.isActive })
    }
    
    private var inactivePrograms: [Program] {
        programs.filter { !$0.isActive }
    }
    
    // Group programs by workout type
    private var groupedPrograms: [WorkoutType: [Program]] {
        Dictionary(grouping: inactivePrograms) { program in
            program.days.first?.workoutType ?? .strength
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                if programs.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        EmptyStateView(
                            icon: "list.bullet.clipboard",
                            title: "Нет программ",
                            message: "Создайте свою первую программу тренировок",
                            buttonTitle: "Создать программу"
                        ) {
                            showingCreateProgram = true
                        }
                        
                        Button(action: loadDefaultPrograms) {
                            HStack {
                                Image(systemName: "square.stack.3d.down.right")
                                Text("Загрузить стандартные программы")
                            }
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(DesignSystem.Colors.accent)
                            .padding()
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            // Active Program Section
                            if let activeProgram = activeProgram {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                    Text("АКТИВНАЯ ПРОГРАММА")
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .tracking(1.2)
                                        .padding(.horizontal, DesignSystem.Spacing.lg)
                                    
                                    ActiveProgramCard(program: activeProgram)
                                }
                            }
                            
                            // Create Button
                            Button(action: { showingCreateProgram = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("Создать свою программу")
                                        .font(DesignSystem.Typography.headline())
                                }
                                .foregroundColor(DesignSystem.Colors.accent)
                                .frame(maxWidth: .infinity)
                                .padding(DesignSystem.Spacing.xl)
                                .background(DesignSystem.Colors.cardBackground)
                                .cornerRadius(DesignSystem.CornerRadius.large)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            
                            // All Programs Section
                            if !inactivePrograms.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                    HStack {
                                        Text("ВСЕ ПРОГРАММЫ (\(inactivePrograms.count))")
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                            .tracking(1.2)
                                        
                                        Spacer()
                                        
                                        if inactivePrograms.count < 15 {
                                            Button(action: loadDefaultPrograms) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "arrow.down.circle")
                                                    Text("Загрузить")
                                                }
                                                .font(DesignSystem.Typography.caption())
                                                .foregroundColor(DesignSystem.Colors.accent)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.lg)
                                    
                                    // Группировка по типу тренировок
                                    ForEach(WorkoutType.allCases, id: \.self) { workoutType in
                                        if let programsForType = groupedPrograms[workoutType], !programsForType.isEmpty {
                                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                                HStack {
                                                    Image(systemName: workoutType.icon)
                                                        .font(.callout)
                                                        .foregroundColor(DesignSystem.Colors.neonGreen)
                                                    
                                                    Text(workoutType.rawValue)
                                                        .font(DesignSystem.Typography.body())
                                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                                    
                                                    Spacer()
                                                    
                                                    Text("\(programsForType.count)")
                                                        .font(DesignSystem.Typography.caption())
                                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                                }
                                                .padding(.horizontal, DesignSystem.Spacing.lg)
                                                .padding(.top, DesignSystem.Spacing.md)
                                                
                                                ForEach(programsForType, id: \.self) { program in
                                                    ProgramCard(program: program)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, DesignSystem.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Программы")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateProgram) {
                ProgramEditorView()
            }
        }
    }
    
    private func loadDefaultPrograms() {
        ProgramSeeder.seedProgramsIfNeeded(context: modelContext)
    }
}

// MARK: - Active Program Card

struct ActiveProgramCard: View {
    let program: Program
    @State private var showingEditor = false
    
    private var typeSummary: [(type: WorkoutType, count: Int)] {
        let typeCounts = Dictionary(grouping: program.days, by: { $0.workoutType })
            .mapValues { $0.count }
            .sorted { $0.key.rawValue < $1.key.rawValue }
        
        return typeCounts.map { (type: $0.key, count: $0.value) }
    }
    
    var body: some View {
        NavigationLink(destination: ProgramDetailView(program: program)) {
            CardView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text(program.name)
                                .font(DesignSystem.Typography.title())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            if !program.desc.isEmpty {
                                Text(program.desc)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                            .font(.system(size: 32))
                    }
                    
                    Divider()
                        .background(DesignSystem.Colors.secondaryText.opacity(0.3))
                    
                    // Type and days
                    HStack(spacing: DesignSystem.Spacing.md) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            ForEach(typeSummary, id: \.type) { item in
                                HStack(spacing: 4) {
                                    Image(systemName: item.type.icon)
                                        .foregroundColor(colorForWorkoutType(item.type))
                                    Text("\(item.count)")
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Label("\(program.days.count) дней", systemImage: "calendar.badge.clock")
                            .font(DesignSystem.Typography.callout())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    // Edit button
                    Button(action: { showingEditor = true }) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "pencil")
                            Text("Редактировать программу")
                        }
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.neonGreen.opacity(0.15))
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(DesignSystem.Spacing.xl)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingEditor) {
            ProgramEditorView(existingProgram: program)
        }
    }
    
    private func colorForWorkoutType(_ type: WorkoutType) -> Color {
        switch type {
        case .strength:
            return .blue
        case .circuit:
            return .orange
        case .cardio:
            return .red
        }
    }
}

// MARK: - Program Card

struct ProgramCard: View {
    let program: Program
    @Environment(\.modelContext) private var modelContext
    
    // Pre-compute summary to avoid recalculating on every render
    private var typeSummary: [(type: WorkoutType, count: Int)] {
        let typeCounts = Dictionary(grouping: program.days, by: { $0.workoutType })
            .mapValues { $0.count }
            .sorted { $0.key.rawValue < $1.key.rawValue }
        
        return typeCounts.map { (type: $0.key, count: $0.value) }
    }
    
    var body: some View {
        NavigationLink(destination: ProgramDetailView(program: program)) {
            CardView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            // Крупное название программы
                            Text(program.name)
                                .font(DesignSystem.Typography.title())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            if !program.desc.isEmpty {
                                Text(program.desc)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
                        if program.isActive {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(DesignSystem.Colors.neonGreen)
                                .font(.system(size: 32))
                        }
                    }
                    
                    Divider()
                        .background(DesignSystem.Colors.secondaryText.opacity(0.3))
                    
                    // Тип тренировок и количество дней
                    HStack(spacing: DesignSystem.Spacing.md) {
                        // Workout Type Summary
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            ForEach(typeSummary, id: \.type) { item in
                                HStack(spacing: 4) {
                                    Image(systemName: item.type.icon)
                                        .foregroundColor(colorForWorkoutType(item.type))
                                    Text("\(item.count)")
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Label("\(program.days.count) дней", systemImage: "calendar.badge.clock")
                            .font(DesignSystem.Typography.callout())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    // Кнопка активации
                    HStack(spacing: DesignSystem.Spacing.xl) {
                        
                        if !program.isActive {
                            Button(action: { activateProgram() }) {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Image(systemName: "play.fill")
                                    Text("Активировать")
                                }
                                .font(DesignSystem.Typography.headline())
                                .foregroundColor(DesignSystem.Colors.neonGreen)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                                .background(DesignSystem.Colors.neonGreen.opacity(0.15))
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(DesignSystem.Spacing.xl)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func activateProgram() {
        // Деактивируем все программы
        let descriptor = FetchDescriptor<Program>()
        if let allPrograms = try? modelContext.fetch(descriptor) {
            for prog in allPrograms {
                prog.isActive = false
            }
        }
        
        // Активируем текущую
        program.isActive = true
        program.startDate = Date()
        
        try? modelContext.save()
        
        // Уведомляем систему об изменении активной программы
        NotificationCenter.default.post(
            name: Notification.Name("ActiveProgramChanged"),
            object: nil
        )
    }
    
    private func colorForWorkoutType(_ type: WorkoutType) -> Color {
        switch type {
        case .strength:
            return .blue
        case .circuit:
            return .orange
        case .cardio:
            return .red
        }
    }
}


#Preview {
    ProgramView()
        .modelContainer(for: Program.self, inMemory: true)
}

