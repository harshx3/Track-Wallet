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
    
    // Total Assets (Bank Accounts + Cash)
    var totalAssets: Decimal {
        accounts.filter { $0.isAsset }.reduce(Decimal(0)) { $0 + $1.currentBalance }
    }
    
    // Total Liabilities (Credit Cards)
    var totalLiabilities: Decimal {
        accounts.filter { !$0.isAsset }.reduce(Decimal(0)) { $0 + $1.currentBalance }
    }
    
    // Total Net Worth = Assets - Liabilities
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
        accounts.filter { $0.type == .creditCard }.reduce(Decimal(0)) { $0 + $1.currentBalance }
    }
    
    var totalLending: Decimal {
        debts.filter { $0.type == .lending && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
    }
    
    var totalBorrowing: Decimal {
        debts.filter { $0.type == .borrowing && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
    }
    
    func update(accounts: [Account], debts: [Debt], transactions: [Transaction]) {
        self.accounts = accounts
        self.debts = debts
        self.transactions = transactions
    }
}
