//
//  Category.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "folder.fill"
    var color: String = "blue"
    var type: TransactionType = TransactionType.expense
    var createdAt: Date = Date()
    var monthlyBudget: Decimal = 0

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]?

    @Relationship(deleteRule: .nullify, inverse: \RecurringPayment.category)
    var recurringPayments: [RecurringPayment]?

    @Relationship(deleteRule: .nullify, inverse: \TransactionTemplate.category)
    var templates: [TransactionTemplate]?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.fill",
        color: String = "blue",
        type: TransactionType = .expense,
        createdAt: Date = Date(),
        monthlyBudget: Decimal = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.type = type
        self.createdAt = createdAt
        self.monthlyBudget = monthlyBudget
        self.transactions = []
    }

    var hasBudget: Bool {
        monthlyBudget > 0
    }

    func spentThisMonth(in transactions: [Transaction]? = nil) -> Decimal {
        let txns = transactions ?? self.transactions ?? []
        let calendar = Calendar.current
        let now = Date()
        return txns
            .filter { $0.type == .expense && calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    func budgetProgress(in transactions: [Transaction]? = nil) -> Double {
        guard monthlyBudget > 0 else { return 0 }
        let spent = spentThisMonth(in: transactions)
        let value = Double(truncating: (spent / monthlyBudget) as NSDecimalNumber)
        guard value.isFinite else { return 0 }
        return min(2.0, max(0, value))
    }
}
