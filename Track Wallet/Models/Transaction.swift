//
//  Transaction.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID = UUID()
    var amount: Decimal = 0
    var type: TransactionType = TransactionType.expense
    var transactionDescription: String = ""
    var paymentMethod: String = ""
    var notes: String = ""
    var date: Date = Date()
    var createdAt: Date = Date()
    
    var fromAccount: Account?
    var toAccount: Account?
    var category: Category?
    var debt: Debt?
    
    init(
        id: UUID = UUID(),
        amount: Decimal,
        type: TransactionType,
        transactionDescription: String = "",
        paymentMethod: String = "",
        notes: String = "",
        date: Date = Date(),
        createdAt: Date = Date(),
        fromAccount: Account? = nil,
        toAccount: Account? = nil,
        category: Category? = nil,
        debt: Debt? = nil
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.transactionDescription = transactionDescription
        self.paymentMethod = paymentMethod
        self.notes = notes
        self.date = date
        self.createdAt = createdAt
        self.fromAccount = fromAccount
        self.toAccount = toAccount
        self.category = category
        self.debt = debt
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "Income"
    case expense = "Expense"
    case transfer = "Transfer"
    case reimbursed = "Reimbursed"
}
