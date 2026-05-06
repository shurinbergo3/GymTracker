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
    @State private var showingSettings = false
    @State private var selectedCategory: ProgramCategory = .all

    @AppStorage("programs_onboarding_dismissed_v1") private var tipDismissed = false

    private var activeProgram: Program? {
        programs.first(where: { $0.isActive })
    }

    private var visiblePrograms: [Program] {
        let nonActive = programs.filter { $0.id != activeProgram?.id }
        guard selectedCategory != .all else { return nonActive }
        return nonActive.filter {
            ProgramMetadata.metadata(for: $0.name).category == selectedCategory
        }
    }

    /// Categories that actually contain programs (excluding the active one) + always include `.all`.
    private var availableCategories: [ProgramCategory] {
        let nonActive = programs.filter { $0.id != activeProgram?.id }
        let used = Set(nonActive.map { ProgramMetadata.metadata(for: $0.name).category })
        var ordered: [ProgramCategory] = [.all]
        for cat in ProgramCategory.allCases where cat != .all && used.contains(cat) {
            ordered.append(cat)
        }
        return ordered
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.xl) {
                            if programs.isEmpty {
                                emptyStateView
                            } else {
                                // Onboarding tip (dismissable)
                                if !tipDismissed {
                                    ProgramsOnboardingTip(onDismiss: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            tipDismissed = true
                                        }
                                    })
                                    .padding(.horizontal, DesignSystem.Spacing.lg)
                                    .padding(.top, DesignSystem.Spacing.md)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }

                                VStack(spacing: DesignSystem.Spacing.xxl) {
                                    // Active Program
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

                                    // Category filter
                                    if availableCategories.count > 2 {
                                        ProgramCategoryFilter(
                                            categories: availableCategories,
                                            selected: $selectedCategory
                                        )
                                    }

                                    // All Programs Section
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                        HStack {
                                            Label("ВСЕ ПРОГРАММЫ".localized(), systemImage: "list.bullet.clipboard")
                                                .font(DesignSystem.Typography.caption())
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                                .tracking(2)

                                            Spacer()

                                            Text("\(visiblePrograms.count)")
                                                .font(DesignSystem.Typography.caption())
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(DesignSystem.Colors.secondaryText.opacity(0.1))
                                                .clipShape(Capsule())
                                        }
                                        .padding(.horizontal, DesignSystem.Spacing.lg)

                                        if visiblePrograms.isEmpty {
                                            emptyCategoryView
                                                .padding(.horizontal, DesignSystem.Spacing.lg)
                                        } else {
                                            LazyVStack(spacing: DesignSystem.Spacing.lg) {
                                                ForEach(visiblePrograms) { program in
                                                    ProgramCard(program: program) {
                                                        scrollToTop(proxy: proxy)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, DesignSystem.Spacing.lg)
                                        }
                                    }
                                }
                                .padding(.vertical, DesignSystem.Spacing.xl)
                            }
                        }
                        .padding(.bottom, 100)
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

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.neonGreen.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DesignSystem.Colors.neonGreen)
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.5), radius: 20)
            }

            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Готов начать?".localized())
                    .font(DesignSystem.Typography.title())
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Text("Загрузи готовые программы или создай свою".localized())
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }

            VStack(spacing: DesignSystem.Spacing.md) {
                Button(action: { loadDefaultPrograms() }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Загрузить готовые программы".localized())
                    }
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.neonGreen)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.4), radius: 12, x: 0, y: 6)
                }

                Button(action: { showingCreateProgram = true }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "plus.circle")
                        Text("Создать свою".localized())
                    }
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(DesignSystem.Colors.neonGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.neonGreen.opacity(0.12))
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyCategoryView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            Text("В этой категории пока нет программ".localized())
                .font(DesignSystem.Typography.callout())
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxl)
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }

    // MARK: - Helpers

    private func loadDefaultPrograms() {
        ProgramSeeder.seedProgramsIfNeeded(context: modelContext)
    }

    private func scrollToTop(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scrollToTopTrigger = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                proxy.scrollTo("activeProgram", anchor: .top)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    scrollToTopTrigger = false
                }
            }
        }
    }
}

// MARK: - Onboarding Tip

private struct ProgramsOnboardingTip: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(alignment: .top) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                    Text("Как это работает".localized())
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .frame(width: 28, height: 28)
                        .background(DesignSystem.Colors.secondaryText.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                tipRow(
                    icon: "1.circle.fill",
                    title: "Выбери программу".localized(),
                    subtitle: "Готовая или своя — фильтруй по цели".localized()
                )
                tipRow(
                    icon: "2.circle.fill",
                    title: "Активируй".localized(),
                    subtitle: "Тапни «Активировать» — она встанет наверх".localized()
                )
                tipRow(
                    icon: "3.circle.fill",
                    title: "Настрой отдых".localized(),
                    subtitle: "Войди в день и задай таймер отдыха".localized()
                )
                tipRow(
                    icon: "4.circle.fill",
                    title: "Тренируйся".localized(),
                    subtitle: "Программа сама подскажет, какой день сегодня".localized()
                )
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            LinearGradient(
                colors: [
                    DesignSystem.Colors.neonGreen.opacity(0.18),
                    DesignSystem.Colors.neonGreen.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(DesignSystem.Colors.neonGreen.opacity(0.35), lineWidth: 1)
        )
    }

    private func tipRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.neonGreen)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.callout())
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Text(subtitle)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Category Filter

