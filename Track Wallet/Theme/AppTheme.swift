//
//  AppTheme.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/30/26.
//

import SwiftUI

// MARK: - Professional Color Scheme (MoneyWiz-inspired)

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
    // Display
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let display = Font.system(size: 28, weight: .bold, design: .rounded)
    
    // Headlines
    static let headline = Font.system(size: 17, weight: .semibold)
    static let headlineLarge = Font.system(size: 20, weight: .semibold)
    
    // Body
    static let body = Font.system(size: 17, weight: .regular)
    static let bodyEmphasized = Font.system(size: 17, weight: .semibold)
    
    // Callout
    static let callout = Font.system(size: 16, weight: .regular)
    static let calloutEmphasized = Font.system(size: 16, weight: .semibold)
    
    // Captions
    static let caption = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .regular)
    
    // Amounts
    static let amountLarge = Font.system(size: 40, weight: .bold, design: .rounded)
    static let amountMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let amountSmall = Font.system(size: 20, weight: .semibold, design: .rounded)
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
}
