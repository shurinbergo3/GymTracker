//
//  CalendarSheet.swift
//  GymTracker
//
//  Sheet wrapper around the workout calendar — opened from the
//  Weekly Streak Strip on the dashboard.
//

import SwiftUI

struct CalendarSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        ExpandableCalendarView()
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.top, DesignSystem.Spacing.md)

                        Spacer().frame(height: 60)
                    }
                }
            }
            .navigationTitle("Календарь тренировок".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(action: { dismiss() })
                }
            }
        }
    }
}

#Preview {
    CalendarSheet()
}
