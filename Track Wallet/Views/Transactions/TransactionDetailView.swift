//
//  TransactionDetailView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let transaction: Transaction

    @State private var showingSaveTemplate = false
    @State private var templateName = ""

    var typeColor: Color {
        switch transaction.type {
        case .income: return AppTheme.income
        case .expense: return AppTheme.expense
        case .transfer: return AppTheme.transfer
        case .reimbursed: return AppTheme.income
        }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: AppSpacing.xs) {
                    Text(transaction.amount.currencyFormatted)
                        .font(AppTypography.amountLarge)
                        .foregroundColor(typeColor)

                    Text(transaction.type.rawValue)
                        .font(AppTypography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(typeColor))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
            }
            .listRowBackground(Color.clear)

            Section {
                HStack {
                    Label("Date", systemImage: "calendar")
                    Spacer()
                    Text(transaction.date.formatted(date: .long, time: .shortened))
                        .foregroundColor(AppTheme.textSecondary)
                }

                if let category = transaction.category {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: category.icon)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(RoundedRectangle(cornerRadius: 6).fill(category.color.toColor))
                        Text("Category")
                        Spacer()
                        Text(category.name)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                if let fromAccount = transaction.fromAccount {
                    HStack(spacing: AppSpacing.sm) {
                        AccountIconView(account: fromAccount, size: 28, cornerRadius: 6)
                        Text(transaction.type == .transfer ? "From" : "Account")
                        Spacer()
                        Text(fromAccount.name)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                if let toAccount = transaction.toAccount {
                    HStack(spacing: AppSpacing.sm) {
                        AccountIconView(account: toAccount, size: 28, cornerRadius: 6)
                        Text("To")
                        Spacer()
                        Text(toAccount.name)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }

            if !transaction.transactionDescription.isEmpty {
                Section("Note") {
                    Text(transaction.transactionDescription)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Section {
                Button {
                    showingSaveTemplate = true
                } label: {
                    Label("Save as Template", systemImage: "bolt.circle")
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Save Template", isPresented: $showingSaveTemplate) {
            TextField("Template Name", text: $templateName)
            Button("Cancel", role: .cancel) { templateName = "" }
            Button("Save") {
                saveAsTemplate()
            }
        } message: {
            Text("Give this template a name for quick reuse.")
        }
    }

    private func saveAsTemplate() {
        let name = templateName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let template = TransactionTemplate(
            name: name,
            amount: transaction.amount,
            type: transaction.type,
            account: transaction.fromAccount,
            category: transaction.category
        )
        modelContext.insert(template)
        HapticManager.notification(.success)
        templateName = ""
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Transaction.self, Account.self, Category.self, TransactionTemplate.self, configurations: config)

    let account = Account(name: "Cash", type: .cash, openingBalance: 100, currentBalance: 100)
    let category = Category(name: "Food", icon: "fork.knife", color: "orange")
    let transaction = Transaction(
        amount: 25.50,
        type: .expense,
        transactionDescription: "Lunch at restaurant",
        fromAccount: account,
        category: category
    )

    container.mainContext.insert(account)
    container.mainContext.insert(category)
    container.mainContext.insert(transaction)

    return NavigationStack {
        TransactionDetailView(transaction: transaction)
    }
    .modelContainer(container)
}
