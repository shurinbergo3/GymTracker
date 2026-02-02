//
//  SupplementDetailView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct SupplementDetailView: View {
    let supplement: Supplement
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header Image Area
                    ZStack {
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.accent.opacity(0.3),
                                DesignSystem.Colors.background
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 250)
                        
                        Image(systemName: supplement.icon)
                            .font(.system(size: 80))
                            .foregroundColor(DesignSystem.Colors.accent)
                            .shadow(color: DesignSystem.Colors.accent.opacity(0.5), radius: 20, x: 0, y: 0)
                    }
                    .frame(height: 200)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                        // Title Section
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(supplement.name)
                                .font(DesignSystem.Typography.largeTitle())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .multilineTextAlignment(.leading)
                            
                            if let subtitle = supplement.subtitle {
                                Text(subtitle)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                        
                        // Main Description ("Deep Analytics")
                        if let deepAnalysis = supplement.detailedDescription {
                            detailSection(title: "АНАЛИТИКА", icon: "doc.text.magnifyingglass", content: deepAnalysis)
                        } else {
                             detailSection(title: "ОПИСАНИЕ", icon: "doc.text", content: supplement.description)
                        }
                        
                        // Mechanism of Action
                        if let mechanism = supplement.mechanism {
                            detailSection(title: "МЕХАНИЗМ ДЕЙСТВИЯ", icon: "gearshape.2.fill", content: mechanism)
                        }
                        
                        // Benefits Grid
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            sectionHeader(title: "ОСНОВНЫЕ ЭФФЕКТЫ", icon: "star.fill")
                            
                            FlowLayout(spacing: 12) {
                                ForEach(supplement.benefits, id: \.self) { benefit in
                                    Text(benefit)
                                        .font(DesignSystem.Typography.subheadline())
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(DesignSystem.Colors.cardBackground)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(DesignSystem.Colors.accent.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        
                        // Forms (if applicable)
                        if let forms = supplement.forms, !forms.isEmpty {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                sectionHeader(title: "ФОРМЫ И ОТЛИЧИЯ", icon: "flask.fill")
                                
                                ForEach(forms, id: \.self) { form in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(DesignSystem.Colors.accent)
                                            .padding(.top, 8)
                                        
                                        Text(form)
                                            .font(DesignSystem.Typography.body())
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding()
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(16)
                        }
                        
                        // Usage / Dosage
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            sectionHeader(title: "КАК ПРИНИМАТЬ", icon: "clock.fill")
                            
                            Text(supplement.usage)
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DesignSystem.Colors.cardBackground)
                                .cornerRadius(16)
                        }
                        
                        // Interaction / Warning
                        if let warning = supplement.warning {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                                
                                Text(warning)
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Spacer().frame(height: 50)
                    }
                    .padding(DesignSystem.Spacing.xl)
                    .background(
                        DesignSystem.Colors.background
                            .cornerRadius(30, corners: [.topLeft, .topRight])
                            .offset(y: -30)
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(DesignSystem.Colors.accent)
            Text(title)
                .font(DesignSystem.Typography.caption())
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.accent)
                .tracking(1.5)
        }
    }
    
    private func detailSection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            sectionHeader(title: title, icon: icon)
            
            Text(content)
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// Helper for FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        if rows.isEmpty { return .zero }
        
        let width = proposal.width ?? 0
        let height = rows.last!.maxY
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        for row in rows {
            for element in row.elements {
                element.subview.place(at: CGPoint(x: bounds.minX + element.rect.minX, y: bounds.minY + element.rect.minY), proposal: .unspecified)
            }
        }
    }
    
    struct LayoutRow {
        var elements: [(subview: LayoutSubview, rect: CGRect)] = []
        var maxY: CGFloat = 0
    }
    
    func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [LayoutRow] {
        var rows: [LayoutRow] = []
        var currentRow = LayoutRow()
        var x: CGFloat = 0
        var y: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth && !currentRow.elements.isEmpty {
                // New row
                y = currentRow.maxY + spacing
                rows.append(currentRow)
                currentRow = LayoutRow()
                x = 0
            }
            
            currentRow.elements.append((subview, CGRect(x: x, y: y, width: size.width, height: size.height)))
            currentRow.maxY = max(currentRow.maxY, y + size.height)
            x += size.width + spacing
        }
        
        if !currentRow.elements.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
}

// Helper for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