private struct ProgramCategoryFilter: View {
    let categories: [ProgramCategory]
    @Binding var selected: ProgramCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(categories) { category in
                    chip(for: category)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }

    private func chip(for category: ProgramCategory) -> some View {
        let isSelected = selected == category
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                selected = category
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(category.displayName)
                    .font(DesignSystem.Typography.caption())
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .black : category.color)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, 10)
            .background(
                isSelected
                ? AnyShapeStyle(category.color)
                : AnyShapeStyle(category.color.opacity(0.15))
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : category.color.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Active Program Card

struct ActiveProgramCard: View {
    let program: Program
    var isHighlighted: Bool = false
    @State private var showingEditor = false
    @State private var pulse: Bool = false

    private var typeSummary: [(type: WorkoutType, count: Int)] {
        Dictionary(grouping: program.days, by: { $0.workoutType })
            .mapValues { $0.count }
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { (type: $0.key, count: $0.value) }
    }

    private var meta: ProgramMetadata {
        ProgramMetadata.metadata(for: program.name)
    }

    var body: some View {
        NavigationLink(destination: ProgramDetailView(program: program)) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingEditor) {
            ProgramEditorView(existingProgram: program)
        }
        .onAppear { pulse = true }
    }

    // MARK: - Card

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            topRow
                .padding(.bottom, DesignSystem.Spacing.lg)

            Text(program.name.localized())
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            if !program.desc.isEmpty {
                Text(program.desc.localized())
                    .font(DesignSystem.Typography.subheadline())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(2)
                    .padding(.top, 6)
            }

            statsRow
                .padding(.top, DesignSystem.Spacing.lg)

            footerRow
                .padding(.top, DesignSystem.Spacing.md)
        }
        .padding(DesignSystem.Spacing.xl)
        .background(cardBackground)
        .overlay(highlightStroke)
        .shadow(color: DesignSystem.Colors.neonGreen.opacity(isHighlighted ? 0.0 : 0.18), radius: 24, x: 0, y: 12)
        .shadow(color: Color.black.opacity(0.45), radius: 14, x: 0, y: 8)
    }

    // MARK: - Top row

    private var topRow: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            activeIndicator
            categoryBadge
            Spacer(minLength: 8)
            editButton
        }
    }

    private var activeIndicator: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.neonGreen.opacity(0.45))
                    .frame(width: 14, height: 14)
                    .scaleEffect(pulse ? 1.8 : 1.0)
                    .opacity(pulse ? 0.0 : 0.9)
                    .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulse)
                Circle()
                    .fill(DesignSystem.Colors.neonGreen)
                    .frame(width: 8, height: 8)
                    .shadow(color: DesignSystem.Colors.neonGreen, radius: 5)
            }
            Text("АКТИВНА".localized())
                .font(.system(.caption2, design: .rounded, weight: .heavy))
                .tracking(1.4)
                .foregroundColor(DesignSystem.Colors.neonGreen)
        }
    }

    private var categoryBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: meta.category.icon)
                .font(.system(size: 10, weight: .bold))
            Text(meta.category.displayName.uppercased())
                .font(.system(.caption2, design: .rounded, weight: .heavy))
                .tracking(1)
        }
        .foregroundColor(meta.category.color)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(meta.category.color.opacity(0.18))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(meta.category.color.opacity(0.35), lineWidth: 0.5)
        )
    }

    private var editButton: some View {
        Button(action: { showingEditor = true }) {
            Image(systemName: "pencil")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(DesignSystem.Colors.neonGreen)
                .frame(width: 36, height: 36)
                .background(DesignSystem.Colors.neonGreen.opacity(0.15))
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(DesignSystem.Colors.neonGreen.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(Text("Редактировать программу".localized()))
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 0) {
            statBlock(value: "\(program.days.count)", label: "ДНЕЙ".localized())
            statDivider
            statBlock(value: "~\(meta.estimatedMinutes)", label: "мин".localized().uppercased())
            statDivider
            statBlock(
                value: meta.level.displayName.uppercased(),
                label: "Уровень".localized().uppercased(),
                valueColor: meta.level.color,
                compact: true
            )
        }
    }

    private func statBlock(value: String, label: String, valueColor: Color = DesignSystem.Colors.primaryText, compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(compact ? .callout : .title2, design: .rounded, weight: .heavy))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 28)
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack(spacing: 8) {
            ForEach(typeSummary, id: \.type) { item in
                HStack(spacing: 4) {
                    Image(systemName: item.type.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text("\(item.count)")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                }
                .foregroundColor(colorForWorkoutType(item.type))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colorForWorkoutType(item.type).opacity(0.14))
                .clipShape(Capsule())
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
    }

    // MARK: - Background

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(white: 0.08))

            // Neon glow — top-left
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            DesignSystem.Colors.neonGreen.opacity(0.20),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 5,
                        endRadius: 260
                    )
                )

            // Category tint — bottom-right
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            meta.category.color.opacity(0.12),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 5,
                        endRadius: 240
                    )
                )

            // Inner gradient stroke
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.neonGreen.opacity(0.55),
                            Color.white.opacity(0.04),
                            meta.category.color.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private var highlightStroke: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(isHighlighted ? DesignSystem.Colors.neonGreen : Color.clear, lineWidth: 3)
            .shadow(color: isHighlighted ? DesignSystem.Colors.neonGreen.opacity(0.5) : Color.clear, radius: 10)
    }

    private func colorForWorkoutType(_ type: WorkoutType) -> Color {
        switch type {
        case .strength:  return .blue
        case .repsOnly:  return .purple
        case .duration:  return .orange
        }
    }
}

