import XCTest
import SwiftData
@testable import Track_Wallet

final class CreditUtilizationTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() {
        super.setUp()
        let schema = Schema([
            Account.self, Transaction.self, Category.self,
            Debt.self, RecurringPayment.self, TransactionTemplate.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDown() {
        context = nil
        container = nil
        super.tearDown()
    }

    // MARK: - totalCreditDue

    func testTotalCreditDueIgnoresNegativeBalances() {
        let card = Account(name: "Overpaid", type: .creditCard, openingBalance: 1000, currentBalance: -200, isAsset: false)
        context.insert(card)

        let calc = FinanceCalculator()
        calc.update(accounts: [card], debts: [], transactions: [])

        XCTAssertEqual(calc.totalCreditDue, 0)
    }

    func testTotalCreditDueCountsPositiveBalanceOnly() {
        let card1 = Account(name: "A", type: .creditCard, openingBalance: 1000, currentBalance: 500, isAsset: false)
        let card2 = Account(name: "B", type: .creditCard, openingBalance: 2000, currentBalance: -100, isAsset: false)
        context.insert(card1)
        context.insert(card2)

        let calc = FinanceCalculator()
        calc.update(accounts: [card1, card2], debts: [], transactions: [])

        XCTAssertEqual(calc.totalCreditDue, 500)
    }

    // MARK: - creditUtilization

    func testCreditUtilizationZeroLimit() {
        let card = Account(name: "No Limit", type: .creditCard, openingBalance: 0, currentBalance: 100, isAsset: false)
        context.insert(card)

        let calc = FinanceCalculator()
        calc.update(accounts: [card], debts: [], transactions: [])

        XCTAssertEqual(calc.creditUtilization, 0)
    }

    func testCreditUtilizationNormalUsage() {
        let card = Account(name: "Card", type: .creditCard, openingBalance: 1000, currentBalance: 250, isAsset: false)
        context.insert(card)

        let calc = FinanceCalculator()
        calc.update(accounts: [card], debts: [], transactions: [])

        XCTAssertEqual(calc.creditUtilization, 0.25, accuracy: 0.001)
    }

    func testCreditUtilizationNegativeBalanceIsZero() {
        let card = Account(name: "Overpaid", type: .creditCard, openingBalance: 5000, currentBalance: -500, isAsset: false)
        context.insert(card)

        let calc = FinanceCalculator()
        calc.update(accounts: [card], debts: [], transactions: [])

        XCTAssertEqual(calc.creditUtilization, 0)
    }

    func testCreditUtilizationPaidOff() {
        let card = Account(name: "Paid", type: .creditCard, openingBalance: 3000, currentBalance: 0, isAsset: false)
        context.insert(card)

        let calc = FinanceCalculator()
        calc.update(accounts: [card], debts: [], transactions: [])

        XCTAssertEqual(calc.totalCreditDue, 0)
        XCTAssertEqual(calc.creditUtilization, 0)
    }

    // MARK: - nil category safety

    func testTopSpendingCategoryWithNilCategory() {
        let account = Account(name: "Bank", type: .bank)
        context.insert(account)

        let txn = Transaction(amount: 50, type: .expense, fromAccount: account)
        context.insert(txn)

        let calc = FinanceCalculator()
        calc.update(accounts: [account], debts: [], transactions: [txn])

        // Should not crash — category is nil
        let _ = calc.topSpendingCategory
        let _ = calc.categoryBreakdown
    }

    func testCategoryBreakdownWithMixedNilCategories() {
        let account = Account(name: "Bank", type: .bank)
        let cat = Category(name: "Food", icon: "fork.knife", color: "red", type: .expense)
        context.insert(account)
        context.insert(cat)

        let txn1 = Transaction(amount: 30, type: .expense, fromAccount: account, category: cat)
        let txn2 = Transaction(amount: 20, type: .expense, fromAccount: account)
        context.insert(txn1)
        context.insert(txn2)

        let calc = FinanceCalculator()
        calc.update(accounts: [account], debts: [], transactions: [txn1, txn2])

        let breakdown = calc.categoryBreakdown
        XCTAssertEqual(breakdown.count, 1)
        XCTAssertEqual(breakdown.first?.name, "Food")
    }
}
