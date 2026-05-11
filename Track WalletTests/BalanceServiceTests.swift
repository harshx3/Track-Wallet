import XCTest
import SwiftData
@testable import Track_Wallet

final class BalanceServiceTests: XCTestCase {

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

    // MARK: - Income

    func testIncomeApplyAddsToBalance() {
        let account = Account(name: "Bank", type: .bank, currentBalance: 1000)
        context.insert(account)
        let txn = Transaction(amount: 500, type: .income, fromAccount: account)
        context.insert(txn)

        BalanceService.applyBalanceChange(for: txn)
        XCTAssertEqual(account.currentBalance, 1500)
    }

    func testIncomeReverseSubtractsFromBalance() {
        let account = Account(name: "Bank", type: .bank, currentBalance: 1500)
        context.insert(account)
        let txn = Transaction(amount: 500, type: .income, fromAccount: account)
        context.insert(txn)

        BalanceService.reverseBalanceChange(for: txn)
        XCTAssertEqual(account.currentBalance, 1000)
    }

    func testIncomeRoundTrip() {
        let account = Account(name: "Bank", type: .bank, currentBalance: 1000)
        context.insert(account)
        let txn = Transaction(amount: 500, type: .income, fromAccount: account)
        context.insert(txn)

        BalanceService.applyBalanceChange(for: txn)
        BalanceService.reverseBalanceChange(for: txn)
        XCTAssertEqual(account.currentBalance, 1000)
    }

    // MARK: - Expense (non-credit-card)

    func testExpenseBankRoundTrip() {
        let account = Account(name: "Bank", type: .bank, currentBalance: 1000)
        context.insert(account)
        let txn = Transaction(amount: 300, type: .expense, fromAccount: account)
        context.insert(txn)

        BalanceService.applyBalanceChange(for: txn)
        XCTAssertEqual(account.currentBalance, 700)

        BalanceService.reverseBalanceChange(for: txn)
        XCTAssertEqual(account.currentBalance, 1000)
    }

    // MARK: - Expense (credit card)

    func testExpenseCreditCardRoundTrip() {
        let card = Account(name: "CC", type: .creditCard, openingBalance: 5000, currentBalance: 200, isAsset: false)
        context.insert(card)
        let txn = Transaction(amount: 100, type: .expense, fromAccount: card)
        context.insert(txn)

        BalanceService.applyBalanceChange(for: txn)
        XCTAssertEqual(card.currentBalance, 300)

        BalanceService.reverseBalanceChange(for: txn)
        XCTAssertEqual(card.currentBalance, 200)
    }

    // MARK: - Transfer

    func testTransferBetweenAssetAccountsRoundTrip() {
        let from = Account(name: "Checking", type: .bank, currentBalance: 1000, isAsset: true)
        let to = Account(name: "Savings", type: .bank, currentBalance: 500, isAsset: true)
        context.insert(from)
        context.insert(to)
        let txn = Transaction(amount: 200, type: .transfer, fromAccount: from, toAccount: to)
        context.insert(txn)

        BalanceService.applyBalanceChange(for: txn)
        XCTAssertEqual(from.currentBalance, 800)
        XCTAssertEqual(to.currentBalance, 700)

        BalanceService.reverseBalanceChange(for: txn)
        XCTAssertEqual(from.currentBalance, 1000)
        XCTAssertEqual(to.currentBalance, 500)
    }

    func testTransferToCreditCardRoundTrip() {
        let from = Account(name: "Bank", type: .bank, currentBalance: 1000, isAsset: true)
        let to = Account(name: "CC", type: .creditCard, openingBalance: 5000, currentBalance: 500, isAsset: false)
        context.insert(from)
        context.insert(to)
        let txn = Transaction(amount: 500, type: .transfer, fromAccount: from, toAccount: to)
        context.insert(txn)

        BalanceService.applyBalanceChange(for: txn)
        XCTAssertEqual(from.currentBalance, 500)
        XCTAssertEqual(to.currentBalance, 0)

        BalanceService.reverseBalanceChange(for: txn)
        XCTAssertEqual(from.currentBalance, 1000)
        XCTAssertEqual(to.currentBalance, 500)
    }

    // MARK: - Reimbursed

    func testReimbursedRoundTrip() {
        let account = Account(name: "Bank", type: .bank, currentBalance: 800)
        context.insert(account)
        let txn = Transaction(amount: 150, type: .reimbursed, fromAccount: account)
        context.insert(txn)

        BalanceService.applyBalanceChange(for: txn)
        XCTAssertEqual(account.currentBalance, 950)

        BalanceService.reverseBalanceChange(for: txn)
        XCTAssertEqual(account.currentBalance, 800)
    }

    // MARK: - Nil account safety

    func testApplyWithNilAccountDoesNotCrash() {
        let txn = Transaction(amount: 100, type: .income)
        context.insert(txn)
        BalanceService.applyBalanceChange(for: txn)
    }

    func testReverseWithNilAccountDoesNotCrash() {
        let txn = Transaction(amount: 100, type: .expense)
        context.insert(txn)
        BalanceService.reverseBalanceChange(for: txn)
    }
}
