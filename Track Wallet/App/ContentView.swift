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
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authManager.isCheckingCredential)
    }
}

#Preview {
    ContentView(authManager: AuthenticationManager())
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self])
}
