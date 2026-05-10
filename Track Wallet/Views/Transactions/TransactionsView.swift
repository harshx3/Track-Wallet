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
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Account.name) private var accounts: [Account]

    @State private var showingAddTransaction = false
    @State private var searchText = ""
    @State private var filterType: TransactionFilterType = .all
    @State private var filterCategory: Category?
    @State private var filterAccount: Account?
    @State private var sortOrder: TransactionSortOrder = .newestFirst
    @State private var dateRange: DateRangeFilter = .allTime

    var filteredTransactions: [Transaction] {
        var result = transactions

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.transactionDescription.lowercased().contains(query) ||
                ($0.category?.name.lowercased().contains(query) ?? false) ||
                ($0.fromAccount?.name.lowercased().contains(query) ?? false) ||
                $0.type.rawValue.lowercased().contains(query)
            }
        }

        switch filterType {
        case .all: break
        case .income: result = result.filter { $0.type == .income }
        case .expense: result = result.filter { $0.type == .expense }
        case .transfer: result = result.filter { $0.type == .transfer }
        }

        if let cat = filterCategory {
            result = result.filter { $0.category?.id == cat.id }
        }

        if let acc = filterAccount {
            result = result.filter { $0.fromAccount?.id == acc.id || $0.toAccount?.id == acc.id }
        }

        if let startDate = dateRange.startDate {
            result = result.filter { $0.date >= startDate }
        }

        switch sortOrder {
        case .newestFirst: result.sort { $0.date > $1.date }
        case .oldestFirst: result.sort { $0.date < $1.date }
        case .highestAmount: result.sort { $0.amount > $1.amount }
        case .lowestAmount: result.sort { $0.amount < $1.amount }
        }

        return result
    }

    var hasActiveFilters: Bool {
        filterType != .all || filterCategory != nil || filterAccount != nil || dateRange != .allTime || sortOrder != .newestFirst
    }

    var body: some View {
        NavigationStack {
            List {
                if !transactions.isEmpty {
                    filterSection
                }

                if filteredTransactions.isEmpty {
                    if transactions.isEmpty {
                        ContentUnavailableView {
                            Label("No Transactions", systemImage: "list.bullet.rectangle")
                        } description: {
                            Text("Add your first expense or income to start tracking your money.")
                        } actions: {
                            Button {
                                showingAddTransaction = true
                            } label: {
                                Label("Add Transaction", systemImage: "plus.circle.fill")
                            }
                        }
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                } else {
                    let grouped = groupedByDate(filteredTransactions)
                    ForEach(grouped, id: \.0) { date, txns in
                        Section {
                            ForEach(txns) { transaction in
                                NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                    TransactionListRow(transaction: transaction)
                                }
                            }
                            .onDelete { offsets in
                                deleteTransactions(txns: txns, at: offsets)
                            }
                        } header: {
                            HStack {
                                Text(sectionDateLabel(date))
                                Spacer()
                                let total = txns.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
                                if total > 0 {
                                    Text("-\(total.currencyFormatted)")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppTheme.expense)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(TransactionSortOrder.allCases, id: \.self) { order in
                                Button {
                                    withAnimation { sortOrder = order }
                                } label: {
                                    HStack {
                                        Text(order.rawValue)
                                        if sortOrder == order {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .symbolVariant(sortOrder != .newestFirst ? .circle.fill : .none)
                        }

                        Button {
                            showingAddTransaction = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
        }
    }

    // MARK: - Filter Section

    @ViewBuilder
    private var filterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransactionFilterType.allCases, id: \.self) { type in
                        FilterChip(title: type.rawValue, isSelected: filterType == type) {
                            withAnimation(.easeInOut(duration: 0.2)) { filterType = type }
                        }
                    }

                    Divider().frame(height: 24)

                    Menu {
                        Button("All Categories") { filterCategory = nil }
                        ForEach(categories) { cat in
                            Button {
                                filterCategory = cat
                            } label: {
                                Label(cat.name, systemImage: cat.icon)
                            }
                        }
                    } label: {
                        FilterChip(
                            title: filterCategory?.name ?? "Category",
                            isSelected: filterCategory != nil,
                            action: {}
                        )
                        .allowsHitTesting(false)
                    }

                    Menu {
                        Button("All Accounts") { filterAccount = nil }
                        ForEach(accounts) { acc in
                            Button {
                                filterAccount = acc
                            } label: {
                                Label(acc.name, systemImage: acc.icon)
                            }
                        }
                    } label: {
                        FilterChip(
                            title: filterAccount?.name ?? "Account",
                            isSelected: filterAccount != nil,
                            action: {}
                        )
                        .allowsHitTesting(false)
                    }

                    Divider().frame(height: 24)

                    Menu {
                        ForEach(DateRangeFilter.allCases, id: \.self) { range in
                            Button {
                                withAnimation { dateRange = range }
                            } label: {
                                HStack {
                                    Text(range.rawValue)
                                    if dateRange == range {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        FilterChip(
                            title: dateRange == .allTime ? "Date" : dateRange.rawValue,
                            isSelected: dateRange != .allTime,
                            action: {}
                        )
                        .allowsHitTesting(false)
                    }

                    if hasActiveFilters {
                        Button {
                            withAnimation {
                                filterType = .all
                                filterCategory = nil
                                filterAccount = nil
                                dateRange = .allTime
                                sortOrder = .newestFirst
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Helpers

    private func groupedByDate(_ txns: [Transaction]) -> [(Date, [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: txns) { calendar.startOfDay(for: $0.date) }
        return grouped.sorted { $0.key > $1.key }
    }

    private func sectionDateLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private func deleteTransactions(txns: [Transaction], at offsets: IndexSet) {
        HapticManager.notification(.warning)
        for index in offsets {
            let transaction = txns[index]
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

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? AppTheme.primary : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Transaction Filter

enum TransactionFilterType: String, CaseIterable {
    case all = "All"
    case income = "Income"
    case expense = "Expense"
    case transfer = "Transfer"
}

enum TransactionSortOrder: String, CaseIterable {
    case newestFirst = "Newest First"
    case oldestFirst = "Oldest First"
    case highestAmount = "Highest Amount"
    case lowestAmount = "Lowest Amount"
}

enum DateRangeFilter: String, CaseIterable {
    case allTime = "All Time"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case last3Months = "3 Months"
    case last6Months = "6 Months"

    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .allTime: return nil
        case .today: return calendar.startOfDay(for: now)
        case .thisWeek: return calendar.dateInterval(of: .weekOfYear, for: now)?.start
        case .thisMonth: return calendar.dateInterval(of: .month, for: now)?.start
        case .lastMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else { return nil }
            return calendar.dateInterval(of: .month, for: lastMonth)?.start
        case .last3Months: return calendar.date(byAdding: .month, value: -3, to: now)
        case .last6Months: return calendar.date(byAdding: .month, value: -6, to: now)
        }
    }
}

// MARK: - Row

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

                Text(transaction.date.formatted(date: .omitted, time: .shortened))
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

#Preview {
    TransactionsView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self, TransactionTemplate.self])
}
