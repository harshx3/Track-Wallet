//
//  ContentView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    let authManager: AuthenticationManager

    @AppStorage("appAppearance") private var appearance: String = AppAppearance.system.rawValue
    @AppStorage("appTextSize") private var textSize: String = AppTextSize.regular.rawValue

    private var colorScheme: ColorScheme? {
        (AppAppearance(rawValue: appearance) ?? .system).colorScheme
    }

    private var dynamicTypeSize: DynamicTypeSize {
        (AppTextSize(rawValue: textSize) ?? .regular).dynamicTypeSize
    }

    var body: some View {
        Group {
            if authManager.isCheckingCredential {
                ProgressView()
                    .scaleEffect(1.2)
            } else if authManager.isAuthenticated {
                TabView {
                    DashboardView()
                        .tabItem {
                            Label("Dashboard", systemImage: "chart.bar.fill")
                        }

                    TransactionsView()
                        .tabItem {
                            Label("Transactions", systemImage: "arrow.left.arrow.right")
                        }

                    DebtsView()
                        .tabItem {
                            Label("Debts", systemImage: "person.2.fill")
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
            } else {
                SignInView(authManager: authManager)
            }
        }
        .preferredColorScheme(colorScheme)
        .dynamicTypeSize(dynamicTypeSize)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authManager.isCheckingCredential)
    }
}

#Preview {
    ContentView(authManager: AuthenticationManager())
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self, RecurringPayment.self])
}
