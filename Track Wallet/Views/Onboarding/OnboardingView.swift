//
//  OnboardingView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 5/8/26.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "dollarsign.circle.fill",
                    iconColor: AppTheme.primary,
                    title: "Track Your Money",
                    subtitle: "Welcome to Wallet Flows. No bank login required. Manually track every dollar with full privacy via iCloud."
                )
                .tag(0)

                OnboardingPage(
                    icon: "wallet.pass.fill",
                    iconColor: AppTheme.asset,
                    title: "Accounts & Cards",
                    subtitle: "Add cash, bank accounts, credit cards, and debit cards. See your net worth and credit utilization at a glance."
                )
                .tag(1)

                OnboardingPage(
                    icon: "chart.bar.fill",
                    iconColor: AppTheme.income,
                    title: "Budgets & Insights",
                    subtitle: "Set monthly budgets per category. Track spending with charts and get smart snapshots of your finances."
                )
                .tag(2)

                OnboardingPage(
                    icon: "person.2.fill",
                    iconColor: AppTheme.transfer,
                    title: "Debts & Recurring",
                    subtitle: "Track who owes you and what you owe. Manage subscriptions, installments, and split payments."
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: AppSpacing.md) {
                Button {
                    if currentPage < 3 {
                        withAnimation { currentPage += 1 }
                    } else {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text(currentPage < 3 ? "Continue" : "Get Started")
                        .font(AppTypography.bodyEmphasized)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .fill(AppTheme.primary)
                        )
                }

                if currentPage < 3 {
                    Button {
                        hasCompletedOnboarding = true
                    } label: {
                        Text("Skip")
                            .font(AppTypography.callout)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xxl)
            .padding(.bottom, 40)
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundStyle(
                    LinearGradient(
                        colors: [iconColor, iconColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppTypography.display)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(AppTypography.callout)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
