//
//  AccountsView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.createdAt, order: .reverse) private var accounts: [Account]
    
    @State private var showingAddAccount = false
    @State private var selectedAccount: Account?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if accounts.isEmpty {
                        ContentUnavailableView(
                            "No Accounts",
                            systemImage: "wallet.pass",
                            description: Text("Add your first account to start tracking")
                        )
                        .frame(height: 400)
                    } else {
                        ForEach(accounts) { account in
                            AccountCard(account: account)
                                .onTapGesture {
                                    selectedAccount = account
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Accounts")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddAccount = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
            }
            .sheet(item: $selectedAccount) { account in
                AccountDetailView(account: account)
            }
        }
    }
}

struct AccountCard: View {
    let account: Account
    
    var gradientColors: [Color] {
        let baseColor = account.color.toColor
        return [baseColor.opacity(0.8), baseColor.opacity(0.6)]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if account.faviconURL != nil {
                    AccountIconView(account: account, size: 44, cornerRadius: 22)
                } else {
                    Image(systemName: account.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.white.opacity(0.2))
                        )
                }
                
                Spacer()
                
                Text(account.type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.2))
                    )
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                
                Text(account.balance.currencyFormatted)
                    .font(AppTypography.amountMedium)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(20)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: account.color.toColor.opacity(0.3), radius: 15, y: 8)
    }
}

#Preview {
    AccountsView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self])
}
