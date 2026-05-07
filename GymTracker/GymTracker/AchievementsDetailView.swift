//
//  AchievementsDetailView.swift
//  GymTracker
//
//  Shared building blocks for achievements UI:
//  - AchievementBadge model + global `achievementBadges` catalog
//  - HowItWorksRow (used by Progress Hub's overview tab)
//  - AvatarView (user avatar with optional photo picker)
//
//  The legacy `AchievementsDetailView` and `ProgressDetailView` sheets
//  were folded into the unified `ProgressHubView` (tabs).
//

import SwiftUI
import PhotosUI

// MARK: - Achievement model

struct AchievementBadge: Identifiable {
    let id = UUID()
    let workouts: Int
    let title: String
    let icon: String
    let tint: Color
    let blurb: String
}

let achievementBadges: [AchievementBadge] = [
    .init(workouts: 1,   title: "Первая",   icon: "flag.fill",   tint: .green,
          blurb: "Самый сложный шаг — начало. Ты его сделал."),
    .init(workouts: 5,   title: "Бронза",   icon: "medal.fill",   tint: Color(red: 0.85, green: 0.55, blue: 0.30),
          blurb: "Привычка формируется. 21 день — порог автоматизма."),
    .init(workouts: 15,  title: "Серебро",  icon: "medal.fill",   tint: Color(white: 0.78),
          blurb: "Тело уже отвечает на нагрузку — нейромышечные связи окрепли."),
    .init(workouts: 30,  title: "Золото",   icon: "medal.fill",   tint: Color(red: 1.0, green: 0.82, blue: 0.20),
          blurb: "Месяц регулярной работы. Видны первые силовые сдвиги."),
    .init(workouts: 50,  title: "Платина",  icon: "rosette",      tint: Color(red: 0.5, green: 0.85, blue: 1.0),
          blurb: "Атлетический уровень. Гипертрофия и сила работают вместе."),
    .init(workouts: 100, title: "Легенда",  icon: "crown.fill",   tint: Color(red: 1.0, green: 0.4, blue: 0.85),
          blurb: "Сотня тренировок — твоё тело и характер другие.")
]

// MARK: - HowItWorksRow

struct HowItWorksRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            Text(text)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            Spacer()
        }
    }
}

// MARK: - Avatar

struct AvatarView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var avatarStore = AvatarStore.shared
    let size: CGFloat
    /// When true, tapping the avatar opens a photo picker so the user can
    /// upload their own image. A small camera badge is shown in the corner.
    var isEditable: Bool = false

    @State private var pickerItem: PhotosPickerItem?
    @State private var showingActionSheet = false

    private var uid: String? { authManager.currentUser?.uid }

    private var localAvatarURL: URL? {
        // Read `avatarStore.version` so SwiftUI re-evaluates when the file changes.
        _ = avatarStore.version
        return avatarStore.currentFileURL(uid: uid)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarCircle

            if isEditable {
                editBadge
                    .offset(x: 2, y: 2)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .onTapGesture {
            guard isEditable else { return }
            if localAvatarURL != nil {
                showingActionSheet = true
            } else {
                isPickerPresented = true
            }
        }
        .photosPicker(
            isPresented: $isPickerPresented,
            selection: $pickerItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadAndSave(item: newItem) }
        }
        .confirmationDialog("Фото профиля".localized(), isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("Изменить фото".localized()) { isPickerPresented = true }
            Button("Удалить фото".localized(), role: .destructive) {
                avatarStore.clear(uid: uid)
            }
            Button("Отмена".localized(), role: .cancel) { }
        }
    }

    @State private var isPickerPresented = false

    // MARK: - Subviews

    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.7, blue: 0.2),
                            Color(red: 1.0, green: 0.4, blue: 0.55),
                            DesignSystem.Colors.accentPurple
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(red: 1.0, green: 0.55, blue: 0.20).opacity(0.5), radius: size / 5)

            content
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
        .overlay(
            Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var editBadge: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Colors.neonGreen)
                .frame(width: size * 0.32, height: size * 0.32)
                .shadow(color: Color.black.opacity(0.4), radius: 4, y: 2)
            Image(systemName: "camera.fill")
                .font(.system(size: size * 0.16, weight: .heavy))
                .foregroundColor(.black)
        }
        .overlay(
            Circle().stroke(DesignSystem.Colors.background, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var content: some View {
        if let local = localAvatarURL, let img = UIImage(contentsOfFile: local.path) {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
        } else if authManager.isLoggedIn, let user = authManager.currentUser {
            if let url = user.photoURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView(user.avatarInitials)
                }
                .frame(width: size, height: size)
            } else {
                initialsView(user.avatarInitials)
            }
        } else {
            Image(systemName: "bolt.fill")
                .font(.system(size: size * 0.42, weight: .heavy))
                .foregroundColor(.black)
        }
    }

    private func initialsView(_ initials: String) -> some View {
        Text(initials)
            .font(.system(size: size * 0.36, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .frame(width: size, height: size)
    }

    // MARK: - Picker handling

    private func loadAndSave(item: PhotosPickerItem) async {
        defer { Task { @MainActor in self.pickerItem = nil } }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                _ = avatarStore.save(data, for: uid)
            }
        } catch {
            #if DEBUG
            print("⚠️ AvatarView: failed to load picked photo — \(error)")
            #endif
        }
    }
}
