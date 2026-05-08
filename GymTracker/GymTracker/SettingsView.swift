//
//  SettingsView.swift
//  GymTracker
//
//  Created by Antigravity on 1/16/26.
//

import SwiftUI
import FirebaseAuth
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isHealthSyncEnabled") private var isHealthSyncEnabled = true
    @AppStorage("isAppleWatchEnabled") private var isAppleWatchEnabled = true
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    @AppStorage(AICoachPrefs.kAIPushEnabled) private var aiPushEnabled = true

    /// Singleton AI coach profile — used to drive the coach-style picker. Writes
    /// go through `AICoachStore.shared.updateCoachStyle` so other observers
    /// (Pre-Workout Brief, push, etc.) see the change immediately. We don't
    /// filter on `singletonID` here because SwiftData's @Query macro can't
    /// reference a static UUID; the table holds at most one row anyway.
    @Query private var coachProfiles: [AICoachUserProfile]

    // Use EnvironmentObject provided by WorkoutTrackerApp
    @EnvironmentObject var authManager: AuthManager

    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var requiresReauth = false
    @State private var showingWipeCoachConfirmation = false
    @State private var isWipingCoach = false
    @State private var showingSignOutConfirmation = false
    @State private var showingOnboardingPreview = false

    private let supportTelegramURL = URL(string: "https://t.me/sumotry")!
    private let supportEmailURL = URL(string: "mailto:sumotry@gmail.com?subject=GymTracker%20Support")!
    private let supportEmail = "sumotry@gmail.com"
    private let supportTelegram = "@sumotry"

    private var userEmail: String? {
        Auth.auth().currentUser?.email
    }

    private var userInitial: String {
        if let email = userEmail, let first = email.first {
            return String(first).uppercased()
        }
        return "•"
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        accountHeroCard
                        integrationsSection
                        languageSection
                        appearanceAndDataSection
                        supportSection
                        aiCoachSection
                        appInfoSection
                        deleteAccountButton
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.sm)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("settings_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done_button".localized()) { dismiss() }
                        .font(DesignSystem.Typography.headline())
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
            }
            .alert("delete_account_alert_title".localized(), isPresented: $showingDeleteConfirmation) {
                Button("cancel_button".localized(), role: .cancel) { }
                Button("delete_button".localized(), role: .destructive) {
                    Task { await handleAccountDeletion() }
                }
            } message: {
                Text("delete_account_message".localized())
            }
            .alert(String(localized: "Очистить историю AI Coach?"), isPresented: $showingWipeCoachConfirmation) {
                Button("cancel_button".localized(), role: .cancel) { }
                Button(String(localized: "Очистить"), role: .destructive) {
                    Task { await handleWipeCoach() }
                }
            } message: {
                Text(String(localized: "Все диалоги и разборы будут удалены с этого устройства и из облака. Действие нельзя отменить."))
            }
            .alert(String(localized: "Выйти из аккаунта?"), isPresented: $showingSignOutConfirmation) {
                Button("cancel_button".localized(), role: .cancel) { }
                Button(String(localized: "Выйти"), role: .destructive) {
                    authManager.signOut()
                    dismiss()
                }
            } message: {
                Text(String(localized: "Вы сможете вернуться в любой момент — данные сохранены в облаке."))
            }
            .fullScreenCover(isPresented: $showingOnboardingPreview) {
                OnboardingPreviewSheet { showingOnboardingPreview = false }
            }
            .alert("delete_error_title".localized(), isPresented: $showingDeleteError) {
                if requiresReauth {
                    Button("relogin_button".localized()) {
                        authManager.signOut()
                        dismiss()
                    }
                    Button("cancel_button".localized(), role: .cancel) {
                        requiresReauth = false
                    }
                } else {
                    Button("ok_button".localized(), role: .cancel) { }
                }
            } message: {
                Text(deleteErrorMessage)
            }
        }
    }

    // MARK: - Sections

    private var accountHeroCard: some View {
        SettingsCard {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.neonGreen,
                                    Color(red: 0.4, green: 0.85, blue: 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.45), radius: 14, x: 0, y: 4)

                    Text(userInitial)
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(.black)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(userEmail ?? "guest_user".localized())
                        .font(DesignSystem.Typography.headline())
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if let uid = Auth.auth().currentUser?.uid {
                        Text("ID · \(uid.prefix(8))")
                            .font(DesignSystem.Typography.monospaced(.caption2, weight: .regular))
                            .foregroundStyle(DesignSystem.Colors.tertiaryText)
                            .tracking(0.6)
                    }
                }

                Spacer(minLength: 0)

                Button {
                    showingSignOutConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.caption.weight(.semibold))
                        Text("sign_out_button".localized())
                            .font(DesignSystem.Typography.caption().weight(.semibold))
                    }
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(DesignSystem.Spacing.md)
        }
    }

    private var integrationsSection: some View {
        SettingsSection(title: "integrations_section".localized(), footer: "health_sync_footer".localized()) {
            SettingsCard {
                VStack(spacing: 0) {
                    SettingsToggleRow(
                        icon: "heart.fill",
                        iconColor: Color.pink,
                        title: "apple_health_sync_toggle".localized(),
                        subtitle: nil,
                        isOn: $isHealthSyncEnabled
                    )

                    SettingsInnerDivider()

                    SettingsToggleRow(
                        icon: "applewatch",
                        iconColor: DesignSystem.Colors.neonGreen,
                        title: String(localized: "Подключить Apple Watch"),
                        subtitle: String(localized: "Кольца активности на главном и в тренировке"),
                        isOn: $isAppleWatchEnabled
                    )
                    .onChange(of: isAppleWatchEnabled) { _, newValue in
                        guard newValue else { return }
                        Task { _ = await HealthManager.shared.requestAuthorization() }
                    }
                }
            }
        }
    }

    private var languageSection: some View {
        SettingsSection(title: "language_section_header".localized(), footer: "language_change_footer".localized()) {
            SettingsCard {
                VStack(spacing: 0) {
                    languageOptionRow(
                        title: "System".localized(),
                        subtitle: "Follows system settings".localized(),
                        flag: "globe",
                        tag: "system"
                    )
                    SettingsInnerDivider()
                    languageOptionRow(
                        title: "Russian".localized(),
                        subtitle: "Русский язык",
                        flag: "🇷🇺",
                        tag: "ru"
                    )
                    SettingsInnerDivider()
                    languageOptionRow(
                        title: "English".localized(),
                        subtitle: "English language",
                        flag: "🇬🇧",
                        tag: "en"
                    )
                    SettingsInnerDivider()
                    languageOptionRow(
                        title: "Polish".localized(),
                        subtitle: "Język polski",
                        flag: "🇵🇱",
                        tag: "pl"
                    )
                }
            }
        }
    }

    private func languageOptionRow(title: String, subtitle: String, flag: String, tag: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                appLanguage = tag
                LanguageManager.shared.appLanguage = tag
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: DesignSystem.Spacing.md) {
                Group {
                    if flag.unicodeScalars.contains(where: { $0.properties.isEmojiPresentation }) {
                        Text(flag).font(.system(size: 28))
                    } else {
                        Image(systemName: flag)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(DesignSystem.Colors.accent)
                    }
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.body().weight(.medium))
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }

                Spacer()

                if appLanguage == tag {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.accent.opacity(0.18))
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(DesignSystem.Colors.accent)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var appearanceAndDataSection: some View {
        SettingsSection(title: String(localized: "Облако и данные")) {
            SettingsCard {
                NavigationLink {
                    DataManagementView()
                } label: {
                    SettingsRowContent(
                        icon: "externaldrive.badge.icloud",
                        iconTint: DesignSystem.Colors.accent,
                        iconBackground: DesignSystem.Colors.accent.opacity(0.18),
                        title: String(localized: "Управление данными"),
                        subtitle: String(localized: "Резервные копии и синхронизация"),
                        accessory: .chevron
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var supportSection: some View {
        SettingsSection(
            title: "support_section".localized(),
            footer: String(localized: "Мы отвечаем обычно в течение дня.")
        ) {
            SettingsCard {
                VStack(spacing: 0) {
                    Link(destination: supportTelegramURL) {
                        SettingsRowContent(
                            icon: "paperplane.fill",
                            iconTint: Color(red: 0.15, green: 0.65, blue: 0.95),
                            iconBackground: Color(red: 0.15, green: 0.65, blue: 0.95).opacity(0.18),
                            title: "Telegram",
                            subtitle: supportTelegram,
                            accessory: .external
                        )
                    }
                    .buttonStyle(.plain)

                    SettingsInnerDivider()

                    Link(destination: supportEmailURL) {
                        SettingsRowContent(
                            icon: "envelope.fill",
                            iconTint: DesignSystem.Colors.accent,
                            iconBackground: DesignSystem.Colors.accent.opacity(0.18),
                            title: "Email",
                            subtitle: supportEmail,
                            accessory: .external
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var aiCoachSection: some View {
        SettingsSection(
            title: "AI Coach",
            footer: String(localized: "Удалит все диалоги, разборы и кеш дайджеста — локально и в облаке. Следующая тренировка начнёт историю с чистого листа.")
        ) {
            SettingsCard {
                VStack(spacing: 0) {
                    coachStyleRow
                    SettingsInnerDivider()
                    SettingsToggleRow(
                        icon: "bell.badge.fill",
                        iconColor: DesignSystem.Colors.accentPurple,
                        title: String(localized: "Push-уведомления от ИИ"),
                        subtitle: String(localized: "Напоминания, разборы и инсайты от коуча"),
                        isOn: $aiPushEnabled
                    )
                    .onChange(of: aiPushEnabled) { _, isOn in
                        if isOn {
                            let ctx = modelContext
                            Task { @MainActor in
                                await AICoachNotificationService.rescheduleSmartReminder(modelContext: ctx)
                                await AICoachNotificationService.rescheduleRecoveryAlertIfNeeded(
                                    healthManager: HealthManager.shared
                                )
                                await AICoachNotificationService.rescheduleWeeklyWrappedPush()
                            }
                        } else {
                            AICoachNotificationService.cancelAll()
                        }
                    }
                    SettingsInnerDivider()
                    Button {
                        showingWipeCoachConfirmation = true
                    } label: {
                        SettingsRowContent(
                            icon: "sparkles",
                            iconTint: DesignSystem.Colors.accentPurple,
                            iconBackground: DesignSystem.Colors.accentPurple.opacity(0.18),
                            title: String(localized: "Очистить историю AI Coach"),
                            subtitle: nil,
                            accessory: isWipingCoach ? .progress : .destructiveIcon("trash")
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isWipingCoach)
                }
            }
        }
    }

    /// Picker for the coach persona. Persists through `AICoachStore` so the
    /// next reply (pre-brief, post-analysis, follow-up) immediately uses the
    /// new tone without a relaunch.
    private var coachStyleRow: some View {
        let current = coachProfiles.first?.coachStyle ?? .friendly
        return Menu {
            ForEach(AICoachStyle.allCases) { style in
                Button {
                    AICoachStore.shared.attach(modelContext)
                    AICoachStore.shared.updateCoachStyle(style)
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    Label {
                        Text(style.titleKey)
                    } icon: {
                        if style == current {
                            Image(systemName: "checkmark")
                        } else {
                            Text(style.emoji)
                        }
                    }
                }
            }
        } label: {
            SettingsRowContent(
                icon: "person.wave.2.fill",
                iconTint: DesignSystem.Colors.neonGreen,
                iconBackground: DesignSystem.Colors.neonGreen.opacity(0.18),
                title: String(localized: "Стиль коуча"),
                subtitle: localizedTitle(for: current),
                accessory: .text(current.emoji)
            )
        }
        .buttonStyle(.plain)
    }

    private func localizedTitle(for style: AICoachStyle) -> String {
        switch style {
        case .strict:    return String(localized: "Жёсткий")
        case .friendly:  return String(localized: "Дружелюбный")
        case .technical: return String(localized: "Технарь")
        case .motivator: return String(localized: "Мотиватор")
        }
    }

    private var appInfoSection: some View {
        SettingsSection(title: "about_section".localized()) {
            SettingsCard {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingOnboardingPreview = true
                } label: {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Image("BrandLogo")
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("BODY FORGE")
                                .font(DesignSystem.Typography.body().weight(.heavy))
                                .tracking(1.2)
                                .foregroundStyle(DesignSystem.Colors.primaryText)
                            Text("version_label".localized())
                                .font(DesignSystem.Typography.caption())
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }

                        Spacer()

                        Text(appVersion)
                            .font(DesignSystem.Typography.monospaced(.footnote, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(Color.white.opacity(0.06))
                            )
                    }
                    .padding(DesignSystem.Spacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var deleteAccountButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.caption.weight(.semibold))
                Text("delete_account_button".localized())
                    .font(DesignSystem.Typography.caption().weight(.semibold))
            }
            .foregroundStyle(Color.red.opacity(0.9))
            .padding(.vertical, DesignSystem.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                    .fill(Color.red.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                    .stroke(Color.red.opacity(0.25), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, DesignSystem.Spacing.md)
    }

    // MARK: - Actions

    private func handleWipeCoach() async {
        isWipingCoach = true
        AICoachStore.shared.attach(modelContext)
        await AICoachStore.shared.wipeAll()
        isWipingCoach = false
    }

    private func handleAccountDeletion() async {
        do {
            try await authManager.deleteAccount(modelContext: modelContext)
            await MainActor.run { dismiss() }
        } catch let error as NSError {
            await MainActor.run {
                if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    requiresReauth = true
                    deleteErrorMessage = error.localizedRecoverySuggestion ?? "relogin_message".localized()
                } else {
                    requiresReauth = false
                    deleteErrorMessage = "\("delete_failed_prefix".localized()): \(error.localizedDescription)"
                }
                showingDeleteError = true
            }
        }
    }
}

// MARK: - Onboarding Preview Wrapper

private struct OnboardingPreviewSheet: View {
    let onClose: () -> Void
    @State private var done: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            OnboardingView(hasSeenOnboarding: $done)

            CloseButton(action: onClose)
                .padding(.top, 56)
                .padding(.trailing, 16)
        }
        .onChange(of: done) { _, finished in
            if finished { onClose() }
        }
    }
}

// MARK: - Reusable Settings Components

private struct SettingsSection<Content: View>: View {
    let title: String
    var footer: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(DesignSystem.Typography.sectionHeader())
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
                .tracking(1.4)
                .padding(.leading, DesignSystem.Spacing.sm)

            content

            if let footer {
                Text(footer)
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.top, 2)
            }
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
    }
}

private struct SettingsInnerDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 0.5)
            .padding(.leading, 60)
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconColor.opacity(0.18))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.body().weight(.medium))
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                    if let subtitle {
                        Text(subtitle)
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    }
                }
            }
        }
        .tint(DesignSystem.Colors.neonGreen)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, 10)
    }
}

private enum SettingsRowAccessory {
    case chevron
    case external
    case progress
    case destructiveIcon(String)
    case text(String)
    case none
}

private struct SettingsRowContent: View {
    let icon: String
    let iconTint: Color
    let iconBackground: Color
    let title: String
    let subtitle: String?
    let accessory: SettingsRowAccessory

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconBackground)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(iconTint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.body().weight(.medium))
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                if let subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 0)

            switch accessory {
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            case .external:
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            case .progress:
                ProgressView().tint(DesignSystem.Colors.accentPurple)
            case .destructiveIcon(let name):
                Image(systemName: name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            case .text(let value):
                HStack(spacing: 6) {
                    Text(value)
                        .font(DesignSystem.Typography.body())
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.tertiaryText)
                }
            case .none:
                EmptyView()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
        .modelContainer(for: [UserProfile.self, WorkoutSession.self, BodyMeasurement.self], inMemory: true)
        .preferredColorScheme(.dark)
}
