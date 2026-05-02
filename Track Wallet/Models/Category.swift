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
    
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]?
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.fill",
        color: String = "blue",
        type: TransactionType = .expense,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.type = type
        self.createdAt = createdAt
        self.transactions = []
    }
}
