//
//  TransactionTemplate.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 5/8/26.
//

import Foundation
import SwiftData

@Model
final class TransactionTemplate {
    var id: UUID = UUID()
    var name: String = ""
    var amount: Decimal = 0
    var type: TransactionType = TransactionType.expense
    var categoryName: String = ""
    var categoryIcon: String = ""
    var accountName: String = ""
    var usageCount: Int = 0
    var createdAt: Date = Date()

    var account: Account?
    var category: Category?

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        type: TransactionType = .expense,
        account: Account? = nil,
        category: Category? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.type = type
        self.account = account
        self.category = category
        self.categoryName = category?.name ?? ""
        self.categoryIcon = category?.icon ?? ""
        self.accountName = account?.name ?? ""
        self.usageCount = 0
        self.createdAt = Date()
    }
}
