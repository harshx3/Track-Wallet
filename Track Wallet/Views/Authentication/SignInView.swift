//
//  SignInView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/30/26.
//

import SwiftUI
import AuthenticationServices

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
                    Text("Wallet Flows")
                        .font(AppTypography.displayLarge)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Private manual money tracking with iCloud")
                        .font(AppTypography.callout)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()

            VStack(spacing: AppSpacing.md) {
                Text("Sign in to securely sync your financial data across devices")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    authManager.handleSignInResult(result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                .padding(.horizontal, AppSpacing.xxl)

                Text("Your data syncs securely via iCloud")
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
