//
//  ContentView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData
import LocalAuthentication

struct ContentView: View {
    let authManager: AuthenticationManager

    @AppStorage("appAppearance") private var appearance: String = AppAppearance.system.rawValue
    @AppStorage("appTextSize") private var textSize: String = AppTextSize.regular.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @AppStorage("appLockTimeout") private var lockTimeout = 0

    @State private var isUnlocked = false
    @State private var lastBackgroundTime: Date?

    @Environment(\.scenePhase) private var scenePhase

    private var colorScheme: ColorScheme? {
        (AppAppearance(rawValue: appearance) ?? .system).colorScheme
    }

    private var dynamicTypeSize: DynamicTypeSize {
        (AppTextSize(rawValue: textSize) ?? .regular).dynamicTypeSize
    }

    private var requiresUnlock: Bool {
        appLockEnabled && !isUnlocked
    }

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if authManager.isCheckingCredential {
                ProgressView()
                    .scaleEffect(1.2)
            } else if authManager.isAuthenticated {
                ZStack {
                    TabView {
                        DashboardView()
                            .tabItem {
                                Label("Dashboard", systemImage: "chart.bar.fill")
                            }

                        TransactionsView()
                            .tabItem {
                                Label("Transactions", systemImage: "arrow.left.arrow.right")
                            }

                        BudgetsView()
                            .tabItem {
                                Label("Budgets", systemImage: "gauge.with.dots.needle.33percent")
                            }

                        RecurringPaymentsView()
                            .tabItem {
                                Label("Recurring", systemImage: "arrow.clockwise.circle.fill")
                            }

                        SettingsView(authManager: authManager)
                            .tabItem {
                                Label("Settings", systemImage: "gearshape.fill")
                            }
                    }
                    .tint(AppTheme.primary)

                    if requiresUnlock {
                        AppLockView {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isUnlocked = true
                                lastBackgroundTime = nil
                            }
                        }
                        .transition(.opacity)
                    }
                }
            } else {
                SignInView(authManager: authManager)
            }
        }
        .preferredColorScheme(colorScheme)
        .dynamicTypeSize(dynamicTypeSize)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authManager.isCheckingCredential)
        .onChange(of: scenePhase) { _, newPhase in
            if appLockEnabled {
                if newPhase == .background {
                    lastBackgroundTime = Date()
                } else if newPhase == .active && isUnlocked {
                    if let backgroundTime = lastBackgroundTime {
                        let elapsed = Date().timeIntervalSince(backgroundTime)
                        // lockTimeout=0 means "Immediately" — use a 1-second grace period
                        // to avoid re-locking during the same foreground transition
                        let effectiveTimeout = max(1.0, Double(lockTimeout))
                        if elapsed >= effectiveTimeout {
                            isUnlocked = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - App Lock View

struct AppLockView: View {
    let onUnlock: () -> Void

    @State private var authFailed = false
    @State private var isAuthenticating = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(AppTheme.primary)

                Text("Wallet Flows is Locked")
                    .font(AppTypography.headlineLarge)

                Button {
                    authenticate()
                } label: {
                    Label(unlockLabel, systemImage: unlockIcon)
                        .font(AppTypography.bodyEmphasized)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppTheme.primary)
                        )
                }
                .padding(.horizontal, 40)
                .disabled(isAuthenticating)

                if authFailed {
                    Text("Authentication failed. Try again.")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.expense)
                }
            }
        }
        .onAppear {
            authenticate()
        }
    }

    private var unlockLabel: String {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            return context.biometryType == .faceID ? "Unlock with Face ID" : "Unlock with Touch ID"
        }
        return "Unlock with Passcode"
    }

    private var unlockIcon: String {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            return context.biometryType == .faceID ? "faceid" : "touchid"
        }
        return "lock.open.fill"
    }

    private func authenticate() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        authFailed = false

        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        AppLockService.authenticate(using: context, reason: "Unlock Wallet Flows") { success in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    HapticManager.notification(.success)
                    onUnlock()
                } else {
                    authFailed = true
                }
            }
        }
    }
}

#Preview {
    ContentView(authManager: AuthenticationManager())
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self, RecurringPayment.self])
}
