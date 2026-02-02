//
//  SleepGuideView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct SleepGuideView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header Image
                        Image("sleep_header")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [.black.opacity(0.6), .clear],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .cornerRadius(DesignSystem.CornerRadius.large)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Механика идеального сна")
                                .font(DesignSystem.Typography.title2())
                                .foregroundColor(.white)
                            Text("От биохимии до привычек")
                                .font(DesignSystem.Typography.subheadline())
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(DesignSystem.Spacing.lg)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    // 1. Почему ломается сон
                    SectionCard(
                        title: "1. Почему ломается сон?",
                        icon: "bolt.slash.fill",
                        color: .red
                    ) {
                        Text("Наши механизмы саморегуляции сбиваются из-за несоответствия среды потребностям тела.")
                            .font(DesignSystem.Typography.body())
                        
                        BulletPoint(icon: "lightbulb.slash", title: "Световое загрязнение", text: "Искусственный холодный свет блокирует мелатонин.")
                        BulletPoint(icon: "ear.badge.checkmark", title: "Шум", text: "Звуки воспринимаются как опасность (выброс адреналина).")
                        BulletPoint(icon: "figure.walk", title: "Малоподвижность", text: "Без движения не накапливается аденозин (нейромедиатор усталости).")
                    }
                    
                    // 2. Биохимия процесса
                    SectionCard(
                        title: "2. Биохимия процесса",
                        icon: "atom",
                        color: .blue
                    ) {
                        Text("Здоровый цикл строится на правильной работе гормональных пар:")
                            .font(DesignSystem.Typography.body()) // Fixed font call
                        
                        ComparisonRow(
                            left: "Серотонин", right: "Мелатонин",
                            text: "Днем на солнце вырабатывается серотонин. Если его мало, ночью не из чего производить мелатонин."
                        )
                        
                        ComparisonRow(
                            left: "Кортизол", right: "Тестостерон",
                            text: "Утро: Пик нужен для энергии."
                        )
                        
                        ComparisonRow(
                            left: "Аденозин", right: "Пролактин",
                            text: "Вечер: Сигнал отдыха и восстановления."
                        )
                    }
                    
                    // 3. Утренний протокол
                    SectionCard(
                        title: "3. Утренний протокол",
                        icon: "sun.max.fill",
                        color: .orange
                    ) {
                        Text("Цель: включиться в рабочий режим за 15 минут.")
                            .font(DesignSystem.Typography.body()) // Fixed font call
                        
                        BulletPoint(icon: "brain.head.profile", title: "Навигация ума", text: "Настройтесь на благодарность и готовность к хаосу.")
                        BulletPoint(icon: "gift.fill", title: "Первое действие", text: "Сделайте что-то приятное сразу для контекста удовольствия.")
                        BulletPoint(icon: "clock.fill", title: "Ранний подъем", text: "Вставайте в 4:30–5:00.")
                        BulletPoint(icon: "snowflake", title: "Холод", text: "Низкая температура пробуждает.")
                        BulletPoint(icon: "fork.knife", title: "Голод", text: "Низкий сахар с утра — драйвер кортизола.")
                    }
                    
                    // 4. Вечерний протокол
                    SectionCard(
                        title: "4. Вечерний протокол",
                        icon: "moon.stars.fill",
                        color: .purple
                    ) {
                        Text("Цель: состояние «упал — не помню как заснул».")
                             .font(DesignSystem.Typography.body()) // Fixed font call
                        
                        BulletPoint(icon: "thermometer.low", title: "Температурный сброс", text: "Горячая ванна -> резкое охлаждение.")
                        BulletPoint(icon: "leaf.fill", title: "Голод", text: "Низкий сахар помогает уснуть.")
                        BulletPoint(icon: "wind", title: "Свежий воздух", text: "Доступ к кислороду обязателен.")
                        BulletPoint(icon: "eye.slash.fill", title: "Свет и звук", text: "Свечи, blue-blocker очки, беруши.")
                    }
                    
                    // 5. Сапплементация
                    SectionCard(
                        title: "5. БАДы",
                        icon: "pills.fill",
                        color: .green
                    ) {
                        Text("Важно корректировать химию осторожно.")
                             .font(DesignSystem.Typography.body()) // Fixed font call
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Не рекомендуется:", systemImage: "xmark.circle.fill").foregroundColor(.red).bold()
                            Text("Мелатонин: Блокирует собственную выработку, повышает пролактин.")
                                 .font(DesignSystem.Typography.caption()) // Fixed font call
                                .foregroundColor(.gray)
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Рекомендуется (за пару часов):", systemImage: "checkmark.circle.fill").foregroundColor(.green).bold()
                            Group {
                                Text("• Глицин: 1–5 г")
                                Text("• Триптофан: 1–2 г")
                                Text("• ГАБА (GABA) и L-теанин")
                                Text("• Магний: Для успокоения")
                                Text("• Тирозин (1–10 г): Если истощен дофамин")
                            }
                            .font(DesignSystem.Typography.caption()) // Fixed font call
                            .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
        }
        .navigationTitle("Сон")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Text(title)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Spacer()
            }
            .padding(.bottom, 4)
            
            content
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

struct BulletPoint: View {
    let icon: String
    let title: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(DesignSystem.Colors.accent)
                .font(.caption)
                .frame(width: 20, height: 20)
                .background(DesignSystem.Colors.accent.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.body()) // Fixed font call
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Text(text)
                    .font(DesignSystem.Typography.caption()) // Fixed font call
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ComparisonRow: View {
    let left: String
    let right: String
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(left)
                    .bold()
                    .foregroundColor(.orange)
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(right)
                    .bold()
                    .foregroundColor(.purple)
            }
            .font(DesignSystem.Typography.caption()) // Fixed font
            
            Text(text)
                .font(DesignSystem.Typography.caption()) // Fixed font
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding(.vertical, 4)
    }
}
