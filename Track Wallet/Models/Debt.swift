//
//  Debt.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import Foundation
import SwiftData

@Model
final class Debt {
    var id: UUID = UUID()
    var personName: String = ""
    var amount: Decimal = 0
    var type: DebtType = DebtType.lending
    var debtDescription: String = ""
    var date: Date = Date()
    var dueDate: Date?
    var isPaid: Bool = false
    var createdAt: Date = Date()
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.debt)
    var transactions: [Transaction]?
    
    init(
        id: UUID = UUID(),
        personName: String,
        amount: Decimal,
        type: DebtType,
        debtDescription: String = "",
        date: Date = Date(),
        dueDate: Date? = nil,
        isPaid: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.personName = personName
        self.amount = amount
        self.type = type
        self.debtDescription = debtDescription
        self.date = date
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.createdAt = createdAt
        self.transactions = []
    }
    
    var remainingAmount: Decimal {
        let paid = transactions?.reduce(Decimal(0)) { $0 + $1.amount } ?? 0
        return amount - paid
    }
}

enum DebtType: String, Codable, CaseIterable {
    case lending = "Lending" // You lent money to someone
    case borrowing = "Borrowing" // You borrowed money from someone
    
    var icon: String {
        switch self {
        case .lending: return "arrow.up.circle.fill"
        case .borrowing: return "arrow.down.circle.fill"
        }
    }
}
