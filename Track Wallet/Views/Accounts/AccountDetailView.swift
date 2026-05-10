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

    private var utilization: Double {
        guard account.type == .creditCard, account.creditLimit > 0 else { return 0 }
        let value = Double(truncating: (account.currentBalance / account.creditLimit) as NSDecimalNumber)
        guard value.isFinite else { return 0 }
        return min(1.0, max(0, value))
    }

    private var monthlySpending: Decimal {
        let calendar = Calendar.current
        let now = Date()
        return accountTransactions
            .filter { $0.type == .expense && calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    var body: some View {
        List {
            balanceSection
            if account.type == .creditCard { creditUtilizationSection }
            quickActionsSection
            if monthlySpending > 0 { monthlySection }
            transactionsSection
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

    // MARK: - Balance

    @ViewBuilder
    private var balanceSection: some View {
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
        }
    }

    // MARK: - Credit Utilization

    @ViewBuilder
    private var creditUtilizationSection: some View {
        Section {
            VStack(spacing: AppSpacing.sm) {
                ProgressView(value: utilization)
                    .tint(utilizationColor)

                HStack {
                    Text("\(Int(utilization * 100))% utilized")
                        .font(AppTypography.caption)
                        .foregroundColor(utilizationColor)
                    Spacer()
                    Text("Available: \(account.availableCredit.currencyFormatted)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            HStack {
                Text("Credit Limit")
                Spacer()
                Text(account.creditLimit.currencyFormatted)
                    .foregroundColor(AppTheme.textSecondary)
            }

            HStack {
                Text("Balance")
                Spacer()
                Text(account.currentBalance.currencyFormatted)
                    .foregroundColor(AppTheme.expense)
            }

            HStack {
                Text("Available")
                Spacer()
                Text(account.availableCredit.currencyFormatted)
                    .foregroundColor(AppTheme.income)
            }

            if let dueDate = account.nextDueDate {
                HStack {
                    Text("Next Due Date")
                    Spacer()
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .foregroundColor(account.isDueSoon ? AppTheme.expense : AppTheme.textSecondary)
                }
            }
        } header: {
            Label("Credit Utilization", systemImage: "creditcard.trianglebadge.exclamationmark.fill")
        }
    }

    private var utilizationColor: Color {
        if utilization < 0.3 { return AppTheme.income }
        if utilization < 0.7 { return AppTheme.transfer }
        return AppTheme.expense
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private var quickActionsSection: some View {
        Section {
            ForEach(account.type.availableActions, id: \.self) { action in
                Button {
                    HapticManager.impact(.light)
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
    }

    // MARK: - Monthly

    @ViewBuilder
    private var monthlySection: some View {
        Section {
            HStack {
                Label("This Month", systemImage: "calendar")
                Spacer()
                Text(monthlySpending.currencyFormatted)
                    .font(AppTypography.bodyEmphasized)
                    .foregroundColor(AppTheme.expense)
            }
        }
    }

    // MARK: - Transactions

    @ViewBuilder
    private var transactionsSection: some View {
        Section {
            if accountTransactions.isEmpty {
                ContentUnavailableView(
                    "No Transactions",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Transactions for this account will appear here")
                )
            } else {
                ForEach(accountTransactions.prefix(20)) { transaction in
                    NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: transaction.category?.icon ?? "arrow.left.arrow.right")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(transaction.type == .expense ? AppTheme.expense : transaction.type == .income ? AppTheme.income : AppTheme.transfer)
                                )

                            VStack(alignment: .leading, spacing: 1) {
                                Text(transaction.category?.name ?? transaction.type.rawValue)
                                    .font(AppTypography.body)
                                    .lineLimit(1)
                                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Spacer()

                            Text(transaction.amount.currencyFormatted)
                                .font(AppTypography.bodyEmphasized)
                                .foregroundColor(transaction.type == .expense ? AppTheme.expense : AppTheme.income)
                        }
                    }
                }

                if accountTransactions.count > 20 {
                    Text("\(accountTransactions.count - 20) more transactions")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        } header: {
            HStack {
                Text("Transactions")
                Spacer()
                Text("\(accountTransactions.count) total")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
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
