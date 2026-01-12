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
    
    init(existingProgram: Program? = nil) {
        self.existingProgram = existingProgram
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Секция 1: Основная информация
                Section {
                    TextField("Название программы", text: $viewModel.programName)
                        .font(DesignSystem.Typography.body())
                    
                    TextField("Описание (опционально)", text: $viewModel.programDescription, axis: .vertical)
                        .font(DesignSystem.Typography.body())
                        .lineLimit(3...6)
                } header: {
                    Text("Основная информация")
                        .font(DesignSystem.Typography.headline())
                }
                
                // Секция 2: Расписание дней
                Section {
                    if viewModel.workoutDays.isEmpty {
                        ContentUnavailableView {
                            Label("Нет тренировочных дней", systemImage: "calendar.badge.plus")
                                .font(DesignSystem.Typography.body())
                        } description: {
                            Text("Добавьте хотя бы один день")
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
                        Label("Добавить тренировочный день", systemImage: "plus.circle.fill")
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                } header: {
                    Text("Расписание дней (\(viewModel.workoutDays.count))")
                        .font(DesignSystem.Typography.headline())
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Новая программа")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveProgram()
                    }
                    .disabled(!viewModel.isValid)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .alert("Ошибка сохранения", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveErrorMessage)
            }
            .onAppear {
                if let program = existingProgram {
                    viewModel.loadProgram(program)
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
                Text(day.name)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if day.exercises.isEmpty {
                    Text("Упражнений нет")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                } else {
                    Text("\(day.exercises.count) упражнений")
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
