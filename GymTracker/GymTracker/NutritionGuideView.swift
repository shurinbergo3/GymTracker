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
                            Text("Nutrition Guide".localized())
                                .font(DesignSystem.Typography.title2())
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                            Text("Simply about complex".localized())
                                .font(DesignSystem.Typography.subheadline())
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(radius: 4)
                        }
                        .padding(DesignSystem.Spacing.lg)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    // Введение
                    Text("nutrition_intro_text".localized())
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .multilineTextAlignment(.leading)

                    // Калькулятор
                    CalorieCalculatorView()
                        .padding(.bottom, 8)
                    
                    // Глава 1. Энергия
                    SectionCard(title: "1. Energy and Calories".localized(), icon: "flame.fill", color: .orange) {
                        Text("Simple: energy (calories) determines your weight.".localized())
                            .font(DesignSystem.Typography.body())
                        
                        BulletPoint(icon: "scalemass", title: "Balance".localized(), text: "Eat more than you burn — gain weight. Burn more — lose weight.".localized())
                        BulletPoint(icon: "waveform.path.ecg", title: "Basal Metabolism".localized(), text: "Energy your body burns at rest (breathing, heartbeat).".localized())
                        BulletPoint(icon: "figure.walk", title: "Activity".localized(), text: "Any movement (walking, cleaning, training) burns calories.".localized())
                    }
                    
                    // Глава 2. БЖУ
                    SectionCard(title: "2. What food is made of (Macros)".localized(), icon: "chart.pie.fill", color: .blue) {
                        Text("Macronutrients are building blocks of our body.".localized())
                             .font(DesignSystem.Typography.body())
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // Protein
                            HStack {
                                Image(systemName: "circle.fill").foregroundColor(.red).font(.caption)
                                Text("Protein (Builder)".localized()).bold().foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            Text("Main material for muscle growth. Found in meat, fish, eggs, cottage cheese.".localized())
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            // Carbs
                            HStack {
                                Image(systemName: "circle.fill").foregroundColor(.green).font(.caption)
                                Text("Carbs (Fuel)".localized()).bold().foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            Text("Energy for training and brain. Grains, pasta, fruits, vegetables.".localized())
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                            // Fats
                            HStack {
                                Image(systemName: "circle.fill").foregroundColor(.yellow).font(.caption)
                                Text("Fats (Protection)".localized()).bold().foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            Text("Needed for hormones and health. Nuts, oils, avocado, fatty fish.".localized())
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    // Глава 3. Вода
                    SectionCard(title: "3. Water".localized(), icon: "drop.fill", color: .cyan) {
                        Text("Water is the medium for all processes.".localized())
                             .font(DesignSystem.Typography.body())
                        BulletPoint(icon: "drop.circle", title: "Drink regularly".localized(), text: "Start your morning with a glass of water.".localized())
                        BulletPoint(icon: "bolt.fill", title: "During training".localized(), text: "Sip between sets.".localized())
                        BulletPoint(icon: "arrow.counterclockwise", title: "Dehydration".localized(), text: "If you're thirsty, you're already dehydrated. Don't let it happen.".localized())
                    }
                    
                    // Глава 4. Стратегии
                    Text("Your goal".localized())
                        .font(DesignSystem.Typography.title3())
                        .bold()
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .padding(.top, 8)
                    
                    // Strategy: Fat Loss
                    SectionCard(title: "Want to lose weight".localized(), icon: "arrow.down.right.circle.fill", color: .green) {
                         Text("Main rule: Calorie deficit.".localized())
                             .font(DesignSystem.Typography.headline())
                             .foregroundColor(.green)
                        
                         BulletPoint(icon: "scalemass", title: "Eat less".localized(), text: "Cut carbs and fats portions.".localized())
                         BulletPoint(icon: "shield.fill", title: "More protein".localized(), text: "Eat protein to avoid losing muscle instead of fat.".localized())
                         BulletPoint(icon: "carrot.fill", title: "Vegetables".localized(), text: "Add vegetables to every meal — they provide satiety.".localized())
                    }
                    
                    // Strategy: Muscle Gain
                    SectionCard(title: "Want to gain mass".localized(), icon: "arrow.up.right.circle.fill", color: .red) {
                        Text("Main rule: Calorie surplus.".localized())
                             .font(DesignSystem.Typography.headline())
                             .foregroundColor(.red)

                        BulletPoint(icon: "plus.circle", title: "Eat more".localized(), text: "Need to eat slightly more than you burn.".localized())
                        BulletPoint(icon: "bolt.fill", title: "Carbohydrates".localized(), text: "Don't fear carbs — they're needed for heavy training.".localized())
                        BulletPoint(icon: "hare.fill", title: "Don't rush".localized(), text: "Fast weight gain is usually fat, not muscle.".localized())
                    }

                    // Глава 5. Тайминг
                    SectionCard(title: "5. When to eat?".localized(), icon: "clock.fill", color: .purple) {
                        ComparisonRow(left: "Before training".localized(), right: "2-3 hours".localized(), text: "Full meal (grains + meat).".localized())
                        ComparisonRow(left: "Before start".localized(), right: "30 min".localized(), text: "Can have banana or yogurt.".localized())
                        ComparisonRow(left: "After".localized(), right: "1 hour".localized(), text: "Eat protein and carbs for recovery.".localized())
                        ComparisonRow(left: "Evening".localized(), right: "Dinner".localized(), text: "Protein (cottage cheese, fish) + vegetables.".localized())
                    }
                    
                    // Глава 7. Добавки
                    SectionCard(title: "6. Sports supplements".localized(), icon: "pills.circle.fill", color: .indigo) {
                        Text("This is a supplement to food, not a replacement.".localized())
                             .font(DesignSystem.Typography.body())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Useful".localized(), systemImage: "checkmark.seal.fill").foregroundColor(.green).bold()
                            Group {
                                Text("• Creatine: Gives strength and volume to muscles.".localized())
                                Text("• Protein: Convenient way to get protein if you didn't have time to eat.".localized())
                                Text("• Vitamins: Help the body function without failures.".localized())
                            }
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            Label("Don't waste money".localized(), systemImage: "xmark.bin.fill").foregroundColor(.red).bold()
                            Text("• Fat burners: Don't work without diet and exercise.".localized())
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    // Глава 8. Метод Ладони
                    SectionCard(title: "7. How to measure portions".localized(), icon: "hand.raised.fill", color: .orange) {
                        Text("No need to weigh everything. Use your hands:".localized())
                            .font(DesignSystem.Typography.body())
                        
                        HStack(alignment: .top, spacing: 20) {
                            VStack {
                                Image(systemName: "hand.raised.fill").font(.largeTitle).foregroundColor(.red)
                                Text("Protein".localized()).font(.caption).bold()
                                Text("Palm".localized()).font(.caption2).foregroundColor(.gray)
                            }
                            VStack {
                                Image(systemName: "circle.grid.cross.fill").font(.largeTitle).foregroundColor(.green)
                                Text("Veggies".localized()).font(.caption).bold()
                                Text("Fist".localized()).font(.caption2).foregroundColor(.gray)
                            }
                            VStack {
                                Image(systemName: "hand.cup.fill").font(.largeTitle).foregroundColor(.blue)
                                Text("Carbs".localized()).font(.caption).bold()
                                Text("Handful".localized()).font(.caption2).foregroundColor(.gray)
                            }
                            VStack {
                                Image(systemName: "hand.thumbsup.fill").font(.largeTitle).foregroundColor(.yellow)
                                Text("Fats".localized()).font(.caption).bold()
                                Text("Thumb".localized()).font(.caption2).foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        
                        Text("Men: 2 portions. Women: 1 portion.".localized())
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(.gray)
                    }

                    Spacer().frame(height: 20)
                }
            }
        }
        .navigationTitle("Nutrition".localized())
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NutritionGuideView()
}
