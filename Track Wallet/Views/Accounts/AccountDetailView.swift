//
//  AccountDetailView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct AccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: Account

    @State private var showingAddDeposit = false
    @State private var showingPayCreditCard = false
    @State private var showingEditAccount = false
    @State private var showingDeleteAlert = false

    var accountTransactions: [Transaction] {
        let outgoing = account.outgoingTransactions ?? []
        let incoming = account.incomingTransactions ?? []
        return (outgoing + incoming).sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            // Balance
            Section {
                VStack(spacing: 4) {
                    Text(account.type.rawValue)
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    Text(account.currentBalance.currencyFormatted)
                        .font(AppTypography.amountMedium)
                        .foregroundColor(account.type == .creditCard && account.currentBalance > 0 ? AppTheme.expense : AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                if account.type == .creditCard {
                    HStack {
                        Text("Credit Limit")
                        Spacer()
                        Text(account.creditLimit.currencyFormatted)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    HStack {
                        Text("Available")
                        Spacer()
                        Text(account.availableCredit.currencyFormatted)
                            .foregroundColor(AppTheme.income)
                    }
                }
            }

            // Quick Actions
            Section {
                ForEach(account.type.availableActions, id: \.self) { action in
                    Button {
                        if action == .payBill {
                            showingPayCreditCard = true
                        } else {
                            showingAddDeposit = true
                        }
                    } label: {
                        Label(action.rawValue, systemImage: action.icon)
                    }
                }
            }

            // Transactions
            Section {
                if accountTransactions.isEmpty {
                    Text("No transactions yet")
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, AppSpacing.lg)
                } else {
                    ForEach(accountTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            } header: {
                Text("Transactions")
            }
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditAccount = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddDeposit) {
            AddDepositView(account: account)
        }
        .sheet(isPresented: $showingPayCreditCard) {
            PayCreditCardView(creditCardAccount: account)
        }
        .sheet(isPresented: $showingEditAccount) {
            EditAccountView(account: account)
        }
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(account)
                dismiss()
            }
        } message: {
            Text("This will also delete all transactions for this account.")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Account.self, Transaction.self, configurations: config)

    let account = Account(name: "Chase Bank", type: .bank, openingBalance: 5000, currentBalance: 5000)
    container.mainContext.insert(account)

    return NavigationStack {
        AccountDetailView(account: account)
    }
    .modelContainer(container)
}
