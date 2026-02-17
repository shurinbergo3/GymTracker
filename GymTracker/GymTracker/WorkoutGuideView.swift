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
                            Text("Гайд по тренировкам".localized())
                                .font(DesignSystem.Typography.title2())
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                            Text("Научный подход".localized())
                                .font(DesignSystem.Typography.subheadline())
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(radius: 4)
                        }
                        .padding(DesignSystem.Spacing.lg)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    // Введение
                    Text("Мышцы не растут на тренировке — они растут во время отдыха. Тренировка — это стресс, который заставляет организм адаптироваться. Чтобы расти, нужно дать правильный стимул.".localized())
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .multilineTextAlignment(.leading)

                    // 1. Физиология и Адаптация
                    SectionCard(title: "1. Физиология Адаптации".localized(), icon: "brain.head.profile", color: .purple) {
                        Text("Организм стремится к равновесию (гомеостазу). Тренировка — это контролируемый стресс, который нарушает это равновесие.".localized())
                             .font(DesignSystem.Typography.body())
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.caption)
                                Text("Общий Адаптационный Синдром (GAS)".localized()).bold().foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            Text("1. Тревога: Утомление и микротравмы после нагрузки.\n2. Сопротивление: Восстановление и суперкомпенсация (рост).\n3. Истощение: Перетренированность, если нет восстановления.".localized())
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }

                    // 2. Прогрессивная нагрузка
                    SectionCard(title: "2. Прогрессивная Нагрузка".localized(), icon: "chart.line.uptrend.xyaxis", color: .green) {
                        Text("Краеугольный камень успеха. Чтобы мышцы росли, требования к ним должны постоянно возрастать.".localized())
                             .font(DesignSystem.Typography.body())
                        
                        BulletPoint(icon: "dumbbell.fill", title: "Интенсивность".localized(), text: "Увеличение рабочего веса. Главный драйвер для натурального атлета.".localized())
                        BulletPoint(icon: "chart.bar.fill", title: "Объем".localized(), text: "Больше подходов или повторений с тем же весом.".localized())
                        BulletPoint(icon: "timer", title: "Плотность".localized(), text: "Сокращение отдыха между подходами (метаболический стресс).".localized())
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        Text("Модели прогрессии:".localized())
                            .font(DesignSystem.Typography.subheadline())
                            .foregroundColor(.white)
                            .padding(.top, 4)
                        
                        ComparisonRow(left: "Новички".localized(), right: "Линейная".localized(), text: "Добавляем вес каждую тренировку.".localized())
                        ComparisonRow(left: "Опытные".localized(), right: "Двойная".localized(), text: "Сначала растем в повторениях (8→12), потом добавляем вес и снижаем повторы (12→8).".localized())
                    }
                    
                    // 3. Механизмы Гипертрофии
                    SectionCard(title: "3. Механизмы Роста Мышц".localized(), icon: "figure.strengthtraining.traditional", color: .red) {
                        BulletPoint(icon: "scalemass.fill", title: "Механическое напряжение".localized(), text: "Сила, которую мышца создает для преодоления веса. Работа близко к отказу.".localized())
                        BulletPoint(icon: "flame.fill", title: "Метаболический стресс".localized(), text: "Жжение, памп, накопление лактата. Работа в 12-20 повторениях.".localized())
                        BulletPoint(icon: "bandage.fill", title: "Мышечное повреждение".localized(), text: "Микроразрывы волокон. Акцент на негативной фазе (опускание веса).".localized())
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Рекомпозиция тела".localized())
                                .font(.headline).foregroundColor(.white)
                            Text("Одновременное сжигание жира и рост мышц возможен! Нужен умеренный дефицит калорий (200-300), высокий белок (1.6-2.4г/кг) и силовой тренинг.".localized())
                                .font(.caption).foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }

                    // 4. Методология Тренировок
                    SectionCard(title: "4. Методология".localized(), icon: "list.bullet.rectangle.portrait.fill", color: .blue) {
                        Text("Как построить тренировочную неделю?".localized())
                             .font(DesignSystem.Typography.body())
                        
                        ComparisonRow(left: "Full Body".localized(), right: "2-4 раза/нед".localized(), text: "Проработка всего тела. Идеально для новичков.".localized())
                        ComparisonRow(left: "Upper/Lower".localized(), right: "4 раза/нед".localized(), text: "Разделение на Верх и Низ. Больше объема на мышцу.".localized())
                        ComparisonRow(left: "Pull/Push/Legs".localized(), right: "3-6 раз/нед".localized(), text: "Тяни/Толкай/Ноги. Для продвинутых и частых тренировок.".localized())
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        Text("Кардио-протоколы:".localized())
                            .font(.headline).foregroundColor(.white)
                        
                        BulletPoint(icon: "figure.walk", title: "LISS (Zone 2)".localized(), text: "Низкая интенсивность, долго (30-60 мин). Жиросжигание и восстановление.".localized())
                        BulletPoint(icon: "bolt.fill", title: "HIIT".localized(), text: "Интервалы высокой интенсивности. Разгоняет метаболизм, но утомляет ЦНС.".localized())
                    }
                    
                    // 5. Периодизация и Восстановление
                    SectionCard(title: "5. Периодизация и Deload".localized(), icon: "arrow.triangle.2.circlepath", color: .orange) {
                        Text("Нельзя тренироваться тяжело вечно. Нужны циклы нагрузок.".localized())
                             .font(DesignSystem.Typography.body())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "battery.100").foregroundColor(.green)
                                Text("Разгрузочная неделя (Deload)".localized()).bold().foregroundColor(.white)
                            }
                            Text("Каждые 4-8 недель снижай объем на 50%, чтобы дать ЦНС и связкам восстановиться.".localized())
                                .font(.caption).foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        BulletPoint(icon: "bed.double.fill", title: "Сон".localized(), text: "Минимум 7-9 часов. Дефицит сна убивает тестостерон и повышает кортизол.".localized())
                        BulletPoint(icon: "figure.roll", title: "Прехаб".localized(), text: "Укрепление уязвимых зон (ротаторы плеча, колени, поясница).".localized())
                    }

                    // 6. Женский тренинг и Питание
                    SectionCard(title: "6. Питание и Женский цикл".localized(), icon: "fork.knife", color: .pink) {
                        Text("Специфика женского тренинга".localized())
                             .font(.headline).foregroundColor(.white)
                        
                        BulletPoint(icon: "1.circle", title: "Фолликулярная фаза".localized(), text: "В начале цикла сил больше. Время для силовых рекордов и HIIT.".localized())
                        BulletPoint(icon: "2.circle", title: "Лютеиновая фаза".localized(), text: "После овуляции силы падают. Лучше снизить интенсивность, делать больше кардио.".localized())
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        Text("Топливо для результатов".localized())
                            .font(.headline).foregroundColor(.white)
                        
                        BulletPoint(icon: "drop.triangle", title: "Белок".localized(), text: "Строительный материал. 1.6 - 2.2 г на кг веса тела.".localized())
                        BulletPoint(icon: "bolt", title: "Креатин".localized(), text: "Самая изученная добавка (Tier A). Дает силу и энергию.".localized())
                        BulletPoint(icon: "cup.and.saucer.fill", title: "Кофеин".localized(), text: "Снижает усталость и повышает производительность.".localized())
                    }
                    
                    Spacer().frame(height: 20)
                }
            }
        }
        .navigationTitle(Text("Тренировки".localized()))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    WorkoutGuideView()
}
