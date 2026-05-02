//
//  ProgramEditorView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct ProgramEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let existingProgram: Program? // Программа для редактирования
    
    @StateObject private var viewModel = ProgramEditorViewModel()
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var hasLoaded = false
    
    init(existingProgram: Program? = nil) {
        self.existingProgram = existingProgram
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Секция 1: Основная информация
                Section {
                    TextField("Название программы".localized(), text: $viewModel.programName)
                        .font(DesignSystem.Typography.body())
                    
                    TextField("Описание (опционально)".localized(), text: $viewModel.programDescription, axis: .vertical)
                        .font(DesignSystem.Typography.body())
                        .lineLimit(3...6)
                } header: {
                    Text("Основная информация".localized())
                        .font(DesignSystem.Typography.headline())
                }
                
                // Секция 2: Расписание дней
                Section {
                    if viewModel.workoutDays.isEmpty {
                        ContentUnavailableView {
                            Label("Нет тренировочных дней".localized(), systemImage: "calendar.badge.plus")
                                .font(DesignSystem.Typography.body())
                        } description: {
                            Text("Добавьте хотя бы один день".localized())
                                .font(DesignSystem.Typography.callout())
                        }
                    } else {
                        ForEach(viewModel.workoutDays) { day in
                            NavigationLink(destination: DayEditorView(day: day)) {
                                DayRow(day: day)
                            }
                        }
                        .onDelete { offsets in
                            withAnimation {
                                viewModel.deleteDay(at: offsets)
                            }
                        }
                        .onMove { source, destination in
                            viewModel.moveDay(from: source, to: destination)
                        }
                    }
                    
                    Button(action: {
                        withAnimation {
                            viewModel.addDay()
                        }
                    }) {
                        Label("Добавить тренировочный день".localized(), systemImage: "plus.circle.fill")
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                } header: {
                    Text(String(format: "Расписание дней (%d)".localized(), viewModel.workoutDays.count))
                        .font(DesignSystem.Typography.headline())
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text("Новая программа".localized()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена".localized()) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить".localized()) {
                        saveProgram()
                    }
                    .disabled(!viewModel.isValid)
                }
                
                
                
            }
            .alert(Text("Ошибка сохранения".localized()), isPresented: $showingSaveError) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text(saveErrorMessage)
            }
            .onAppear {
                if !hasLoaded, let program = existingProgram {
                    viewModel.loadProgram(program)
                    hasLoaded = true
                }
            }
        }
    }
    
    private func saveProgram() {
        do {
            try viewModel.saveProgram(context: modelContext, existingProgram: existingProgram)
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
        }
    }
}

// MARK: - Day Row

struct DayRow: View {
    @ObservedObject var day: WorkoutDayDraft
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(day.name.localized())
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if day.exercises.isEmpty {
                    Text("Упражнений нет".localized())
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                } else {
                    Text(String(format: "%d упражнений".localized(), day.exercises.count))
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.accent)
                }
            }
            
            Spacer()
            
            if day.exercises.isEmpty {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.footnote)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.footnote)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

#Preview {
    ProgramEditorView()
        .modelContainer(for: Program.self, inMemory: true)
}
