//
//  WorkoutGuideView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct WorkoutGuideView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header Image & Title
                    ZStack(alignment: .bottomLeading) {
                        Image("workout_header")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [.black.opacity(0.7), .clear],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .cornerRadius(DesignSystem.CornerRadius.large)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Гайд по тренировкам")
                                .font(DesignSystem.Typography.title2())
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                            Text("Научный подход")
                                .font(DesignSystem.Typography.subheadline())
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(radius: 4)
                        }
                        .padding(DesignSystem.Spacing.lg)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    // Введение
                    Text("Мышцы не растут на тренировке — они растут во время отдыха. Тренировка — это стресс, который заставляет организм адаптироваться. Чтобы расти, нужно дать правильный стимул.")
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .multilineTextAlignment(.leading)

                    // 1. Как растут мышцы
                    SectionCard(title: "1. Механизмы роста", icon: "waveform.path.ecg", color: .purple) {
                        Text("Гипертрофия (рост мышц) запускается тремя факторами:")
                            .font(DesignSystem.Typography.body())
                        
                        BulletPoint(icon: "dumbbell.fill", title: "Механическое напряжение", text: "Главный фактор. Это работа с тяжелыми весами или близко к отказу.")
                        BulletPoint(icon: "drop.fill", title: "Метаболический стресс", text: "Ощущение «жжения» и пампинг (накопление крови в мышце).")
                        BulletPoint(icon: "hammer.fill", title: "Микротравмы", text: "Легкая боль после тренировки — сигнал к восстановлению.")
                    }
                    
                    // 2. Отказ и Повторения
                    SectionCard(title: "2. До отказа или нет?", icon: "exclamationmark.triangle.fill", color: .red) {
                        Text("Отказ — это когда ты физически не можешь сделать еще одно повторение.")
                             .font(DesignSystem.Typography.body())
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "circle.fill").foregroundColor(.green).font(.caption)
                                Text("Золотая середина (RIR 1-3)").bold().foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            Text("Останавливайся за 1–3 повторения до полного отказа. Это дает такой же рост, но меньше утомляет нервную систему.")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            HStack {
                                Image(systemName: "circle.fill").foregroundColor(.red).font(.caption)
                                Text("Полный отказ").bold().foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            Text("Используй редко, в основном в изолированных упражнениях (на бицепс, трицепс).")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    // 3. Объем и Прогрессия
                    SectionCard(title: "3. Сколько тренироваться?", icon: "chart.bar.fill", color: .blue) {
                        Text("Объем = количество рабочих подходов в неделю.")
                             .font(DesignSystem.Typography.body())
                        
                        ComparisonRow(left: "Новичок", right: "6-10 подходов", text: "На каждую группу мышц в неделю.")
                        ComparisonRow(left: "Опытный", right: "10-20 подходов", text: "Нужно больше стимула для роста.")
                        
                        Text("Главный закон прогресса:")
                            .bold()
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .padding(.top, 8)
                        Text("На каждой тренировке старайся сделать чуть больше: добавить вес, повторение или улучшить технику.")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    // 4. Сила vs Масса
                    SectionCard(title: "4. Сила или Масса?", icon: "scalemass.fill", color: .orange) {
                        ComparisonRow(left: "Сила", right: "1-5 повторов", text: "Тяжелые веса, длинный отдых (3-5 мин). Тренирует нервную систему.")
                        ComparisonRow(left: "Масса", right: "6-15 повторов", text: "Средние веса, баланс напряжения и утомления. Идеально для бодибилдинга.")
                    }
                    
                    // 5. Структура Тренировки (PPL)
                    SectionCard(title: "5. Сплит «Тяни-Толкай»", icon: "figure.strengthtraining.traditional", color: .cyan) {
                         Text("Самая популярная схема тренировок (Push-Pull-Legs):")
                             .font(DesignSystem.Typography.body())
                        
                         BulletPoint(icon: "arrow.up", title: "Толкай (Push)", text: "Грудь, Плечи, Трицепс.")
                         BulletPoint(icon: "arrow.down", title: "Тяни (Pull)", text: "Спина, Бицепс, Задняя дельта.")
                         BulletPoint(icon: "figure.walk", title: "Ноги (Legs)", text: "Квадрицепс, Бицепс бедра, Ягодицы.")
                    }
                    
                    // 6. Кардио и Восстановление
                    SectionCard(title: "6. Кардио и Сон", icon: "heart.fill", color: .green) {
                        Text("Рост происходит во сне, а не в зале.")
                             .font(DesignSystem.Typography.body())
                        
                        BulletPoint(icon: "bed.double.fill", title: "Сон", text: "Спи минимум 7-8 часов. Недосып снижает тестостерон.")
                        BulletPoint(icon: "figure.run", title: "Зона 2 (Легкое кардио)", text: "Бег/ходьба, где можно говорить. Улучшает восстановление между подходами.")
                        BulletPoint(icon: "battery.100", title: "Разгрузка (Deload)", text: "Каждые 6-8 недель снижай нагрузки вдвое, чтобы дать телу восстановиться.")
                    }

                    Spacer().frame(height: 20)
                }
            }
        }
        .navigationTitle("Тренировки")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    WorkoutGuideView()
}
