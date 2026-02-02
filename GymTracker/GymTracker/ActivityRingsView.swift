//
//  ActivityRingsView.swift
//  GymTracker
//
//  Created by Antigravity on 1/16/26.
//

import SwiftUI
import HealthKit
import HealthKitUI

struct ActivityRingsView: UIViewRepresentable {
    func makeUIView(context: Context) -> HKActivityRingView {
        let ringView = HKActivityRingView()
        
        // Fetch current summary data asynchronously
        Task {
            if let summary = await fetchActivitySummary() {
                // Animate the rings
                await MainActor.run {
                    ringView.setActivitySummary(summary, animated: true)
                }
            }
        }
        
        return ringView
    }
    
    func updateUIView(_ uiView: HKActivityRingView, context: Context) {
        // We could update data here if bound to a state, 
        // but for now a simple fetch on appear is sufficient.
    }
    
    private func fetchActivitySummary() async -> HKActivitySummary? {
        // Query HealthKit for today's summary
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.calendar, .year, .month, .day], from: now)
        
        
        let predicate = HKQuery.predicateForActivitySummary(with: components)
        
        let store = HealthManager.shared.healthStore
        
        return await withCheckedContinuation { continuation in
            let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
                if let error = error {
                    #if DEBUG
                    print("Error fetching rings: \(error.localizedDescription)")
                    #endif
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let summaries = summaries, let summary = summaries.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: summary)
            }
            
            store.execute(query)
        }
    }
}

#Preview {
    ActivityRingsView()
        .frame(width: 150, height: 150)
}
