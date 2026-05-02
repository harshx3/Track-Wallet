//
//  SignInView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/30/26.
//

import SwiftUI

struct SignInView: View {
    let authManager: AuthenticationManager

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: AppSpacing.xl) {
                Image(systemName: "dollarsign.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(AppTheme.primary)

                VStack(spacing: AppSpacing.xs) {
                    Text("Track Wallet")
                        .font(AppTypography.displayLarge)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Your personal finance companion")
                        .font(AppTypography.callout)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()

            VStack(spacing: AppSpacing.md) {
                Text("Sign in to securely access your financial data")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)

                Button {
                    authManager.mockSignIn()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.title3)
                        Text("Sign in with Apple")
                            .font(AppTypography.bodyEmphasized)
                    }
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(colorScheme == .dark ? Color.white : Color.black)
                    )
                }
                .padding(.horizontal, AppSpacing.xxl)

                Text("All data is stored locally on your device")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(.bottom, 60)
        }
    }
}

#Preview {
    SignInView(authManager: AuthenticationManager())
}
