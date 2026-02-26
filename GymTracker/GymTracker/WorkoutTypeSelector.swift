//
//  WorkoutTypeSelector.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI

struct WorkoutTypeSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedType: WorkoutType
    let onSelect: (WorkoutType) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    ForEach([WorkoutType.strength, WorkoutType.repsOnly, WorkoutType.duration], id: \.self) { type in
                        Button(action: {
                            selectedType = type
                            onSelect(type)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: type.icon)
                                    .font(.title2)
                                    .foregroundColor(selectedType == type ? DesignSystem.Colors.neonGreen : DesignSystem.Colors.primaryText)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(type.displayName)
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                    
                                    Text(type.description)
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                
                                Spacer()
                                
                                if selectedType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(DesignSystem.Colors.neonGreen)
                                }
                            }
                            .padding(DesignSystem.Spacing.lg)
                            .background(selectedType == type ? DesignSystem.Colors.neonGreen.opacity(0.1) : DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.CornerRadius.large)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .navigationTitle("Тип тренировки".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена".localized()) {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
    }
}

extension WorkoutType {
    var description: String {
        switch self {
        case .strength:
            return "Вес × Повторы".localized()
        case .repsOnly:
            return "Только повторения".localized()
        case .duration:
            return "Время и дистанция".localized()
        }
    }
}

#Preview {
    WorkoutTypeSelectorView(
        selectedType: .constant(.strength),
        onSelect: { _ in }
    )
}
