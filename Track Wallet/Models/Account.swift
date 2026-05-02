//
//  Account.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Account {
    var id: UUID = UUID()
    var name: String = ""
    var type: AccountType = AccountType.cash
    var openingBalance: Decimal = 0 // For credit cards, this represents credit limit
    var currentBalance: Decimal = 0
    var icon: String = "dollarsign.circle.fill"
    var color: String = "blue"
    var createdAt: Date = Date()
    var isPaymentMethod: Bool = true
    var isAsset: Bool = true
    var paymentMethods: [String] = []
    var websiteURL: String = ""
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.fromAccount)
    var outgoingTransactions: [Transaction]?
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.toAccount)
    var incomingTransactions: [Transaction]?
    
    init(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        openingBalance: Decimal = 0,
        currentBalance: Decimal = 0,
        icon: String = "dollarsign.circle.fill",
        color: String = "blue",
        createdAt: Date = Date(),
        isPaymentMethod: Bool = true,
        isAsset: Bool = true,
        paymentMethods: [String] = [],
        websiteURL: String = ""
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.openingBalance = openingBalance
        self.currentBalance = currentBalance
        self.icon = icon
        self.color = color
        self.createdAt = createdAt
        self.isPaymentMethod = isPaymentMethod
        self.isAsset = isAsset
        self.paymentMethods = paymentMethods
        self.websiteURL = websiteURL
        self.outgoingTransactions = []
        self.incomingTransactions = []
    }

    var faviconURL: URL? {
        guard !websiteURL.isEmpty else { return nil }
        var domain = websiteURL
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
        if let slashIndex = domain.firstIndex(of: "/") {
            domain = String(domain[domain.startIndex..<slashIndex])
        }
        guard !domain.isEmpty else { return nil }
        return URL(string: "https://icons.duckduckgo.com/ip3/\(domain).ico")
    }
    
    var balance: Decimal {
        currentBalance
    }
    
    // For credit cards, this represents credit limit
    var creditLimit: Decimal {
        get { openingBalance }
        set { openingBalance = newValue }
    }
    
    // Available credit for credit cards
    var availableCredit: Decimal {
        type == .creditCard ? max(0, openingBalance - currentBalance) : 0
    }
}

enum AccountType: String, Codable, CaseIterable {
    case cash = "Cash"
    case bank = "Bank Account"
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    
    var icon: String {
        switch self {
        case .cash: return "banknote.fill"
        case .bank: return "building.columns.fill"
        case .creditCard: return "creditcard.fill"
        case .debitCard: return "creditcard.fill"
        }
    }
    
    var isAsset: Bool {
        switch self {
        case .cash, .bank, .debitCard: return true
        case .creditCard: return false
        }
    }
    
    // Available quick actions for this account type
    var availableActions: [AccountQuickAction] {
        switch self {
        case .cash:
            return [.addCash] // Only add cash, no withdraw
        case .bank, .debitCard:
            return [.deposit] // Only deposit, no withdraw
        case .creditCard:
            return [.payBill]
        }
    }
}

enum AccountQuickAction: String, CaseIterable {
    case addCash = "Add Cash"
    case deposit = "Deposit"
    case payBill = "Pay Bill"
    
    var icon: String {
        switch self {
        case .addCash: return "plus.circle.fill"
        case .deposit: return "arrow.down.circle.fill"
        case .payBill: return "creditcard.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .addCash, .deposit: return .green
        case .payBill: return .orange
        }
    }
}