// MARK: - Program Card

struct ProgramCard: View {
    let program: Program
    var onActivate: (() -> Void)? = nil
    @Environment(\.modelContext) private var modelContext

    private var meta: ProgramMetadata {
        ProgramMetadata.metadata(for: program.name)
    }

    private var typeSummary: [(type: WorkoutType, count: Int)] {
        Dictionary(grouping: program.days, by: { $0.workoutType })
            .mapValues { $0.count }
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { (type: $0.key, count: $0.value) }
    }

    var body: some View {
        NavigationLink(destination: ProgramDetailView(program: program)) {
            CardView {
                HStack(spacing: 0) {
                    // Color accent bar
                    Rectangle()
                        .fill(meta.category.color)
                        .frame(width: 4)

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        // Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                // Category + Level badges
                                HStack(spacing: 6) {
                                    HStack(spacing: 4) {
                                        Image(systemName: meta.category.icon)
                                            .font(.system(size: 10, weight: .bold))
                                        Text(meta.category.displayName.uppercased())
                                            .font(DesignSystem.Typography.caption())
                                            .fontWeight(.bold)
                                            .tracking(0.8)
                                    }
                                    .foregroundColor(meta.category.color)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(meta.category.color.opacity(0.18))
                                    .clipShape(Capsule())

                                    HStack(spacing: 4) {
                                        Image(systemName: meta.level.icon)
                                            .font(.system(size: 10, weight: .semibold))
                                        Text(meta.level.displayName)
                                            .font(DesignSystem.Typography.caption())
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(meta.level.color)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(meta.level.color.opacity(0.15))
                                    .clipShape(Capsule())
                                }

                                Text(program.name.localized())
                                    .font(DesignSystem.Typography.title3())
                                    .foregroundColor(DesignSystem.Colors.primaryText)

                                if !program.desc.isEmpty {
                                    Text(program.desc.localized())
                                        .font(DesignSystem.Typography.callout())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            if program.isActive {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                                    .font(.system(size: 28))
                            }
                        }

                        // Stats row
                        HStack(spacing: DesignSystem.Spacing.md) {
                            statItem(icon: "calendar", text: String(format: "%d дней".localized(), program.days.count))
                            statItem(icon: "clock", text: String(format: "~%d мин".localized(), meta.estimatedMinutes))

                            // Workout type icons
                            HStack(spacing: 6) {
                                ForEach(typeSummary, id: \.type) { item in
                                    HStack(spacing: 2) {
                                        Image(systemName: item.type.icon)
                                            .font(.system(size: 10))
                                            .foregroundColor(colorForWorkoutType(item.type))
                                        Text("\(item.count)")
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                }
                            }
                        }

                        // Activate button
                        if !program.isActive {
                            Button(action: { activateProgram() }) {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Image(systemName: "play.fill")
                                    Text("Активировать".localized())
                                }
                                .font(DesignSystem.Typography.headline())
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                                .background(meta.category.color)
                                .cornerRadius(DesignSystem.CornerRadius.small)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(DesignSystem.Spacing.lg)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func statItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(DesignSystem.Typography.caption())
        }
        .foregroundColor(DesignSystem.Colors.secondaryText)
    }

    private func colorForWorkoutType(_ type: WorkoutType) -> Color {
        switch type {
        case .strength: return .blue
        case .repsOnly: return .purple
        case .duration: return .orange
        }
    }

    private func activateProgram() {
        let descriptor = FetchDescriptor<Program>()
        if let allPrograms = try? modelContext.fetch(descriptor) {
            for prog in allPrograms {
                prog.isActive = false
            }
        }

        program.isActive = true
        program.startDate = Date()

        try? modelContext.save()

        NotificationCenter.default.post(
            name: Notification.Name("ActiveProgramChanged"),
            object: nil
        )

        Task {
            let profileDescriptor = FetchDescriptor<UserProfile>()
            if let profile = try? modelContext.fetch(profileDescriptor).first {
                await SyncManager.shared.syncUserProfile(
                    profile: profile,
                    activeProgram: program,
                    context: modelContext
                )
            }
        }

        onActivate?()
    }
}
