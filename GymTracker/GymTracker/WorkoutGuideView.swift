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

                    // 1. Физиология и Адаптация
                    SectionCard(title: "1. Физиология Адаптации", icon: "brain.head.profile", color: .purple) {
                        Text("Организм стремится к равновесию (гомеостазу). Тренировка — это контролируемый стресс, который нарушает это равновесие.")
                             .font(DesignSystem.Typography.body())
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.caption)
                                Text("Общий Адаптационный Синдром (GAS)").bold().foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            Text("1. Тревога: Утомление и микротравмы после нагрузки.\n2. Сопротивление: Восстановление и суперкомпенсация (рост).\n3. Истощение: Перетренированность, если нет восстановления.")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }

                    // 2. Прогрессивная нагрузка
                    SectionCard(title: "2. Прогрессивная Нагрузка", icon: "chart.line.uptrend.xyaxis", color: .green) {
                        Text("Краеугольный камень успеха. Чтобы мышцы росли, требования к ним должны постоянно возрастать.")
                             .font(DesignSystem.Typography.body())
                        
                        BulletPoint(icon: "dumbbell.fill", title: "Интенсивность", text: "Увеличение рабочего веса. Главный драйвер для натурального атлета.")
                        BulletPoint(icon: "chart.bar.fill", title: "Объем", text: "Больше подходов или повторений с тем же весом.")
                        BulletPoint(icon: "timer", title: "Плотность", text: "Сокращение отдыха между подходами (метаболический стресс).")
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        Text("Модели прогрессии:")
                            .font(DesignSystem.Typography.subheadline())
                            .foregroundColor(.white)
                            .padding(.top, 4)
                        
                        ComparisonRow(left: "Новички", right: "Линейная", text: "Добавляем вес каждую тренировку.")
                        ComparisonRow(left: "Опытные", right: "Двойная", text: "Сначала растем в повторениях (8→12), потом добавляем вес и снижаем повторы (12→8).")
                    }
                    
                    // 3. Механизмы Гипертрофии
                    SectionCard(title: "3. Механизмы Роста Мышц", icon: "figure.strengthtraining.traditional", color: .red) {
                        BulletPoint(icon: "scalemass.fill", title: "Механическое напряжение", text: "Сила, которую мышца создает для преодоления веса. Работа близко к отказу.")
                        BulletPoint(icon: "flame.fill", title: "Метаболический стресс", text: "Жжение, памп, накопление лактата. Работа в 12-20 повторениях.")
                        BulletPoint(icon: "bandage.fill", title: "Мышечное повреждение", text: "Микроразрывы волокон. Акцент на негативной фазе (опускание веса).")
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Рекомпозиция тела")
                                .font(.headline).foregroundColor(.white)
                            Text("Одновременное сжигание жира и рост мышц возможен! Нужен умеренный дефицит калорий (200-300), высокий белок (1.6-2.4г/кг) и силовой тренинг.")
                                .font(.caption).foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }

                    // 4. Методология Тренировок
                    SectionCard(title: "4. Методология", icon: "list.bullet.rectangle.portrait.fill", color: .blue) {
                        Text("Как построить тренировочную неделю?")
                             .font(DesignSystem.Typography.body())
                        
                        ComparisonRow(left: "Full Body", right: "2-4 раза/нед", text: "Проработка всего тела. Идеально для новичков.")
                        ComparisonRow(left: "Upper/Lower", right: "4 раза/нед", text: "Разделение на Верх и Низ. Больше объема на мышцу.")
                        ComparisonRow(left: "Pull/Push/Legs", right: "3-6 раз/нед", text: "Тяни/Толкай/Ноги. Для продвинутых и частых тренировок.")
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        Text("Кардио-протоколы:")
                            .font(.headline).foregroundColor(.white)
                        
                        BulletPoint(icon: "figure.walk", title: "LISS (Zone 2)", text: "Низкая интенсивность, долго (30-60 мин). Жиросжигание и восстановление.")
                        BulletPoint(icon: "bolt.fill", title: "HIIT", text: "Интервалы высокой интенсивности. Разгоняет метаболизм, но утомляет ЦНС.")
                    }
                    
                    // 5. Периодизация и Восстановление
                    SectionCard(title: "5. Периодизация и Deload", icon: "arrow.triangle.2.circlepath", color: .orange) {
                        Text("Нельзя тренироваться тяжело вечно. Нужны циклы нагрузок.")
                             .font(DesignSystem.Typography.body())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "battery.100").foregroundColor(.green)
                                Text("Разгрузочная неделя (Deload)").bold().foregroundColor(.white)
                            }
                            Text("Каждые 4-8 недель снижай объем на 50%, чтобы дать ЦНС и связкам восстановиться.")
                                .font(.caption).foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        BulletPoint(icon: "bed.double.fill", title: "Сон", text: "Минимум 7-9 часов. Дефицит сна убивает тестостерон и повышает кортизол.")
                        BulletPoint(icon: "figure.roll", title: "Прехаб", text: "Укрепление уязвимых зон (ротаторы плеча, колени, поясница).")
                    }

                    // 6. Женский тренинг и Питание
                    SectionCard(title: "6. Питание и Женский цикл", icon: "fork.knife", color: .pink) {
                        Text("Специфика женского тренинга")
                             .font(.headline).foregroundColor(.white)
                        
                        BulletPoint(icon: "1.circle", title: "Фолликулярная фаза", text: "В начале цикла сил больше. Время для силовых рекордов и HIIT.")
                        BulletPoint(icon: "2.circle", title: "Лютеиновая фаза", text: "После овуляции силы падают. Лучше снизить интенсивность, делать больше кардио.")
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        Text("Топливо для результатов")
                            .font(.headline).foregroundColor(.white)
                        
                        BulletPoint(icon: "drop.triangle", title: "Белок", text: "Строительный материал. 1.6 - 2.2 г на кг веса тела.")
                        BulletPoint(icon: "bolt", title: "Креатин", text: "Самая изученная добавка (Tier A). Дает силу и энергию.")
                        BulletPoint(icon: "cup.and.saucer.fill", title: "Кофеин", text: "Снижает усталость и повышает производительность.")
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
