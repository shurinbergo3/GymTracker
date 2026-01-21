//
//  DesignSystem.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI

// MARK: - Design System (Apple Fitness+ Aesthetic)

struct DesignSystem {
    
    // MARK: - Colors
    
    struct Colors {
        // Apple Fitness+ Dark Mode Palette
        static let background = Color(uiColor: .systemBackground) // Deep black in dark mode
        static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground) // Dark gray cards
        
        // Neon Volt/Lime Green (Activity Ring Style)
        static let accent = Color(red: 0.75, green: 1.0, blue: 0.2)
        static let neonGreen = Color(red: 0.75, green: 1.0, blue: 0.2)
        
        // Secondary Accents
        static let secondaryAccent = Color.orange
        static let accentMint = Color.mint
        
        // Progress colors
        static let progressPositive = Color(red: 0.75, green: 1.0, blue: 0.2) // Neon green
        static let progressNegative = Color.red
        static let progressNeutral = Color.gray
        
        // Text colors
        static let primaryText = Color.white
        static let secondaryText = Color(white: 0.7)
    }
    
    // MARK: - Spacing (Increased for "breathing" design)
    
    struct Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let xxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius (Larger, more rounded)
    
    struct CornerRadius {
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 28
    }
    
    // MARK: - Typography (Heavy, Bold, Rounded)
    
    struct Typography {
        static func largeTitle() -> Font {
            .system(.largeTitle, design: .rounded, weight: .heavy)
        }
        
        static func title() -> Font {
            .system(.title, design: .rounded, weight: .heavy)
        }
        
        static func title2() -> Font {
            .system(.title2, design: .rounded, weight: .bold)
        }
        
        static func title3() -> Font {
            .system(.title3, design: .rounded, weight: .semibold)
        }
        
        static func headline() -> Font {
            .system(.headline, design: .rounded, weight: .semibold)
        }
        
        static func body() -> Font {
            .system(.body, design: .rounded)
        }
        
        static func callout() -> Font {
            .system(.callout, design: .rounded)
        }
        
        static func caption() -> Font {
            .system(.caption, design: .rounded)
        }
        
        static func subheadline() -> Font {
            .system(.subheadline, design: .rounded, weight: .regular)
        }
        
        static func sectionHeader() -> Font {
            .system(.caption, design: .rounded, weight: .bold)
        }
    }
}

// MARK: - Reusable Components

/// Enhanced card with shadow for Apple Fitness aesthetic
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

/// Icon button with neon accent
struct IconButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(DesignSystem.Colors.accent)
                .frame(width: 44, height: 44)
        }
    }
}

/// Neon-bordered text field with focus state
struct NeonTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .focused($isFocused)
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .stroke(isFocused ? DesignSystem.Colors.neonGreen : Color.clear, lineWidth: 2)
            )
            .font(DesignSystem.Typography.title3())
            .foregroundColor(DesignSystem.Colors.primaryText)
    }
}

/// Standard rounded text field (legacy support)
struct RoundedTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        NeonTextField(placeholder: placeholder, text: $text, keyboardType: keyboardType)
    }
}

/// Large gradient button with capsule shape
struct GradientButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                }
                Text(title)
                    .font(DesignSystem.Typography.title3())
                    .fontWeight(.bold)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.neonGreen,
                        Color(red: 0.6, green: 0.9, blue: 0.15)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignSystem.CornerRadius.extraLarge)
            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.4), radius: 12, x: 0, y: 6)
        }
    }
}

/// Workout banner card for hero-style workout starter
struct WorkoutBannerCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.15, blue: 0.2),
                        Color(red: 0.1, green: 0.1, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(DesignSystem.CornerRadius.large)
            .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
    }
}

/// Empty State with Apple Fitness styling
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxl) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text(title)
                    .font(DesignSystem.Typography.title())
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(message)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer().frame(height: 60)
            
            GradientButton(title: buttonTitle, action: action)
                .padding(.horizontal, DesignSystem.Spacing.xxl)
        }
        .padding(DesignSystem.Spacing.xxl)
    }
}

/// Stat Card with formatted value and icon
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack(alignment: .top) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                Spacer(minLength: 0)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Text(title)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .frame(height: 120) // Fixed height to make them squares/uniform
            .padding(DesignSystem.Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Close Button
struct CloseButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer dark circle border
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 44, height: 44)
                
                // Inner bright red circle
                Circle()
                    .fill(Color(red: 1.0, green: 0.27, blue: 0.23)) // Bright red like reference
                    .frame(width: 36, height: 36)
                
                // White X icon
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
            }
            .shadow(color: Color(red: 1.0, green: 0.27, blue: 0.23).opacity(0.5), radius: 8, x: 0, y: 2)
        }
    }
}
