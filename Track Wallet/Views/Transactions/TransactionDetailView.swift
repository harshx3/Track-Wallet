//
//  TransactionDetailView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let transaction: Transaction
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(transaction.amount.currencyFormatted)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Type")
                    Spacer()
                    Text(transaction.type.rawValue)
                        .foregroundColor(AppTheme.textSecondary)
                }

                HStack {
                    Text("Date")
                    Spacer()
                    Text(transaction.date.formatted(date: .long, time: .shortened))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            if let fromAccount = transaction.fromAccount {
                Section("From Account") {
                    HStack {
                        Image(systemName: fromAccount.icon)
                            .foregroundColor(fromAccount.color.toColor)
                        Text(fromAccount.name)
                    }
                }
            }

            if let toAccount = transaction.toAccount {
                Section("To Account") {
                    HStack {
                        Image(systemName: toAccount.icon)
                            .foregroundColor(toAccount.color.toColor)
                        Text(toAccount.name)
                    }
                }
            }

            if let category = transaction.category {
                Section("Category") {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color.toColor)
                        Text(category.name)
                    }
                }
            }

            if !transaction.transactionDescription.isEmpty {
                Section("Description") {
                    Text(transaction.transactionDescription)
                }
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Transaction.self, Account.self, Category.self, configurations: config)
    
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
    
    return TransactionDetailView(transaction: transaction)
        .modelContainer(container)
}
