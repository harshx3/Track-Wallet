//
//  TransactionsView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var showingAddTransaction = false

    var body: some View {
        NavigationStack {
            List {
                if transactions.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Add your first transaction")
                    )
                } else {
                    ForEach(transactions) { transaction in
                        NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                            TransactionListRow(transaction: transaction)
                        }
                    }
                    .onDelete(perform: deleteTransactions)
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
        }
    }

    private func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            let transaction = transactions[index]
            switch transaction.type {
            case .income:
                transaction.fromAccount?.currentBalance -= transaction.amount
            case .expense:
                if transaction.fromAccount?.type == .creditCard {
                    transaction.fromAccount?.currentBalance -= transaction.amount
                } else {
                    transaction.fromAccount?.currentBalance += transaction.amount
                }
            case .transfer:
                transaction.fromAccount?.currentBalance += transaction.amount
                if let toAccount = transaction.toAccount {
                    if toAccount.isAsset {
                        toAccount.currentBalance -= transaction.amount
                    } else {
                        toAccount.currentBalance += transaction.amount
                    }
                }
            case .reimbursed:
                transaction.fromAccount?.currentBalance -= transaction.amount
            }
            modelContext.delete(transaction)
        }
    }
}

struct TransactionListRow: View {
    let transaction: Transaction

    var typeColor: Color {
        switch transaction.type {
        case .income: return AppTheme.income
        case .expense: return AppTheme.expense
        case .transfer: return AppTheme.transfer
        case .reimbursed: return AppTheme.income
        }
    }

    var typeIcon: String {
        switch transaction.type {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .reimbursed: return "arrow.counterclockwise.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: transaction.category?.icon ?? typeIcon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(typeColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category?.name ?? transaction.type.rawValue)
                    .font(AppTypography.body)

                if !transaction.transactionDescription.isEmpty {
                    Text(transaction.transactionDescription)
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.amount.currencyFormatted)
                    .font(AppTypography.bodyEmphasized)
                    .foregroundColor(typeColor)

                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

#Preview {
    TransactionsView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self])
}
