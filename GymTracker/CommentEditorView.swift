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
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    Text("Добавьте заметки о выполнении упражнения, ощущениях или корректировках")
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    CardView {
                        TextEditor(text: $comment)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .frame(minHeight: 150)
                            .scrollContentBackground(.hidden)
                            .focused($isFieldFocused)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    Spacer()
                }
                .padding(.vertical, DesignSystem.Spacing.lg)
            }
            .navigationTitle("Комментарий")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.accent)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isFieldFocused = true
            }
        }
    }
}

#Preview {
    CommentEditorView(comment: .constant(""))
}
