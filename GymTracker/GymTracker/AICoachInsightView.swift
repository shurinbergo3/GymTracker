//
//  AICoachInsightView.swift
//  GymTracker
//
//  Rich, structured rendering for the AI coach's cycle analysis / brief, plus
//  the post-workout summary card.
//
//  The analysis prompt asks the model for a numbered structure (1) … 5)). Rather
//  than dumping that as a flat paragraph, we parse it into labelled sections and
//  render each as its own accented block — a verdict badge, "what worked",
//  "improve", and the next-session plan with the exercise/number rows pulled out.
//
//  Parsing is intentionally forgiving: if the reply isn't numbered (e.g. a
//  free-form follow-up answer) we fall back to a single block so nothing breaks.
//

import SwiftUI
import SwiftData

// MARK: - Parsing

/// One labelled section of an AI analysis.
struct AICoachInsightBlock: Identifiable {
    let id = UUID()
    let index: Int          // 1-based section number (0 when unstructured)
    let title: String?      // e.g. "Вердикт" — already in the user's language
    let body: String        // remaining text for the section

    /// Plan-style "Name: 80 × 8/8/7" rows, extracted when present so we can
    /// render them as tidy chips instead of a wall of text.
    var planRows: [(name: String, value: String)] {
        body.split(whereSeparator: \.isNewline).compactMap { raw in
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard let colon = line.firstIndex(of: ":") else { return nil }
            let name = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            // Only treat as a plan row when the value carries a number — avoids
            // misreading ordinary sentences that happen to contain a colon.
            guard !name.isEmpty, !value.isEmpty,
                  value.rangeOfCharacter(from: .decimalDigits) != nil else { return nil }
            return (name, value)
        }
    }

    /// Body with the plan rows stripped out (so we don't render them twice).
    var prose: String {
        let rowNames = Set(planRows.map { $0.name })
        let kept = body.split(whereSeparator: \.isNewline).filter { raw in
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard let colon = line.firstIndex(of: ":") else { return !line.isEmpty }
            let name = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            return !rowNames.contains(name)
        }
        return kept.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum AICoachInsightParser {

    /// Splits an analysis into numbered blocks. Falls back to a single block
    /// when the text isn't in the expected numbered form.
    static func parse(_ text: String) -> [AICoachInsightBlock] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var blocks: [AICoachInsightBlock] = []
        var currentIndex: Int? = nil
        var currentTitle: String? = nil
        var currentBody: [String] = []

        func flush() {
            guard let idx = currentIndex else { return }
            let body = currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            blocks.append(AICoachInsightBlock(index: idx, title: currentTitle, body: body))
            currentTitle = nil
            currentBody = []
        }

        for rawLine in trimmed.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            if let (num, rest) = leadingNumber(line) {
                flush()
                currentIndex = num
                // Split "Вердикт — текст" / "Вердикт: текст" into title + body.
                let (title, body) = splitTitle(rest)
                currentTitle = title
                if let body, !body.isEmpty { currentBody.append(body) }
            } else if currentIndex != nil {
                currentBody.append(line)
            } else {
                // Preamble before any number — start an implicit block 0.
                currentIndex = currentIndex ?? 0
                currentBody.append(line)
            }
        }
        flush()

        // No numbered structure detected → one plain block.
        if blocks.isEmpty || (blocks.count == 1 && blocks[0].index == 0 && blocks[0].title == nil) {
            return [AICoachInsightBlock(index: 0, title: nil, body: trimmed)]
        }
        return blocks
    }

