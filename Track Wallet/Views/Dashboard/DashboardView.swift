//
//  DashboardView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var accounts: [Account]
    @Query private var debts: [Debt]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var recurringPayments: [RecurringPayment]

    @State private var calculator = FinanceCalculator()

    var assetAccounts: [Account] {
        accounts.filter { $0.isAsset }.sorted { $0.name < $1.name }
    }

    var liabilityAccounts: [Account] {
        accounts.filter { !$0.isAsset }.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            List {
                // Net Worth
                Section {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.sm)
                                    .fill(
                                        LinearGradient(
                                            colors: calculator.totalNetWorth >= 0
                                                ? [AppTheme.income, AppTheme.income.opacity(0.7)]
                                                : [AppTheme.expense, AppTheme.expense.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Net Worth")
                                .font(AppTypography.callout)
                                .foregroundColor(AppTheme.textSecondary)

                            Text(calculator.totalNetWorth.currencyFormatted)
                                .font(AppTypography.amountMedium)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Overview
                Section {
                    FinancialStatRow(icon: "banknote.fill", title: "Cash", amount: calculator.totalCash, color: AppTheme.income)
                    FinancialStatRow(icon: "building.columns.fill", title: "Bank", amount: calculator.totalBankBalance, color: AppTheme.primary)
                    FinancialStatRow(icon: "creditcard.fill", title: "Credit Due", amount: calculator.totalCreditDue, color: AppTheme.expense)
                } header: {
                    Label("Overview", systemImage: "square.grid.2x2.fill")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                // Debts
                if calculator.totalLending > 0 || calculator.totalBorrowing > 0 {
                    Section {
                        if calculator.totalLending > 0 {
                            FinancialStatRow(icon: "arrow.up.circle.fill", title: "You'll Receive", amount: calculator.totalLending, color: AppTheme.transfer)
                        }
                        if calculator.totalBorrowing > 0 {
                            FinancialStatRow(icon: "arrow.down.circle.fill", title: "You Owe", amount: calculator.totalBorrowing, color: AppTheme.liability)
                        }
                    } header: {
                        Label("Debts", systemImage: "person.2.fill")
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                // Upcoming Recurring
                if !calculator.upcomingRecurringPayments.isEmpty {
                    Section {
                        ForEach(calculator.upcomingRecurringPayments.prefix(3)) { payment in
                            NavigationLink(destination: RecurringPaymentDetailView(payment: payment)) {
                                UpcomingPaymentRow(payment: payment)
                            }
                        }

                        if calculator.activeRecurringCount > 3 {
                            NavigationLink(destination: RecurringPaymentsView()) {
                                HStack {
                                    Text("See All")
                                        .font(AppTypography.callout)
                                        .foregroundColor(AppTheme.primary)
                                    Spacer()
                                    Text("\(calculator.activeRecurringCount) active")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                        }
                    } header: {
                        Label("Upcoming Payments", systemImage: "arrow.clockwise.circle.fill")
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                // Assets
                if !assetAccounts.isEmpty {
                    Section {
                        ForEach(assetAccounts) { account in
                            NavigationLink(destination: AccountDetailView(account: account)) {
                                AccountRowView(account: account, isAsset: true)
                            }
                        }
                    } header: {
                        HStack {
                            Label("Assets", systemImage: "arrow.up.right.circle.fill")
                                .font(AppTypography.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text(calculator.totalAssets.currencyFormatted)
                                .font(AppTypography.calloutEmphasized)
                                .foregroundColor(AppTheme.income)
                        }
                    }
                }

                // Liabilities
                if !liabilityAccounts.isEmpty {
                    Section {
                        ForEach(liabilityAccounts) { account in
                            NavigationLink(destination: AccountDetailView(account: account)) {
                                AccountRowView(account: account, isAsset: false)
                            }
                        }
                    } header: {
                        HStack {
                            Label("Liabilities", systemImage: "arrow.down.right.circle.fill")
                                .font(AppTypography.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text(calculator.totalLiabilities.currencyFormatted)
                                .font(AppTypography.calloutEmphasized)
                                .foregroundColor(AppTheme.expense)
                        }
                    }
                }

                // Recent Transactions
                if !transactions.isEmpty {
                    Section {
                        ForEach(transactions.prefix(5)) { transaction in
                            NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                TransactionRowView(transaction: transaction)
                            }
                        }
                    } header: {
                        Label("Recent Transactions", systemImage: "clock.arrow.circlepath")
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
        .onAppear {
            calculator.update(accounts: accounts, debts: debts, transactions: transactions, recurringPayments: recurringPayments)
        }
        .onChange(of: accounts) { _, newValue in
            calculator.update(accounts: newValue, debts: debts, transactions: transactions, recurringPayments: recurringPayments)
        }
        .onChange(of: debts) { _, newValue in
            calculator.update(accounts: accounts, debts: newValue, transactions: transactions, recurringPayments: recurringPayments)
        }
        .onChange(of: transactions) { _, newValue in
            calculator.update(accounts: accounts, debts: debts, transactions: newValue, recurringPayments: recurringPayments)
        }
        .onChange(of: recurringPayments) { _, newValue in
            calculator.update(accounts: accounts, debts: debts, transactions: transactions, recurringPayments: newValue)
        }
    }
}

// MARK: - Supporting Views

struct FinancialStatRow: View {
    let icon: String
    let title: String
    let amount: Decimal
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.xs)
                        .fill(color)
                )

            Text(title)
                .font(AppTypography.body)

            Spacer()

            Text(amount.currencyFormatted)
                .font(AppTypography.bodyEmphasized)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

struct UpcomingPaymentRow: View {
    let payment: RecurringPayment

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .stroke(AppTheme.primary.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)
                Circle()
                    .trim(from: 0, to: CGFloat(payment.progress))
                    .stroke(payment.isOverdue ? AppTheme.expense : AppTheme.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(payment.isOverdue ? AppTheme.expense : AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(payment.name)
                    .font(AppTypography.body)
                    .lineLimit(1)
                Text(payment.nextPaymentDate.formatted(date: .abbreviated, time: .omitted))
                    .font(AppTypography.caption)
                    .foregroundColor(payment.isOverdue ? AppTheme.expense : AppTheme.textSecondary)
            }

            Spacer()

            Text(payment.installmentAmount.currencyFormatted)
                .font(AppTypography.bodyEmphasized)
                .foregroundColor(payment.isOverdue ? AppTheme.expense : AppTheme.textPrimary)
        }
    }
}

struct AccountRowView: View {
    let account: Account
    let isAsset: Bool

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            if account.faviconURL != nil {
                AccountIconView(account: account, size: 36, cornerRadius: AppRadius.xs)
            } else {
                Image(systemName: account.icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.xs)
                            .fill(isAsset ? AppTheme.asset : AppTheme.liability)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(AppTypography.body)

                if account.type == .creditCard {
                    Text("Limit: \(account.creditLimit.currencyFormatted)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()

            Text(account.currentBalance.currencyFormatted)
                .font(AppTypography.bodyEmphasized)
                .foregroundColor(isAsset ? AppTheme.income : AppTheme.expense)
        }
    }
}

struct TransactionRowView: View {
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
        HStack(spacing: AppSpacing.md) {
            Image(systemName: transaction.category?.icon ?? typeIcon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.xs)
                        .fill(typeColor)
                )

            VStack(alignment: .leading, spacing: 4) {
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

            VStack(alignment: .trailing, spacing: 4) {
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
    DashboardView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self, RecurringPayment.self])
}
