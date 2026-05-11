import XCTest
@testable import Track_Wallet

final class CurrencyFormatterTests: XCTestCase {

    func testFormatterUsesCurrentLocale() {
        XCTAssertEqual(sharedCurrencyFormatter.locale, Locale.current)
    }

    func testFormatterHasTwoFractionDigits() {
        XCTAssertEqual(sharedCurrencyFormatter.maximumFractionDigits, 2)
    }

    func testDecimalZeroFormatsNonEmpty() {
        let result = Decimal(0).currencyFormatted
        XCTAssertFalse(result.isEmpty)
    }

    func testDecimalPositiveContainsDigits() {
        let result = Decimal(string: "42.50")!.currencyFormatted
        XCTAssertTrue(result.contains("42"))
    }

    func testDecimalNegativeContainsDigits() {
        let result = Decimal(-100).currencyFormatted
        XCTAssertTrue(result.contains("100"))
    }

    func testDecimalLargeValueFormatsNonEmpty() {
        let result = Decimal(1_000_000).currencyFormatted
        XCTAssertFalse(result.isEmpty)
    }

    func testDoubleFormatsNonEmpty() {
        let result = Double(99.99).currencyFormatted
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("99"))
    }
}
