//
//  AICoachHistoryView.swift
//  GymTracker
//
//  Day-by-day archive of every conversation with the AI Coach. Pinned day
//  headers, expand/collapse per day, search-as-you-type, and a small banner
//  showing the cached weekly digest the bot uses for token economy.
//

import SwiftUI
import SwiftData

struct AICoachHistoryView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\AICoachMessage.timestamp, order: .reverse)])
    private var allMessages: [AICoachMessage]

    @Query(sort: [SortDescriptor(\AICoachWeeklySummary.generatedAt, order: .reverse)])
    private var summaries: [AICoachWeeklySummary]

    @State private var search: String = ""
    @State private var collapsedDays: Set<Date> = []

    // MARK: - Filtering / grouping

    private var filteredMessages: [AICoachMessage] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return allMessages }
        return allMessages.filter { $0.text.lowercased().contains(q) }
    }

    private var grouped: [(day: Date, messages: [AICoachMessage])] {
        let cal = Calendar.current
        var dict: [Date: [AICoachMessage]] = [:]
        for m in filteredMessages {
            let day = cal.startOfDay(for: m.timestamp)
            dict[day, default: []].append(m)
        }
        // Newest day first; messages within a day oldest → newest (chat order).
        return dict
            .map { (key, value) in
                (day: key, messages: value.sorted { $0.timestamp < $1.timestamp })
            }
            .sorted { $0.day > $1.day }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if allMessages.isEmpty {
                emptyState
            } else {
                content
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
            Text("История пуста".localized())
                .font(DesignSystem.Typography.title3())
                .foregroundStyle(DesignSystem.Colors.primaryText)
            Text("Заверши тренировку, чтобы получить первый разбор. Все диалоги с коучем сохраняются здесь.".localized())
                .font(.callout)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                searchField

                if let digest = summaries.first {
                    weeklyDigestBanner(digest)
                }

                stats

                ForEach(grouped, id: \.day) { group in
                    DaySection(
                        day: group.day,
                        messages: group.messages,
                        collapsed: collapsedDays.contains(group.day),
                        onToggle: { toggle(group.day) }
                    )
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.md)
        }
    }

    private func toggle(_ day: Date) {
        withAnimation(.easeInOut(duration: 0.18)) {
            if collapsedDays.contains(day) {
                collapsedDays.remove(day)
            } else {
                collapsedDays.insert(day)
            }
        }
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
            TextField("Поиск по истории".localized(), text: $search)
                .foregroundStyle(DesignSystem.Colors.primaryText)
                .submitLabel(.search)
            if !search.isEmpty {
                Button {
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.tertiaryText)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - Weekly digest

    private func weeklyDigestBanner(_ digest: AICoachWeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.accentPurple)
                Text("Дайджест последней недели".localized().uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.2)
                    .foregroundStyle(DesignSystem.Colors.accentPurple)
                Spacer()
                Text(formatRelative(digest.generatedAt))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
            Text(digest.text)
                .font(DesignSystem.Typography.body())
                .foregroundStyle(DesignSystem.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text(String(format: "Сжимает %d сообщений в один контекст для модели — экономит токены.".localized(), digest.sourceMessageCount))
                .font(.system(size: 10))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            LinearGradient(
                colors: [DesignSystem.Colors.accentPurple.opacity(0.18), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(DesignSystem.Colors.accentPurple.opacity(0.25), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    // MARK: - Stats strip

    private var stats: some View {
        let assistantCount = allMessages.filter { $0.isAssistant }.count
        let userCount = allMessages.filter { $0.isUser }.count
        let analysesCount = allMessages.filter { $0.isCycleAnalysis }.count

        return HStack(spacing: 8) {
            statChip(icon: "doc.text.magnifyingglass", value: "\(analysesCount)", label: "разборов".localized(), tint: DesignSystem.Colors.neonGreen)
            statChip(icon: "bubble.left.fill", value: "\(userCount)", label: "вопросов".localized(), tint: .cyan)
            statChip(icon: "sparkles", value: "\(assistantCount)", label: "ответов".localized(), tint: DesignSystem.Colors.accentPurple)
        }
    }

    private func statChip(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10, weight: .bold))
                Text(value).font(.system(size: 18, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(tint)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.0)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(tint.opacity(0.20), lineWidth: 0.5)
        )
    }

    // MARK: - Helpers

    private func formatRelative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = LanguageManager.shared.currentLocale
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Day section

private struct DaySection: View {
    let day: Date
    let messages: [AICoachMessage]
    let collapsed: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if !collapsed {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages) { msg in
                        compactRow(msg)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private var header: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatDay(day))
                        .font(DesignSystem.Typography.headline())
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                    Text(formatSecondary(day))
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }

                Spacer()

                let analyses = messages.filter { $0.isCycleAnalysis }.count
                if analyses > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(analyses)")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(DesignSystem.Colors.neonGreen)
                    .clipShape(Capsule())
                }

                Text("\(messages.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())

                Image(systemName: collapsed ? "chevron.down" : "chevron.up")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
        }
        .buttonStyle(.plain)
    }

    private func compactRow(_ msg: AICoachMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(msg.isAssistant ? DesignSystem.Colors.neonGreen : DesignSystem.Colors.accentPurple)
                .frame(width: 6, height: 6)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(msg.isAssistant ? "Коуч".localized() : "Ты".localized())
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(msg.isAssistant ? DesignSystem.Colors.neonGreen : DesignSystem.Colors.accentPurple)

                    if msg.isCycleAnalysis {
                        Text("РАЗБОР".localized())
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(0.8)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(DesignSystem.Colors.neonGreen)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Text(formatTime(msg.timestamp))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.tertiaryText)
                }

                Text(msg.text)
                    .font(DesignSystem.Typography.callout())
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func formatDay(_ d: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Сегодня".localized() }
        if cal.isDateInYesterday(d) { return "Вчера".localized() }

        let f = DateFormatter()
        f.locale = LanguageManager.shared.currentLocale
        f.dateFormat = "d MMMM"
        return f.string(from: d)
    }

    private func formatSecondary(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.currentLocale
        f.dateFormat = "EEEE, yyyy"
        return f.string(from: d).capitalized
    }

    private func formatTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.currentLocale
        f.timeStyle = .short
        return f.string(from: d)
    }
}
