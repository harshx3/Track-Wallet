//
//  TransactionRow.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: iconName)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.transactionDescription.isEmpty ? transaction.type.rawValue : transaction.transactionDescription)
                    .font(AppTypography.body)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let category = transaction.category {
                        Text(category.name)
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Text(transaction.date, style: .date)
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(amountText)
                    .font(AppTypography.bodyEmphasized)
                    .foregroundColor(amountColor)

                if let accountName = accountName {
                    Text(accountName)
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch transaction.type {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .reimbursed: return "arrow.counterclockwise.circle.fill"
        }
    }

    private var iconColor: Color {
        switch transaction.type {
        case .income, .reimbursed: return AppTheme.income
        case .expense: return AppTheme.expense
        case .transfer: return AppTheme.transfer
        }
    }

    private var amountText: String {
        let formatted = transaction.amount.currencyFormatted
        switch transaction.type {
        case .income, .reimbursed: return "+ \(formatted)"
        case .expense: return "- \(formatted)"
        case .transfer: return formatted
        }
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income, .reimbursed: return AppTheme.income
        case .expense: return AppTheme.expense
        case .transfer: return AppTheme.textPrimary
        }
    }

    private var accountName: String? {
        if transaction.type == .transfer,
           let from = transaction.fromAccount,
           let to = transaction.toAccount {
            return "\(from.name) → \(to.name)"
        }
        return transaction.fromAccount?.name ?? transaction.toAccount?.name
    }
}

#Preview {
    List {
        TransactionRow(transaction: Transaction(
            amount: 50.00,
            type: .income,
            transactionDescription: "Freelance Payment",
            date: Date()
        ))

        TransactionRow(transaction: Transaction(
            amount: 25.50,
            type: .expense,
            transactionDescription: "Coffee Shop",
            date: Date()
        ))

        TransactionRow(transaction: Transaction(
            amount: 100.00,
            type: .transfer,
            transactionDescription: "Savings Transfer",
            date: Date()
        ))
    }
}
