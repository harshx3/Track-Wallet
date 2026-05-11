import XCTest
@testable import Track_Wallet

final class RecurringPaymentTests: XCTestCase {

    // MARK: - calculateFirstPaymentDate

    func testFirstPaymentDateDoesNotCrashWithCurrentDate() {
        let result = RecurringPayment.calculateFirstPaymentDate(
            startDate: Date(),
            dayOfMonth: 15,
            frequency: .monthly
        )
        XCTAssertNotNil(result)
    }

    func testFirstPaymentDateReturnsStartDayWhenInFuture() {
        let calendar = Calendar.current
        let future = calendar.date(from: DateComponents(year: 2027, month: 3, day: 1))!
        let result = RecurringPayment.calculateFirstPaymentDate(
            startDate: future,
            dayOfMonth: 20,
            frequency: .monthly
        )
        let day = calendar.component(.day, from: result)
        XCTAssertEqual(day, 20)
    }

    // MARK: - calculateNextDate: monthly

    func testNextDateMonthlyAdvancesOneMonth() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 5, day: 10))!
        let result = RecurringPayment.calculateNextDate(
            from: date, dayOfMonth: 10, frequency: .monthly
        )
        let comps = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 6)
        XCTAssertEqual(comps.day, 10)
    }

    func testNextDateMonthlyDecemberWrapsToJanuary() {
        let calendar = Calendar.current
        let dec = calendar.date(from: DateComponents(year: 2026, month: 12, day: 15))!
        let result = RecurringPayment.calculateNextDate(
            from: dec, dayOfMonth: 15, frequency: .monthly
        )
        let comps = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(comps.year, 2027)
        XCTAssertEqual(comps.month, 1)
        XCTAssertEqual(comps.day, 15)
    }

    func testNextDateMonthlyClampsDay31ToFebruary() {
        let calendar = Calendar.current
        let jan = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let result = RecurringPayment.calculateNextDate(
            from: jan, dayOfMonth: 31, frequency: .monthly
        )
        let comps = calendar.dateComponents([.month, .day], from: result)
        XCTAssertEqual(comps.month, 2)
        XCTAssertEqual(comps.day, 28)
    }

    // MARK: - calculateNextDate: quarterly

    func testNextDateQuarterlyAdvancesThreeMonths() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let result = RecurringPayment.calculateNextDate(
            from: date, dayOfMonth: 1, frequency: .quarterly
        )
        let comps = calendar.dateComponents([.year, .month], from: result)
        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 6)
    }

    func testNextDateQuarterlyOctoberWrapsToJanuary() {
        let calendar = Calendar.current
        let oct = calendar.date(from: DateComponents(year: 2026, month: 10, day: 15))!
        let result = RecurringPayment.calculateNextDate(
            from: oct, dayOfMonth: 15, frequency: .quarterly
        )
        let comps = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(comps.year, 2027)
        XCTAssertEqual(comps.month, 1)
        XCTAssertEqual(comps.day, 15)
    }

    // MARK: - calculateNextDate: weekly / biweekly / yearly

    func testNextDateWeeklyAddsSeven() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 5, day: 10))!
        let result = RecurringPayment.calculateNextDate(
            from: date, dayOfMonth: 10, frequency: .weekly
        )
        let diff = calendar.dateComponents([.day], from: date, to: result).day
        XCTAssertEqual(diff, 7)
    }

    func testNextDateBiweeklyAddsFourteen() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 5, day: 10))!
        let result = RecurringPayment.calculateNextDate(
            from: date, dayOfMonth: 10, frequency: .biweekly
        )
        let diff = calendar.dateComponents([.day], from: date, to: result).day
        XCTAssertEqual(diff, 14)
    }

    func testNextDateYearlyAddsOneYear() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 5, day: 10))!
        let result = RecurringPayment.calculateNextDate(
            from: date, dayOfMonth: 10, frequency: .yearly
        )
        let comps = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(comps.year, 2027)
        XCTAssertEqual(comps.month, 5)
        XCTAssertEqual(comps.day, 10)
    }
}
