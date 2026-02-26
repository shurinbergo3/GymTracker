//
//  WeightTrackerCard.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct WeightTrackerCard: View {
    @Query private var userProfiles: [UserProfile]
    @State private var showingAddWeight = false
    @State private var showingProfile = false
    @State private var isHistoryExpanded = false
    
    private var currentProfile: UserProfile? {
        userProfiles.first
    }
    
    private var weightHistory: [WeightRecord] {
        currentProfile?.weightHistory.sorted { $0.date > $1.date } ?? []
    }
    
    private var currentWeight: Double {
        weightHistory.first?.weight ?? 0
    }
    
    var body: some View {
        CardView {
            VStack(spacing: 0) {
                // Top Row: Weight (Left) & Height (Right)
                HStack(spacing: 0) {
                    // Weight Section
                    Button(action: { showingAddWeight = true }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                                Text("Вес".localized())
                                    .font(DesignSystem.Typography.subheadline())
                                    .foregroundColor(.gray)
                            }
                            
                            Text(currentWeight > 0 ? String(format: "%.1f %@", currentWeight, "кг".localized()) : "—")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            // Collapsible Trigger
                            if weightHistory.count > 1 {
                                Button(action: { withAnimation { isHistoryExpanded.toggle() } }) {
                                    HStack(spacing: 4) {
                                        Text("История".localized())
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Image(systemName: "chevron.down")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .rotationEffect(.degrees(isHistoryExpanded ? 180 : 0))
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Height Section
                    Button(action: { showingProfile = true }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lines.measurement.vertical")
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                                Text("Рост".localized())
                                    .font(DesignSystem.Typography.subheadline())
                                    .foregroundColor(.gray)
                            }
                            
                            if let profile = currentProfile, profile.height > 0 {
                                Text("\(Int(profile.height)) \("см".localized())")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            } else {
                                Text("Указать".localized())
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.accent)
                            }
                            
                            Text("Изменить".localized()) // Spacer/Hint
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.01))
                        }
                        .frame(width: 140, alignment: .leading)
                        .padding()
                    }
                    .buttonStyle(.plain)
                }
                
                // Bottom Row: Collapsed History
                if isHistoryExpanded {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    VStack(spacing: 0) {
                        ForEach(Array(weightHistory.dropFirst().prefix(5)), id: \.date) { record in
                            HStack {
                                Text(formatDate(record.date))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text(String(format: "%.1f %@", record.weight, "кг".localized()))
                                    .font(.callout)
                                    .foregroundColor(.gray)
                                    .strikethrough()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.vertical, 8)
                            
                            if record != weightHistory.dropFirst().prefix(5).last {
                                Divider()
                                    .background(Color.white.opacity(0.05))
                                    .padding(.horizontal, DesignSystem.Spacing.lg)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2))
                }
            }
        }
        .sheet(isPresented: $showingAddWeight) {
            if let profile = currentProfile {
                AddWeightView(userProfile: profile)
            } else {
                CreateProfileView()
            }
        }
        .sheet(isPresented: $showingProfile) {
            if let profile = currentProfile {
                EditHeightView(userProfile: profile)
                    .presentationDetents([.height(250)])
            } else {
                CreateProfileView()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}
