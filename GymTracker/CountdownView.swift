import SwiftUI

struct CountdownView: View {
    @State private var count = 3
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 150, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.neonGreen)
                    .transition(.scale.combined(with: .opacity))
                    .id(count)
            } else {
                Text("GO!")
                    .font(.system(size: 120, weight: .black, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.neonGreen)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            runCountdown()
        }
    }
    
    private func runCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                if count > 1 {
                    count -= 1
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                } else if count == 1 {
                    count = 0 
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    // Delay slightly for GO! then finish
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onComplete()
                    }
                    timer.invalidate()
                }
            }
        }
        // Initial haptic
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}
