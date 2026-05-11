import Foundation

enum BalanceService {
    static func applyBalanceChange(for transaction: Transaction) {
        guard let account = transaction.fromAccount else { return }
        let amount = transaction.amount

        switch transaction.type {
        case .income:
            account.currentBalance += amount
        case .expense:
            if account.type == .creditCard {
                account.currentBalance += amount
            } else {
                account.currentBalance -= amount
            }
        case .transfer:
            account.currentBalance -= amount
            if let toAccount = transaction.toAccount {
                if toAccount.isAsset {
                    toAccount.currentBalance += amount
                } else {
                    toAccount.currentBalance -= amount
                }
            }
        case .reimbursed:
            account.currentBalance += amount
        }
    }

    static func reverseBalanceChange(for transaction: Transaction) {
        guard let account = transaction.fromAccount else { return }
        let amount = transaction.amount

        switch transaction.type {
        case .income:
            account.currentBalance -= amount
        case .expense:
            if account.type == .creditCard {
                account.currentBalance -= amount
            } else {
                account.currentBalance += amount
            }
        case .transfer:
            account.currentBalance += amount
            if let toAccount = transaction.toAccount {
                if toAccount.isAsset {
                    toAccount.currentBalance -= amount
                } else {
                    toAccount.currentBalance += amount
                }
            }
        case .reimbursed:
            account.currentBalance -= amount
        }
    }
}
