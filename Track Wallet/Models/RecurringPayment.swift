//
//  RecurringPayment.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 5/2/26.
//

import Foundation
import SwiftData

@Model
final class RecurringPayment {
    var id: UUID = UUID()
    var name: String = ""
    var planType: RecurringPlanType?
    var totalAmount: Decimal = 0
    var installmentAmount: Decimal = 0
    var frequency: PaymentFrequency = PaymentFrequency.monthly
    var dayOfMonth: Int = 1
    var startDate: Date = Date()
    var endDate: Date?
    var totalInstallments: Int = 0
    var completedInstallments: Int = 0
    var paidAmount: Decimal = 0
    var isActive: Bool = true
    var nextPaymentDate: Date = Date()
    var recurringDescription: String = ""
    var createdAt: Date = Date()
    var splitMembers: [String] = []

    var account: Account?
    var category: Category?

    init(
        id: UUID = UUID(),
        name: String,
        planType: RecurringPlanType = .installment,
        totalAmount: Decimal = 0,
        installmentAmount: Decimal,
        frequency: PaymentFrequency = .monthly,
        dayOfMonth: Int = 1,
        startDate: Date = Date(),
        endDate: Date? = nil,
        totalInstallments: Int = 0,
        recurringDescription: String = "",
        account: Account? = nil,
        category: Category? = nil,
        splitMembers: [String] = []
    ) {
        self.id = id
        self.name = name
        self.planType = planType
        self.totalAmount = totalAmount
        self.installmentAmount = installmentAmount
        self.frequency = frequency
        self.dayOfMonth = dayOfMonth
        self.startDate = startDate
        self.endDate = endDate
        self.totalInstallments = totalInstallments
        self.completedInstallments = 0
        self.paidAmount = 0
        self.isActive = true
        self.recurringDescription = recurringDescription
        self.createdAt = Date()
        self.account = account
        self.category = category
        self.splitMembers = splitMembers
        self.nextPaymentDate = RecurringPayment.calculateFirstPaymentDate(
            startDate: startDate,
            dayOfMonth: dayOfMonth,
            frequency: frequency
        )
    }

    var resolvedPlanType: RecurringPlanType {
        planType ?? .installment
    }

    var isSubscription: Bool {
        resolvedPlanType == .subscription
    }

    var isSplit: Bool {
        !splitMembers.isEmpty
    }

    var splitCount: Int {
        splitMembers.count + 1
    }

    var perPersonAmount: Decimal {
        guard splitCount > 1 else { return installmentAmount }
        return installmentAmount / Decimal(splitCount)
    }

    var remainingAmount: Decimal {
        if isSubscription { return 0 }
        return max(0, totalAmount - paidAmount)
    }

    var remainingInstallments: Int {
        if isSubscription { return 0 }
        return max(0, totalInstallments - completedInstallments)
    }

    var progress: Double {
        let value: Double
        if isSubscription {
            guard let endDate else { return 0 }
            let totalDuration = endDate.timeIntervalSince(startDate)
            guard totalDuration > 0 else { return 1.0 }
            let elapsed = Date().timeIntervalSince(startDate)
            value = elapsed / totalDuration
        } else {
            guard totalAmount > 0 else { return 0 }
            value = Double(truncating: (paidAmount / totalAmount) as NSDecimalNumber)
        }
        guard value.isFinite else { return 0 }
        return min(1.0, max(0, value))
    }

    var isCompleted: Bool {
        if isSubscription {
            if let endDate {
                return Date() >= endDate || (!isActive && completedInstallments > 0)
            }
            return !isActive && completedInstallments > 0
        }
        return completedInstallments >= totalInstallments || paidAmount >= totalAmount
    }

    var isDueToday: Bool {
        guard isActive, !isCompleted else { return false }
        return Calendar.current.isDateInToday(nextPaymentDate) || nextPaymentDate < Date()
    }

    var isOverdue: Bool {
        guard isActive, !isCompleted else { return false }
        return nextPaymentDate < Calendar.current.startOfDay(for: Date())
    }

    func advanceToNextPayment() {
        completedInstallments += 1
        paidAmount += installmentAmount

        if isCompleted {
            if !isSubscription {
                isActive = false
            }
            return
        }

        nextPaymentDate = RecurringPayment.calculateNextDate(
            from: nextPaymentDate,
            dayOfMonth: dayOfMonth,
            frequency: frequency
        )

        if isSubscription, let endDate, nextPaymentDate > endDate {
            isActive = false
        }
    }

    static func calculateFirstPaymentDate(
        startDate: Date,
        dayOfMonth: Int,
        frequency: PaymentFrequency
    ) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: startDate)
        let clampedDay = min(dayOfMonth, daysInMonth(year: components.year!, month: components.month!))
        components.day = clampedDay

        guard let candidate = calendar.date(from: components) else { return startDate }

        if candidate >= calendar.startOfDay(for: startDate) {
            return candidate
        }

        return calculateNextDate(from: candidate, dayOfMonth: dayOfMonth, frequency: frequency)
    }

    static func calculateNextDate(
        from currentDate: Date,
        dayOfMonth: Int,
        frequency: PaymentFrequency
    ) -> Date {
        let calendar = Calendar.current

        let next: Date?
        switch frequency {
        case .weekly:
            next = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)
        case .biweekly:
            next = calendar.date(byAdding: .weekOfYear, value: 2, to: currentDate)
        case .monthly:
            var comps = calendar.dateComponents([.year, .month], from: currentDate)
            comps.month! += 1
            if comps.month! > 12 {
                comps.month = 1
                comps.year! += 1
            }
            let maxDay = daysInMonth(year: comps.year!, month: comps.month!)
            comps.day = min(dayOfMonth, maxDay)
            next = calendar.date(from: comps)
        case .quarterly:
            var comps = calendar.dateComponents([.year, .month], from: currentDate)
            comps.month! += 3
            while comps.month! > 12 {
                comps.month! -= 12
                comps.year! += 1
            }
            let maxDay = daysInMonth(year: comps.year!, month: comps.month!)
            comps.day = min(dayOfMonth, maxDay)
            next = calendar.date(from: comps)
        case .yearly:
            next = calendar.date(byAdding: .year, value: 1, to: currentDate)
        }

        return next ?? currentDate
    }

    private static func daysInMonth(year: Int, month: Int) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        let calendar = Calendar.current
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 28
        }
        return range.count
    }
}

enum RecurringPlanType: String, Codable, CaseIterable {
    case installment = "Installment"
    case subscription = "Subscription"

    var icon: String {
        switch self {
        case .installment: return "chart.bar.fill"
        case .subscription: return "infinity"
        }
    }

    var label: String {
        switch self {
        case .installment: return "Fixed Plan"
        case .subscription: return "Subscription"
        }
    }
}

enum PaymentFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"

    var icon: String {
        switch self {
        case .weekly: return "calendar.badge.clock"
        case .biweekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .quarterly: return "calendar.badge.plus"
        case .yearly: return "calendar.circle"
        }
    }

    var shortLabel: String {
        switch self {
        case .weekly: return "/wk"
        case .biweekly: return "/2wk"
        case .monthly: return "/mo"
        case .quarterly: return "/qtr"
        case .yearly: return "/yr"
        }
    }
}
