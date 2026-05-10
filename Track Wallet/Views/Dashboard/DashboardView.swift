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
    @State private var showingAddTransaction = false

    var assetAccounts: [Account] {
        accounts.filter { $0.isAsset }.sorted { $0.name < $1.name }
    }

    var liabilityAccounts: [Account] {
        accounts.filter { !$0.isAsset }.sorted { $0.name < $1.name }
    }

    var creditCards: [Account] {
        accounts.filter { $0.type == .creditCard }
    }

    private var hasAnyData: Bool {
        !accounts.isEmpty || !transactions.isEmpty || !debts.isEmpty || !recurringPayments.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if hasAnyData {
                    List {
                        thisMonthSection
                        netWorthSection
                        insightsSection
                        liabilitiesAndCreditSection
                        assetsSection
                        recentTransactionsSection
                    }
                    .listSectionSpacing(.compact)
                    .animation(.easeInOut(duration: 0.3), value: accounts.count)
                    .animation(.easeInOut(duration: 0.3), value: transactions.count)
                } else {
                    emptyDashboard
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        HapticManager.impact(.light)
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
        .onAppear {
            for account in accounts where account.type == .creditCard {
                account.advanceDueDateIfNeeded()
                if account.nextBillDueDate != nil {
                    NotificationManager.shared.scheduleDueDateReminder(for: account)
                }
            }
            calculator.update(accounts: accounts, debts: debts, transactions: transactions, recurringPayments: recurringPayments)
        }
        .onChange(of: accounts) { _, new in calculator.update(accounts: new, debts: debts, transactions: transactions, recurringPayments: recurringPayments) }
        .onChange(of: debts) { _, new in calculator.update(accounts: accounts, debts: new, transactions: transactions, recurringPayments: recurringPayments) }
        .onChange(of: transactions) { _, new in calculator.update(accounts: accounts, debts: debts, transactions: new, recurringPayments: recurringPayments) }
        .onChange(of: recurringPayments) { _, new in calculator.update(accounts: accounts, debts: debts, transactions: transactions, recurringPayments: new) }
    }

    // MARK: - This Month

    @ViewBuilder
    private var thisMonthSection: some View {
        Section {
            VStack(spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.sm) {
                    MonthStatCard(title: "Spent", value: calculator.monthlySpending.currencyFormatted, color: AppTheme.expense)
                    MonthStatCard(title: "Income", value: calculator.monthlyIncome.currencyFormatted, color: AppTheme.income)
                }
                HStack(spacing: AppSpacing.sm) {
                    MonthStatCard(
                        title: calculator.monthlySaved >= 0 ? "Saved" : "Over",
                        value: abs(calculator.monthlySaved).currencyFormatted,
                        color: calculator.monthlySaved >= 0 ? AppTheme.primary : AppTheme.expense
                    )
                    MonthStatCard(title: "Bills Due", value: calculator.upcomingBillsTotal.currencyFormatted, color: AppTheme.transfer)
                }
            }
            .padding(.vertical, AppSpacing.xs)
        } header: {
            HStack {
                Label("This Month", systemImage: "calendar")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Text(Date().formatted(.dateTime.month(.wide).year()))
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    // MARK: - Net Worth

    @ViewBuilder
    private var netWorthSection: some View {
        Section {
            HStack(spacing: AppSpacing.sm) {
                DashboardCard(
                    title: "Net Worth",
                    amount: calculator.totalNetWorth.currencyFormatted,
                    icon: "chart.line.uptrend.xyaxis",
                    gradient: calculator.totalNetWorth >= 0
                        ? [AppTheme.income, AppTheme.income.opacity(0.7)]
                        : [AppTheme.expense, AppTheme.expense.opacity(0.7)]
                )

                DashboardCard(
                    title: "Liabilities",
                    amount: calculator.totalLiabilities.currencyFormatted,
                    icon: "creditcard.fill",
                    gradient: [AppTheme.expense, AppTheme.expense.opacity(0.7)]
                )
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    // MARK: - Insights (Biggest Category, Money to Receive, Upcoming Payments)

    @ViewBuilder
    private var insightsSection: some View {
        let hasInsights = calculator.topSpendingCategory != nil ||
            calculator.totalLending > 0 ||
            !calculator.upcomingRecurringPayments.isEmpty

        if hasInsights {
            Section {
                if let top = calculator.topSpendingCategory {
                    InsightRowView(
                        icon: top.icon,
                        iconColor: AppTheme.expense,
                        title: "Top Spending",
                        subtitle: top.name,
                        amount: top.amount.currencyFormatted,
                        amountColor: AppTheme.expense
                    )
                }

                if calculator.totalLending > 0 {
                    NavigationLink(destination: DebtsView()) {
                        InsightRowView(
                            icon: "arrow.down.left.circle.fill",
                            iconColor: AppTheme.income,
                            title: "Money to Receive",
                            subtitle: calculator.totalBorrowing > 0 ? "You owe \(calculator.totalBorrowing.currencyFormatted)" : nil,
                            amount: calculator.totalLending.currencyFormatted,
                            amountColor: AppTheme.income
                        )
                    }
                }

                ForEach(calculator.upcomingRecurringPayments.prefix(2)) { payment in
                    NavigationLink(destination: RecurringPaymentDetailView(payment: payment)) {
                        InsightRowView(
                            icon: payment.isSubscription ? "infinity" : "arrow.clockwise",
                            iconColor: payment.isOverdue ? AppTheme.expense : AppTheme.recurring,
                            title: payment.name,
                            subtitle: payment.nextPaymentDate.formatted(date: .abbreviated, time: .omitted),
                            amount: payment.installmentAmount.currencyFormatted,
                            amountColor: payment.isOverdue ? AppTheme.expense : AppTheme.textPrimary
                        )
                    }
                }
            } header: {
                Label("Insights", systemImage: "lightbulb.fill")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - Liabilities & Credit

    @ViewBuilder
    private var liabilitiesAndCreditSection: some View {
        if !liabilityAccounts.isEmpty {
            Section {
                if !creditCards.isEmpty && calculator.totalCreditLimit > 0 {
                    VStack(spacing: AppSpacing.xs) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Overall Utilization")
                                .font(AppTypography.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text("\(Int(calculator.creditUtilization * 100))%")
                                .font(AppTypography.bodyEmphasized)
                                .foregroundColor(utilizationColor(calculator.creditUtilization))
                                .contentTransition(.numericText())
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(utilizationColor(calculator.creditUtilization))
                                    .frame(width: max(0, geo.size.width * calculator.creditUtilization), height: 6)
                                    .animation(.easeInOut(duration: 0.6), value: calculator.creditUtilization)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text("\(calculator.totalCreditDue.currencyFormatted) of \(calculator.totalCreditLimit.currencyFormatted)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text("\((calculator.totalCreditLimit - calculator.totalCreditDue).currencyFormatted) available")
                                .font(AppTypography.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                }

                ForEach(liabilityAccounts) { account in
                    NavigationLink(destination: AccountDetailView(account: account)) {
                        CreditCardRow(account: account)
                    }
                }
            } header: {
                HStack {
                    Label("Liabilities", systemImage: "creditcard.fill")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text(calculator.totalLiabilities.currencyFormatted)
                        .font(AppTypography.calloutEmphasized)
                        .foregroundColor(AppTheme.expense)
                }
            }
        }
    }

    private func utilizationColor(_ value: Double) -> Color {
        if value < 0.3 { return AppTheme.income }
        if value < 0.7 { return AppTheme.transfer }
        return AppTheme.expense
    }

    // MARK: - Assets

    @ViewBuilder
    private var assetsSection: some View {
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
    }

    // MARK: - Recent Transactions

    @ViewBuilder
    private var recentTransactionsSection: some View {
        if !transactions.isEmpty {
            Section {
                ForEach(transactions.prefix(5)) { transaction in
                    NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                        TransactionRowView(transaction: transaction)
                    }
                }
            } header: {
                HStack {
                    Label("Recent Transactions", systemImage: "clock.arrow.circlepath")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    NavigationLink {
                        TransactionsView()
                    } label: {
                        Text("See All")
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
        }
    }

    // MARK: - Empty Dashboard

    @ViewBuilder
    private var emptyDashboard: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                Spacer(minLength: 40)

                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: AppSpacing.xs) {
                    Text("Welcome to Wallet Flows")
                        .font(AppTypography.headlineLarge)

                    Text("Start by adding an account and your first transaction to see your financial overview here.")
                        .font(AppTypography.body)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }

                VStack(spacing: AppSpacing.sm) {
                    EmptyDashboardAction(
                        icon: "wallet.pass.fill",
                        title: "Add an Account",
                        subtitle: "Cash, bank, credit card, or savings",
                        color: AppTheme.primary
                    )

                    EmptyDashboardAction(
                        icon: "arrow.left.arrow.right",
                        title: "Add a Transaction",
                        subtitle: "Record your first expense or income",
                        color: AppTheme.income
                    )

                    EmptyDashboardAction(
                        icon: "person.2.fill",
                        title: "Track a Debt",
                        subtitle: "Money you lent or borrowed",
                        color: AppTheme.transfer
                    )

                    EmptyDashboardAction(
                        icon: "arrow.clockwise.circle.fill",
                        title: "Add Recurring Payment",
                        subtitle: "Bills, subscriptions, or installments",
                        color: AppTheme.recurring
                    )
                }
                .padding(.horizontal, AppSpacing.md)

                Spacer()
            }
        }
    }
}

// MARK: - Month Stat Card

struct MonthStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(color)
            Text(value)
                .font(AppTypography.bodyEmphasized)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Budget Progress Row

struct BudgetProgressRow: View {
    let category: Category

    private var spent: Decimal { category.spentThisMonth() }
    private var progress: Double { category.budgetProgress() }

    private var progressColor: Color {
        if progress < 0.6 { return AppTheme.income }
        if progress < 0.9 { return AppTheme.transfer }
        return AppTheme.expense
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: category.icon)
                        .font(.caption)
                        .foregroundColor(category.color.toColor)
                    Text(category.name)
                        .font(AppTypography.body)
                }
                Spacer()
                Text("\(spent.currencyFormatted) of \(category.monthlyBudget.currencyFormatted)")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            ProgressView(value: min(1.0, progress))
                .tint(progressColor)

            HStack {
                Text("\(Int(min(100, progress * 100)))% used")
                    .font(AppTypography.caption)
                    .foregroundColor(progressColor)
                Spacer()
                let remaining = category.monthlyBudget - spent
                Text(remaining >= 0 ? "\(remaining.currencyFormatted) left" : "\(abs(remaining).currencyFormatted) over")
                    .font(AppTypography.caption)
                    .foregroundColor(remaining >= 0 ? AppTheme.textSecondary : AppTheme.expense)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Supporting Views

struct DashboardCard: View {
    let title: String
    let amount: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.xs)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppTheme.textSecondary)

            Text(amount)
                .font(AppTypography.amountSmall)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: amount)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppTheme.cardBackground)
        )
    }
}

struct AccountRowView: View {
    let account: Account
    let isAsset: Bool

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            AccountIconView(account: account, size: 36, cornerRadius: AppRadius.xs)

            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(AppTypography.body)

                Text(account.type.rawValue)
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
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

// MARK: - Empty Dashboard Action

struct EmptyDashboardAction: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.xs)
                        .fill(color)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.bodyEmphasized)
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppTheme.cardBackground)
        )
    }
}

