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
        accounts.filter { $0.type == .creditCard }.reduce(Decimal(0)) { $0 + $1.currentBalance }
    }

    var totalLending: Decimal {
        debts.filter { $0.type == .lending && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
    }

    var totalBorrowing: Decimal {
        debts.filter { $0.type == .borrowing && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
    }

    var activeRecurringCount: Int {
        recurringPayments.filter { $0.isActive && !$0.isCompleted }.count
    }

    var totalMonthlyRecurring: Decimal {
        recurringPayments
            .filter { $0.isActive && !$0.isCompleted && $0.frequency == .monthly }
            .reduce(Decimal(0)) { $0 + $1.installmentAmount }
    }

    var upcomingRecurringPayments: [RecurringPayment] {
        recurringPayments
            .filter { $0.isActive && !$0.isCompleted }
            .sorted { $0.nextPaymentDate < $1.nextPaymentDate }
    }

    func update(accounts: [Account], debts: [Debt], transactions: [Transaction], recurringPayments: [RecurringPayment] = []) {
        self.accounts = accounts
        self.debts = debts
        self.transactions = transactions
        self.recurringPayments = recurringPayments
    }
}
