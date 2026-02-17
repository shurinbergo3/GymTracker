//
//  CommentEditorView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI

struct CommentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var comment: String
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Compact text field
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Комментарий к упражнению".localized())
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    TextField("Ваши заметки...", text: $comment, axis: .vertical)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .textFieldStyle(.plain)
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                        .lineLimit(3...6)
                        .focused($isFieldFocused)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Save button
                Button(action: { dismiss() }) {
                    Text("Сохранить".localized())
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.neonGreen.opacity(0.15))
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .padding(.vertical, DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.background)
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(DesignSystem.CornerRadius.extraLarge)
            .onAppear {
                isFieldFocused = true
            }
        }
    }
}

#Preview {
    CommentEditorView(comment: .constant(""))
}
