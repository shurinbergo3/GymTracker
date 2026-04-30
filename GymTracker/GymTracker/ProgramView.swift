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
    @Query(sort: [SortDescriptor(\Program.displayOrder, order: .forward)]) private var programs: [Program]
    @State private var showingCreateProgram = false
    @State private var scrollToTopTrigger = false
    @State private var showingExercises = false
    @State private var showingSettings = false
    
    private var activeProgram: Program? {
        programs.first(where: { $0.isActive })
    }
    
    // ... (rest of vars)

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.xl) {
                            
                            if programs.isEmpty {
                                // Empty State
                                VStack(spacing: DesignSystem.Spacing.lg) {
                                    Spacer()
                                        .frame(height: 100)
                                    
                                    Image(systemName: "dumbbell.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                                    
                                    Text("Нет программ".localized())
                                        .font(DesignSystem.Typography.title2())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                    
                                    Text("Создайте свою первую программу тренировок".localized())
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    Button(action: { loadDefaultPrograms() }) {
                                        Text("Загрузить стандартные".localized())
                                            .font(DesignSystem.Typography.headline())
                                            .foregroundColor(DesignSystem.Colors.neonGreen)
                                            .padding()
                                            .background(DesignSystem.Colors.neonGreen.opacity(0.1))
                                            .cornerRadius(DesignSystem.CornerRadius.medium)
                                    }
                                    .padding(.top)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 50)
                            } else {
                                // Content
                                VStack(spacing: DesignSystem.Spacing.xxl) {
                                    
                                    // Active Program Section
                                    if let active = activeProgram {
                                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                            Label("АКТИВНАЯ ПРОГРАММА".localized(), systemImage: "bolt.fill")
                                                .font(DesignSystem.Typography.caption())
                                                .foregroundColor(DesignSystem.Colors.neonGreen)
                                                .tracking(2)
                                                .padding(.horizontal, DesignSystem.Spacing.lg)
                                            
                                            ActiveProgramCard(program: active, isHighlighted: scrollToTopTrigger)
                                                .padding(.horizontal, DesignSystem.Spacing.lg)
                                                .id("activeProgram")
                                        }
                                    }
                                    
                                    // All Programs Section
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                        HStack {
                                            Label("ВСЕ ПРОГРАММЫ".localized(), systemImage: "list.bullet.clipboard")
                                                .font(DesignSystem.Typography.caption())
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                                .tracking(2)
                                            
                                            Spacer()
                                            
                                            Text("\(programs.count)")
                                                .font(DesignSystem.Typography.caption())
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(DesignSystem.Colors.secondaryText.opacity(0.1))
                                                .clipShape(Capsule())
                                        }
                                        .padding(.horizontal, DesignSystem.Spacing.lg)
                                        
                                        LazyVStack(spacing: DesignSystem.Spacing.lg) {
                                            ForEach(programs.filter { $0.id != activeProgram?.id }) { program in
                                                ProgramCard(program: program) {
                                                    scrollToTop(proxy: proxy)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, DesignSystem.Spacing.lg)
                                    }
                                }
                                .padding(.vertical, DesignSystem.Spacing.xl)
                            }
                        }
                        .padding(.bottom, 100) // Space for FAB
                    }
                }
                
                // FAB to create new program
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingCreateProgram = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: 60, height: 60)
                                .background(DesignSystem.Colors.neonGreen)
                                .clipShape(Circle())
                                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.4), radius: 10, x: 0, y: 4)
                        }
                        .padding(DesignSystem.Spacing.xl)
                    }
                }
            }
            // Seeding removed — handled exclusively by ContentViewWrapper.task to prevent race-condition duplicates

            .navigationTitle(Text("Программы".localized()))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                     UserProfileButton {
                        showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingCreateProgram) {
                ProgramEditorView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private func loadDefaultPrograms() {
        ProgramSeeder.seedProgramsIfNeeded(context: modelContext)
    }
    
    private func scrollToTop(proxy: ScrollViewProxy) {
        // Wait for the view to update with the new active program
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Highlight animation
            scrollToTopTrigger = true
            
            // Scroll to active program with animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                proxy.scrollTo("activeProgram", anchor: .top)
            }
            
            // Remove highlight after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    scrollToTopTrigger = false
                }
            }
        }
    }
}

// MARK: - Active Program Card

struct ActiveProgramCard: View {
    let program: Program
    var isHighlighted: Bool = false
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
                            Text(program.name.localized())
                                .font(DesignSystem.Typography.title())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            if !program.desc.isEmpty {
                                Text(program.desc.localized())
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
                        
                        Label("\(program.days.count) дней".localized(), systemImage: "calendar.badge.clock")
                            .font(DesignSystem.Typography.callout())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    // Edit button
                    Button(action: { showingEditor = true }) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "pencil")
                            Text("Редактировать программу".localized())
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
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .stroke(isHighlighted ? DesignSystem.Colors.neonGreen : Color.clear, lineWidth: 3)
                .shadow(color: isHighlighted ? DesignSystem.Colors.neonGreen.opacity(0.5) : Color.clear, radius: 10)
        )
        .sheet(isPresented: $showingEditor) {
            ProgramEditorView(existingProgram: program)
        }
    }
    
    private func colorForWorkoutType(_ type: WorkoutType) -> Color {
        switch type {
        case .strength:
            return .blue
        case .repsOnly:
            return .purple
        case .duration:
            return .orange
        }
    }
}

// MARK: - Program Card

struct ProgramCard: View {
    let program: Program
    var onActivate: (() -> Void)? = nil
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
                            Text(program.name.localized())
                                .font(DesignSystem.Typography.title())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            if !program.desc.isEmpty {
                                Text(program.desc.localized())
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
                        
                        Label("\(program.days.count) дней".localized(), systemImage: "calendar.badge.clock")
                            .font(DesignSystem.Typography.callout())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    // Кнопка активации
                    HStack(spacing: DesignSystem.Spacing.xl) {
                        
                        if !program.isActive {
                            Button(action: { activateProgram() }) {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Image(systemName: "play.fill")
                                    Text("Активировать".localized())
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
        
        // Trigger Cloud Sync for Active Program (Profile)
        Task {
            // Re-fetch profile to ensure we have latest context
            let profileDescriptor = FetchDescriptor<UserProfile>()
            if let profile = try? modelContext.fetch(profileDescriptor).first {
                await SyncManager.shared.syncUserProfile(
                    profile: profile,
                    activeProgram: program,
                    context: modelContext
                )
            }
        }
        
        // Скролл к активной программе
        onActivate?()
    }
    
    private func colorForWorkoutType(_ type: WorkoutType) -> Color {
        switch type {
        case .strength:
            return .blue
        case .repsOnly:
            return .purple
        case .duration:
            return .orange
        }
    }
}


#Preview {
    ProgramView()
        .modelContainer(for: Program.self, inMemory: true)
}