// MARK: - Insight Row

struct InsightRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String?
    let amount: String
    let amountColor: Color

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.body)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()

            Text(amount)
                .font(AppTypography.bodyEmphasized)
                .foregroundColor(amountColor)
        }
    }
}

// MARK: - Credit Card Row

struct CreditCardRow: View {
    let account: Account

    private var utilization: Double {
        guard account.type == .creditCard, account.creditLimit > 0, account.currentBalance > 0 else { return 0 }
        let value = Double(truncating: (account.currentBalance / account.creditLimit) as NSDecimalNumber)
        return value.isFinite ? min(1, max(0, value)) : 0
    }

    private var utilizationColor: Color {
        if utilization < 0.3 { return AppTheme.income }
        if utilization < 0.7 { return AppTheme.transfer }
        return AppTheme.expense
    }

    private var hasBalance: Bool {
        account.currentBalance > 0
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            AccountIconView(account: account, size: 36, cornerRadius: AppRadius.xs)

            VStack(alignment: .leading, spacing: 3) {
                Text(account.name)
                    .font(AppTypography.body)
                    .lineLimit(1)

                if account.type == .creditCard && account.creditLimit > 0 {
                    if hasBalance {
                        HStack(spacing: 6) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 4)

                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(utilizationColor)
                                        .frame(width: max(0, geo.size.width * utilization), height: 4)
                                        .animation(.easeInOut(duration: 0.5), value: utilization)
                                }
                            }
                            .frame(height: 4)

                            Text("\(Int(utilization * 100))%")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(utilizationColor)
                                .frame(width: 28, alignment: .trailing)
                        }
                    } else {
                        Text(account.currentBalance < 0 ? "Credit" : "Paid off")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppTheme.income)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(account.currentBalance.currencyFormatted)
                    .font(AppTypography.bodyEmphasized)
                    .foregroundColor(hasBalance ? AppTheme.expense : AppTheme.income)

                if let dueDate = account.nextDueDate {
                    let days = account.daysUntilDue ?? 0
                    Text(days == 0 ? "Due today" : days <= 5 ? "Due in \(days)d" : "Due \(dueDate.formatted(.dateTime.day().month(.abbreviated)))")
                        .font(.system(size: 10))
                        .foregroundColor(account.isDueSoon ? AppTheme.expense : AppTheme.textSecondary)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self, RecurringPayment.self, TransactionTemplate.self])
}