    /// Returns (number, remainder) for lines like "1) ...", "2. ...", "3 - ...".
    private static func leadingNumber(_ line: String) -> (Int, String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first, first.isNumber else { return nil }
        var digits = ""
        var idx = trimmed.startIndex
        while idx < trimmed.endIndex, trimmed[idx].isNumber {
            digits.append(trimmed[idx])
            idx = trimmed.index(after: idx)
        }
        guard let num = Int(digits), idx < trimmed.endIndex else { return nil }
        // Require a separator so we don't eat "10 повторов" as a heading.
        let sep = trimmed[idx]
        guard sep == ")" || sep == "." || sep == ":" else { return nil }
        let rest = String(trimmed[trimmed.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
        guard num >= 1, num <= 9 else { return nil }
        return (num, rest)
    }

    private static func splitTitle(_ s: String) -> (String?, String?) {
        // Prefer an em/en dash separator; fall back to colon.
        for sep in [" — ", " – ", " - ", ": "] {
            if let r = s.range(of: sep) {
                let title = String(s[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let body = String(s[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                if title.count <= 40 { return (title.isEmpty ? nil : title, body) }
            }
        }
        // Short single line → treat the whole thing as a title.
        if s.count <= 40 && !s.contains(".") { return (s, nil) }
        return (nil, s)
    }
}

// MARK: - Section styling

private struct InsightStyle {
    let icon: String
    let color: Color

    static func forIndex(_ index: Int) -> InsightStyle {
        switch index {
        case 1: return .init(icon: "checkmark.seal.fill", color: DesignSystem.Colors.neonGreen)
        case 2: return .init(icon: "hand.thumbsup.fill", color: .green)
        case 3: return .init(icon: "arrow.up.forward.circle.fill", color: .orange)
        case 4: return .init(icon: "calendar.badge.clock", color: DesignSystem.Colors.accentPurple)
        case 5: return .init(icon: "flame.fill", color: .pink)
        default: return .init(icon: "sparkles", color: DesignSystem.Colors.neonGreen)
        }
    }
}

// MARK: - Insight view

/// Renders an analysis string as a stack of accented section cards.
struct AICoachInsightView: View {
    let text: String
    /// When set, only the first N blocks are shown (compact preview mode).
    var maxBlocks: Int? = nil

    private var blocks: [AICoachInsightBlock] {
        let all = AICoachInsightParser.parse(text)
        if let n = maxBlocks { return Array(all.prefix(n)) }
        return all
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(blocks) { block in
                sectionCard(block)
            }
        }
    }

    @ViewBuilder
    private func sectionCard(_ block: AICoachInsightBlock) -> some View {
        let style = InsightStyle.forIndex(block.index)
        VStack(alignment: .leading, spacing: 8) {
            if block.title != nil || block.index > 0 {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(style.color.opacity(0.18))
                            .frame(width: 26, height: 26)
                        Image(systemName: style.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(style.color)
                    }
                    Text(block.title ?? sectionFallbackTitle(block.index))
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Spacer(minLength: 0)
                }
            }

            let prose = block.prose
            if !prose.isEmpty {
                Text(prose)
                    .font(DesignSystem.Typography.body())
                    .foregroundStyle(block.index > 0 ? DesignSystem.Colors.primaryText : DesignSystem.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !block.planRows.isEmpty {
                VStack(spacing: 6) {
                    ForEach(block.planRows, id: \.name) { row in
                        HStack {
                            Text(row.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text(row.value)
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(style.color)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [style.color.opacity(0.10), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(style.color.opacity(0.22), lineWidth: 0.5)
        )
    }

    private func sectionFallbackTitle(_ index: Int) -> String {
        switch index {
        case 1: return "Вердикт".localized()
        case 2: return "Что сработало".localized()
        case 3: return "Что улучшить".localized()
        case 4: return "План на следующую".localized()
        case 5: return "Фокус".localized()
        default: return "Разбор".localized()
        }
    }
}

// MARK: - Post-workout summary card

/// Compact AI analysis surfaced on the workout completion screen. Shows a live
/// "analyzing" state, then the structured verdict, and opens the full chat.
struct PostWorkoutAICard: View {
    @ObservedObject private var store = AICoachStore.shared
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var workoutManager: WorkoutManager

    @State private var showingChat = false
    @State private var auroraPhase: CGFloat = 0

    /// Latest cycle analysis for the just-finished workout.
    @Query private var analyses: [AICoachMessage]

    init() {
        let sig = AICoachStore.shared.lastWorkoutSignature
        _analyses = Query(
            filter: #Predicate<AICoachMessage> {
                $0.isCycleAnalysis && $0.kind == "assistant"
                    && $0.workoutSignature != nil && $0.workoutSignature == sig
            },
            sort: [SortDescriptor(\AICoachMessage.timestamp, order: .reverse)]
        )
    }

    private var analysis: AICoachMessage? { analyses.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if let analysis {
                AICoachInsightView(text: analysis.text, maxBlocks: 3)
                openChatButton
            } else if store.isAnalyzing {
                loadingState
            } else if let err = store.lastError {
                errorState(err)
            } else {
                loadingState
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .stroke(neonStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .shadow(color: DesignSystem.Colors.accentPurple.opacity(0.25), radius: 18, x: 0, y: 8)
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .onAppear {
            store.attach(modelContext)
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                auroraPhase = 1
            }
        }
        .sheet(isPresented: $showingChat) {
            AICoachChatSheet()
                .environment(\.modelContext, modelContext)
                .environmentObject(workoutManager)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignSystem.Colors.accentPurple, DesignSystem.Colors.neonGreen],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.black)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Разбор от ИИ-коуча".localized())
                    .font(DesignSystem.Typography.title3())
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                Text((store.isAnalyzing ? "Анализирую тренировку…" : "Персональный анализ").localized().uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.2)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
            Spacer()
        }
    }

    private var loadingState: some View {
        HStack(spacing: 12) {
            ProgressView().tint(DesignSystem.Colors.neonGreen)
            Text("Анализирую тренировку, датчики и историю…".localized())
                .font(DesignSystem.Typography.body())
                .foregroundStyle(DesignSystem.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }

    private func errorState(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text(message)
                .font(DesignSystem.Typography.body())
                .foregroundStyle(DesignSystem.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var openChatButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showingChat = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 13, weight: .bold))
                Text("Спросить коуча".localized())
                    .font(DesignSystem.Typography.headline())
                Spacer()
                Text("\(store.questionsRemaining(mode: .post))/\(AICoachStore.maxPostQuestions)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Image(systemName: "chevron.right").font(.caption.weight(.bold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(DesignSystem.Colors.neonGreen)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.08, blue: 0.16),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [DesignSystem.Colors.accentPurple.opacity(0.20), .clear],
                center: UnitPoint(x: auroraPhase, y: 0),
                startRadius: 4, endRadius: 240
            )
            RadialGradient(
                colors: [DesignSystem.Colors.neonGreen.opacity(0.12), .clear],
                center: UnitPoint(x: 1 - auroraPhase, y: 1),
                startRadius: 4, endRadius: 260
            )
        }
    }

    private var neonStroke: LinearGradient {
        LinearGradient(
            colors: [
                DesignSystem.Colors.accentPurple.opacity(0.55),
                DesignSystem.Colors.neonGreen.opacity(0.35),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}
