//
//  AppTheme.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/30/26.
//

import SwiftUI

// MARK: - Professional Color Scheme 

struct AppTheme {
    // Primary Colors
    static let primary = Color(red: 0.0, green: 0.48, blue: 1.0) // iOS Blue
    static let primaryDark = Color(red: 0.0, green: 0.38, blue: 0.85)
    
    // Income/Positive
    static let income = Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759
    static let incomeLight = Color(red: 0.20, green: 0.78, blue: 0.35, opacity: 0.1)
    
    // Expense/Negative
    static let expense = Color(red: 1.0, green: 0.23, blue: 0.19) // #FF3B30
    static let expenseLight = Color(red: 1.0, green: 0.23, blue: 0.19, opacity: 0.1)
    
    // Transfer
    static let transfer = Color(red: 1.0, green: 0.58, blue: 0.0) // #FF9500
    static let transferLight = Color(red: 1.0, green: 0.58, blue: 0.0, opacity: 0.1)
    
    // Assets
    static let asset = Color(red: 0.0, green: 0.78, blue: 0.75) // #00C7BE Teal
    static let assetLight = Color(red: 0.0, green: 0.78, blue: 0.75, opacity: 0.1)
    
    // Liabilities
    static let liability = Color(red: 1.0, green: 0.27, blue: 0.23) // #FF453A
    static let liabilityLight = Color(red: 1.0, green: 0.27, blue: 0.23, opacity: 0.1)

    // Recurring
    static let recurring = Color(red: 0.37, green: 0.36, blue: 0.90) // Indigo
    static let recurringLight = Color(red: 0.37, green: 0.36, blue: 0.90, opacity: 0.1)
    
    // Backgrounds
    static let background = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let surfaceBackground = Color(.tertiarySystemGroupedBackground)
    
    // Text
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    
    // Borders
    static let border = Color(.separator)
    static let borderLight = Color(.separator).opacity(0.3)
    
    // Shadows
    static func cardShadow() -> some View {
        EmptyView()
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    static func lightShadow() -> some View {
        EmptyView()
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Typography

struct AppTypography {
    // Display — text style-based for Dynamic Type scaling
    static let displayLarge: Font = .system(.largeTitle, design: .rounded, weight: .bold)
    static let display: Font = .system(.title, design: .rounded, weight: .bold)

    // Headlines
    static let headline: Font = .headline
    static let headlineLarge: Font = .system(.title3, weight: .semibold)

    // Body
    static let body: Font = .body
    static let bodyEmphasized: Font = .body.weight(.semibold)

    // Callout
    static let callout: Font = .callout
    static let calloutEmphasized: Font = .callout.weight(.semibold)

    // Captions
    static let caption: Font = .caption
    static let caption2: Font = .caption2

    // Amounts
    static let amountLarge: Font = .system(.largeTitle, design: .rounded, weight: .bold)
    static let amountMedium: Font = .system(.title, design: .rounded, weight: .bold)
    static let amountSmall: Font = .system(.title3, design: .rounded, weight: .semibold)
}

// MARK: - Spacing

struct AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radius

struct AppRadius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let pill: CGFloat = 100
}

// MARK: - View Modifiers

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground)
            .cornerRadius(AppRadius.md)
            .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
    }
}

// MARK: - Premium Card Modifier (hairline border, continuous corners, no shadow)

struct PremiumCardModifier: ViewModifier {
    var radius: CGFloat = AppRadius.md
    var tint: Color? = nil

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(tint ?? AppTheme.cardBackground)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppTheme.border.opacity(0.45), lineWidth: 0.5)
            }
    }
}

// MARK: - Pressable Card Button Style

struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { HapticManager.impact(.light) }
            }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodyEmphasized)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.primary)
            .cornerRadius(AppRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodyEmphasized)
            .foregroundColor(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.primary.opacity(0.1))
            .cornerRadius(AppRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardModifier())
    }

    func premiumCard(radius: CGFloat = AppRadius.md, tint: Color? = nil) -> some View {
        self.modifier(PremiumCardModifier(radius: radius, tint: tint))
    }
}

// MARK: - Utilization Threshold Helper

extension AppTheme {
    /// Returns a color based on a 0...1+ utilization value.
    /// Defaults to 60% warning, 85% danger — suitable for credit utilization.
    static func utilizationColor(_ value: Double, warningAt: Double = 0.6, dangerAt: Double = 0.85) -> Color {
        if value < warningAt { return primary }
        if value < dangerAt { return transfer }
        return expense
    }

    static func utilizationGradient(_ value: Double, warningAt: Double = 0.6, dangerAt: Double = 0.85) -> LinearGradient {
        let color = utilizationColor(value, warningAt: warningAt, dangerAt: dangerAt)
        return LinearGradient(
            colors: [color.opacity(0.75), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Utilization Gauge (gradient capsule progress bar)

struct UtilizationGauge: View {
    let value: Double
    var height: CGFloat = 8
    var warningAt: Double = 0.6
    var dangerAt: Double = 0.85
    var animate: Bool = true

    private var clamped: Double {
        min(1.0, max(0, value))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))

                Capsule()
                    .fill(AppTheme.utilizationGradient(value, warningAt: warningAt, dangerAt: dangerAt))
                    .frame(width: max(height, geo.size.width * clamped))
                    .animation(animate ? .smooth(duration: 0.55) : nil, value: clamped)
            }
        }
        .frame(height: height)
    }
}
