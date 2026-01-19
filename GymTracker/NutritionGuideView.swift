//
//  NutritionGuideView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct NutritionGuideView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header Image & Title
                    ZStack(alignment: .bottomLeading) {
                        Image("nutrition_header")
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
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Гид по питанию")
                                .font(DesignSystem.Typography.title2())
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                            Text("Просто о сложном")
                                .font(DesignSystem.Typography.subheadline())
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(radius: 4)
                        }
                        .padding(DesignSystem.Spacing.lg)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    // Введение
                    Text("Правильное питание — это не диета, а топливо для твоих побед. Еда влияет на энергию, настроение и восстановление мышц. Мы не будем считать сложные формулы, а разберем базу, которая работает.")
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .multilineTextAlignment(.leading)

                    // Калькулятор
                    CalorieCalculatorView()
                        .padding(.bottom, 8)
                    
                    // Глава 1. Энергия
                    SectionCard(title: "1. Энергия и Калории", icon: "flame.fill", color: .orange) {
                        Text("Все просто: количество энергии (калорий) определяет твой вес.")
                            .font(DesignSystem.Typography.body())
                        
                        BulletPoint(icon: "scalemass", title: "Баланс", text: "Ешь больше, чем тратишь — набираешь. Тратишь больше — худеешь.")
                        BulletPoint(icon: "waveform.path.ecg", title: "Базовый обмен", text: "Энергия, которую тело тратит в покое (на дыхание, работу сердца).")
                        BulletPoint(icon: "figure.walk", title: "Активность", text: "Любое движение (ходьба, уборка, тренировка) сжигает калории.")
                    }
                    
                    // Глава 2. БЖУ
                    SectionCard(title: "2. Из чего состоит еда (БЖУ)", icon: "chart.pie.fill", color: .blue) {
                        Text("Макронутриенты — это кирпичики нашего тела.")
                             .font(DesignSystem.Typography.body())
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // Protein
                            HStack {
                                Image(systemName: "circle.fill").foregroundColor(.red).font(.caption)
                                Text("Белки (Строитель)").bold().foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            Text("Главный материал для роста мышц. Есть в мясе, рыбе, яйцах, твороге.")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            // Carbs
                            HStack {
                                Image(systemName: "circle.fill").foregroundColor(.green).font(.caption)
                                Text("Углеводы (Топливо)").bold().foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            Text("Энергия для тренировок и мозга. Крупы, макароны, фрукты, овощи.")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                            // Fats
                            HStack {
                                Image(systemName: "circle.fill").foregroundColor(.yellow).font(.caption)
                                Text("Жиры (Защита)").bold().foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            Text("Нужны для гормонов и здоровья. Орехи, масла, авокадо, жирная рыба.")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    // Глава 3. Вода
                    SectionCard(title: "3. Вода", icon: "drop.fill", color: .cyan) {
                        Text("Вода — это среда для всех процессов.")
                             .font(DesignSystem.Typography.body())
                        BulletPoint(icon: "drop.circle", title: "Пей регулярно", text: "Начинай утро со стакана воды.")
                        BulletPoint(icon: "bolt.fill", title: "На тренировке", text: "Пей по чуть-чуть между подходами.")
                        BulletPoint(icon: "arrow.counterclockwise", title: "Обезвоживание", text: "Если хочешь пить — ты уже обезвожен. Не допускай этого.")
                    }
                    
                    // Глава 4. Стратегии
                    Text("Твоя цель")
                        .font(DesignSystem.Typography.title3())
                        .bold()
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .padding(.top, 8)
                    
                    // Strategy: Fat Loss
                    SectionCard(title: "Хочу похудеть", icon: "arrow.down.right.circle.fill", color: .green) {
                         Text("Главное правило: Дефицит калорий.")
                             .font(DesignSystem.Typography.headline())
                             .foregroundColor(.green)
                        
                         BulletPoint(icon: "scalemass", title: "Меньше ешь", text: "Урежь порции углеводов и жиров.")
                         BulletPoint(icon: "shield.fill", title: "Больше белка", text: "Ешь белок, чтобы не терять мышцы вместо жира.")
                         BulletPoint(icon: "carrot.fill", title: "Овощи", text: "Добавляй овощи в каждый прием пищи — они дают сытость.")
                    }
                    
                    // Strategy: Muscle Gain
                    SectionCard(title: "Хочу набрать массу", icon: "arrow.up.right.circle.fill", color: .red) {
                        Text("Главное правило: Профицит калорий.")
                             .font(DesignSystem.Typography.headline())
                             .foregroundColor(.red)

                        BulletPoint(icon: "plus.circle", title: "Больше ешь", text: "Нужно есть чуть больше, чем тратишь.")
                        BulletPoint(icon: "bolt.fill", title: "Углеводы", text: "Не бойся углеводов — они нужны для тяжелых тренировок.")
                        BulletPoint(icon: "hare.fill", title: "Не спеши", text: "Быстрый набор веса — это чаще жир, а не мышцы.")
                    }

                    // Глава 5. Тайминг
                    SectionCard(title: "5. Когда есть?", icon: "clock.fill", color: .purple) {
                        ComparisonRow(left: "До тренировки", right: "2-3 часа", text: "Полноценный обед (каша + мясо).")
                        ComparisonRow(left: "Перед стартом", right: "30 мин", text: "Можно банан или йогурт.")
                        ComparisonRow(left: "После", right: "1 час", text: "Поешь белок и углеводы для восстановления.")
                        ComparisonRow(left: "Вечером", right: "Ужин", text: "Белок (творог, рыба) + овощи.")
                    }
                    
                    // Глава 7. Добавки
                    SectionCard(title: "6. Спортивные добавки", icon: "pills.circle.fill", color: .indigo) {
                        Text("Это дополнение к еде, а не замена.")
                             .font(DesignSystem.Typography.body())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Полезно", systemImage: "checkmark.seal.fill").foregroundColor(.green).bold()
                            Group {
                                Text("• Креатин: Дает силу и объем мышцам.")
                                Text("• Протеин: Удобный способ добрать белок, если не успел поесть.")
                                Text("• Витамины: Помогают организму работать без сбоев.")
                            }
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            Label("Не трать деньги", systemImage: "xmark.bin.fill").foregroundColor(.red).bold()
                            Text("• Жиросжигатели: Не работают без диеты и спорта.")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    // Глава 8. Метод Ладони
                    SectionCard(title: "7. Как измерять порции", icon: "hand.raised.fill", color: .orange) {
                        Text("Не обязательно все взвешивать. Используй руки:")
                            .font(DesignSystem.Typography.body())
                        
                        HStack(alignment: .top, spacing: 20) {
                            VStack {
                                Image(systemName: "hand.raised.fill").font(.largeTitle).foregroundColor(.red)
                                Text("Белок").font(.caption).bold()
                                Text("Ладонь").font(.caption2).foregroundColor(.gray)
                            }
                            VStack {
                                Image(systemName: "circle.grid.cross.fill").font(.largeTitle).foregroundColor(.green)
                                Text("Овощи").font(.caption).bold()
                                Text("Кулак").font(.caption2).foregroundColor(.gray)
                            }
                            VStack {
                                Image(systemName: "hand.cup.fill").font(.largeTitle).foregroundColor(.blue)
                                Text("Угли").font(.caption).bold()
                                Text("Горсть").font(.caption2).foregroundColor(.gray)
                            }
                            VStack {
                                Image(systemName: "hand.thumbsup.fill").font(.largeTitle).foregroundColor(.yellow)
                                Text("Жиры").font(.caption).bold()
                                Text("Палец").font(.caption2).foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        
                        Text("Мужчинам: 2 порции. Женщинам: 1 порция.")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(.gray)
                    }

                    Spacer().frame(height: 20)
                }
            }
        }
        .navigationTitle("Питание")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NutritionGuideView()
}
