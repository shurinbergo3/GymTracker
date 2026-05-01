//
//  CalorieCalculatorView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct CalorieCalculatorView: View {
    @State private var gender: Gender = .male
    @State private var age: String = ""
    @State private var height: String = "" // cm
    @State private var weight: String = "" // kg
    @State private var activityLevel: ActivityLevel = .moderate
    @State private var goal: Goal = .maintain
    
    @State private var resultCalories: Int? = nil
    @State private var isExpanded: Bool = false
    
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Мужчина"
        case female = "Женщина"
        var id: String { self.rawValue }
    }
    
    enum ActivityLevel: Double, CaseIterable, Identifiable {
        case sedentary = 1.2
        case light = 1.375
        case moderate = 1.55
        case active = 1.725
        case veryActive = 1.9
        
        var id: Double { self.rawValue }
        
        var title: String {
            switch self {
            case .sedentary: return "Сидячий (без спорта)"
            case .light: return "Легкий (1-3 тренировки)"
            case .moderate: return "Средний (3-5 тренировок)"
            case .active: return "Активный (6-7 тренировок)"
            case .veryActive: return "Экстра (тяжелый труд)"
            }
        }
    }
    
    enum Goal: Double, CaseIterable, Identifiable {
        case cut = 0.8
        case maintain = 1.0
        case bulk = 1.15
        
        var id: Double { self.rawValue }
        
        var title: String {
            switch self {
            case .cut: return "Похудение"
            case .maintain: return "Поддержание"
            case .bulk: return "Набор массы"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Button
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "function")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.purple.opacity(0.8))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Калькулятор калорий".localized())
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        Text("Рассчитать свою норму".localized())
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding()
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: DesignSystem.Spacing.md) {
                    
                    // Gender Picker
                    Picker("Пол", selection: $gender) {
                        ForEach(Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Inputs
                    HStack(spacing: 12) {
                        TextField("", text: $age, prompt: Text("Возраст".localized()).foregroundColor(.gray))
                            .keyboardType(.numberPad)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        TextField("", text: $height, prompt: Text("Рост (см)".localized()).foregroundColor(.gray))
                            .keyboardType(.numberPad)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        TextField("", text: $weight, prompt: Text("Вес (кг)".localized()).foregroundColor(.gray))
                            .keyboardType(.decimalPad)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                    
                    // Activity Picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Активность".localized())
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Menu {
                            ForEach(ActivityLevel.allCases) { level in
                                Button(action: { activityLevel = level }) {
                                    HStack {
                                        Text(level.title)
                                        if activityLevel == level { Image(systemName: "checkmark") }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(activityLevel.title)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Goal Picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Цель".localized())
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Picker("Цель", selection: $goal) {
                            ForEach(Goal.allCases) { goal in
                                Text(goal.title).tag(goal)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Calculate Button
                    Button(action: calculateCalories) {
                        Text("Рассчитать".localized())
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.Colors.neonGreen)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    
                    // Result
                    if let calories = resultCalories {
                        VStack(spacing: 4) {
                            Text("Ваша норма:".localized())
                                .font(DesignSystem.Typography.subheadline())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Text("\(calories) ккал".localized())
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.accent)
                                .transition(.scale)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                .padding(.top, 1)
                // Actually if I want it to look like one card opening up, I should probably put them in one ZStack background.
                // But simplifying: just having it below works. 
                // Better Design: Put expanded content inside the same container as the button header, but below it.
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .animation(.spring(), value: isExpanded)
        .animation(.spring(), value: resultCalories)
    }
    
    private func calculateCalories() {
        guard let ageDouble = Double(age),
              let heightDouble = Double(height),
              let weightDouble = Double(weight) else {
            return
        }
        // Защита от нулевых/отрицательных значений: иначе Mifflin-St Jeor выдаёт
        // отрицательные/нулевые калории (например 5 ккал для мужчины с весом 0).
        guard ageDouble > 0, heightDouble > 0, weightDouble > 0 else {
            return
        }

        // Mifflin-St Jeor Equation
        // Men: (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) + 5
        // Women: (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) - 161

        var bmr: Double = (10 * weightDouble) + (6.25 * heightDouble) - (5 * ageDouble)

        if gender == .male {
            bmr += 5
        } else {
            bmr -= 161
        }

        let tdee = bmr * activityLevel.rawValue
        let targetCalories = tdee * goal.rawValue

        resultCalories = max(0, Int(targetCalories))

        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()
        CalorieCalculatorView()
    }
}
