//
//  FinanceCalculator.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import Foundation
import SwiftData

@Observable
class FinanceCalculator {
    var accounts: [Account] = []
    var debts: [Debt] = []
    var transactions: [Transaction] = []
    var recurringPayments: [RecurringPayment] = []

    var totalAssets: Decimal {
        accounts.filter { $0.isAsset }.reduce(Decimal(0)) { $0 + $1.currentBalance }
    }

    var totalLiabilities: Decimal {
        accounts.filter { !$0.isAsset }.reduce(Decimal(0)) { $0 + $1.currentBalance }
    }

    var totalNetWorth: Decimal {
        totalAssets - totalLiabilities
    }

    var totalCash: Decimal {
        accounts.filter { $0.type == .cash }.reduce(Decimal(0)) { $0 + $1.currentBalance }
    }

    var totalBankBalance: Decimal {
        accounts.filter { $0.type == .bank }.reduce(Decimal(0)) { $0 + $1.currentBalance }
    }

    var totalCreditDue: Decimal {
        accounts.filter { $0.type == .creditCard }.reduce(Decimal(0)) { $0 + max(0, $1.currentBalance) }
    }

    var totalCreditLimit: Decimal {
        accounts.filter { $0.type == .creditCard }.reduce(Decimal(0)) { $0 + $1.creditLimit }
    }

    var creditUtilization: Double {
        guard totalCreditLimit > 0 else { return 0 }
        let value = Double(truncating: (totalCreditDue / totalCreditLimit) as NSDecimalNumber)
        guard value.isFinite else { return 0 }
        return min(1.0, max(0, value))
    }

    var totalLending: Decimal {
        let grouped = Dictionary(grouping: debts) {
            $0.personName.trimmingCharacters(in: .whitespaces).lowercased()
        }
        return grouped.values.reduce(Decimal(0)) { total, personDebts in
            let lending = personDebts.filter { $0.type == .lending && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
            let borrowing = personDebts.filter { $0.type == .borrowing && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
            let net = lending - borrowing
            return total + max(0, net)
        }
    }

    var totalBorrowing: Decimal {
        let grouped = Dictionary(grouping: debts) {
            $0.personName.trimmingCharacters(in: .whitespaces).lowercased()
        }
        return grouped.values.reduce(Decimal(0)) { total, personDebts in
            let lending = personDebts.filter { $0.type == .lending && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
            let borrowing = personDebts.filter { $0.type == .borrowing && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
            let net = lending - borrowing
            return total + max(0, -net)
        }
    }

    // MARK: - Monthly

    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        return transactions.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
    }

    var monthlySpending: Decimal {
        currentMonthTransactions
            .filter { $0.type == .expense }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    var monthlyIncome: Decimal {
        currentMonthTransactions
            .filter { $0.type == .income }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    var monthlySaved: Decimal {
        monthlyIncome - monthlySpending
    }

    var topSpendingCategory: (name: String, icon: String, amount: Decimal)? {
        let expenses = currentMonthTransactions.filter { $0.type == .expense && $0.category != nil }
        let grouped = Dictionary(grouping: expenses) { $0.category?.name ?? "" }
        guard let top = grouped.max(by: { a, b in
            a.value.reduce(Decimal(0)) { $0 + $1.amount } < b.value.reduce(Decimal(0)) { $0 + $1.amount }
        }) else { return nil }
        let amount = top.value.reduce(Decimal(0)) { $0 + $1.amount }
        let icon = top.value.first?.category?.icon ?? "folder.fill"
        return (name: top.key, icon: icon, amount: amount)
    }

    struct CategorySpending: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let color: String
        let amount: Decimal
        let percentage: Double
    }

    var categoryBreakdown: [CategorySpending] {
        let expenses = currentMonthTransactions.filter { $0.type == .expense && $0.category != nil }
        let grouped = Dictionary(grouping: expenses) { $0.category?.id ?? UUID() }
        let total = monthlySpending
        guard total > 0 else { return [] }

        return grouped.compactMap { _, txns -> CategorySpending? in
            guard let cat = txns.first?.category else { return nil }
            let amount = txns.reduce(Decimal(0)) { $0 + $1.amount }
            let pct = Double(truncating: (amount / total) as NSDecimalNumber)
            return CategorySpending(name: cat.name, icon: cat.icon, color: cat.color, amount: amount, percentage: pct.isFinite ? pct : 0)
        }.sorted { $0.amount > $1.amount }
    }

    struct MonthlyTotal: Identifiable {
        let id = UUID()
        let month: Date
        let spending: Decimal
        let income: Decimal
    }

    struct NetWorthPoint: Identifiable {
        let id = UUID()
        let month: Date
        let netWorth: Decimal
    }

    var last6MonthsTotals: [MonthlyTotal] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<6).reversed().compactMap { offset -> MonthlyTotal? in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: now) else { return nil }
            let monthTxns = transactions.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
            let spending = monthTxns.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
            let income = monthTxns.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount }
            return MonthlyTotal(month: month, spending: spending, income: income)
        }
    }

    var netWorthTrend: [NetWorthPoint] {
        let monthlyTotals = last6MonthsTotals
        guard !monthlyTotals.isEmpty else { return [] }

        var points: [NetWorthPoint] = []
        var cumulative: Decimal = 0

        for i in stride(from: monthlyTotals.count - 1, through: 0, by: -1) {
            let item = monthlyTotals[i]
            let estimated = totalNetWorth - cumulative
            points.insert(NetWorthPoint(month: item.month, netWorth: estimated), at: 0)
            cumulative += (item.income - item.spending)
        }

        return points
    }

    // MARK: - Recurring

    var activeRecurringCount: Int {
        recurringPayments.filter { $0.isActive && !$0.isCompleted }.count
    }

    var totalMonthlyRecurring: Decimal {
        recurringPayments
            .filter { $0.isActive && !$0.isCompleted && $0.frequency == .monthly }
            .reduce(Decimal(0)) { $0 + $1.installmentAmount }
    }

    var activeSubscriptionCount: Int {
        recurringPayments.filter { $0.isActive && !$0.isCompleted && $0.isSubscription }.count
    }

    var upcomingRecurringPayments: [RecurringPayment] {
        recurringPayments
            .filter { $0.isActive && !$0.isCompleted }
            .sorted { $0.nextPaymentDate < $1.nextPaymentDate }
    }

    var upcomingBillsTotal: Decimal {
        let calendar = Calendar.current
        let now = Date()
        guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: calendar.startOfDay(for: now)) else { return 0 }
        return recurringPayments
            .filter { $0.isActive && !$0.isCompleted && $0.nextPaymentDate < monthEnd }
            .reduce(Decimal(0)) { $0 + $1.installmentAmount }
    }

    func update(accounts: [Account], debts: [Debt], transactions: [Transaction], recurringPayments: [RecurringPayment] = []) {
        self.accounts = accounts
        self.debts = debts
        self.transactions = transactions
        self.recurringPayments = recurringPayments
    }
}
