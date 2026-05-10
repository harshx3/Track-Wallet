//
//  NotificationManager.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 5/9/26.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func checkPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    func schedulePaymentReminder(for payment: RecurringPayment) {
        guard payment.reminderDays >= 0, payment.isActive, !payment.isCompleted else {
            removeReminder(for: payment)
            return
        }

        let identifier = "recurring_\(payment.id.uuidString)"
        removeReminder(identifier: identifier)

        let calendar = Calendar.current
        guard let reminderDate = calendar.date(byAdding: .day, value: -payment.reminderDays, to: payment.nextPaymentDate) else { return }

        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Payment Reminder"

        if payment.reminderDays == 0 {
            content.body = "\(payment.name) — \(payment.installmentAmount.currencyFormatted) is due today."
        } else {
            content.body = "\(payment.name) — \(payment.installmentAmount.currencyFormatted) is due in \(payment.reminderDays) day\(payment.reminderDays == 1 ? "" : "s")."
        }

        content.sound = .default
        content.categoryIdentifier = "PAYMENT_REMINDER"

        var components = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func removeReminder(for payment: RecurringPayment) {
        removeReminder(identifier: "recurring_\(payment.id.uuidString)")
    }

    func removeReminder(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func rescheduleAllReminders(payments: [RecurringPayment]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for payment in payments where payment.reminderDays >= 0 && payment.isActive && !payment.isCompleted {
            schedulePaymentReminder(for: payment)
        }
    }

    // MARK: - Credit Card Due Date

    func scheduleDueDateReminder(for account: Account) {
        guard account.type == .creditCard, let dueDate = account.nextDueDate else {
            removeDueDateReminder(for: account)
            return
        }

        let identifier = "creditcard_due_\(account.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        let calendar = Calendar.current
        guard let reminderDate = calendar.date(byAdding: .day, value: -1, to: dueDate),
              reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Bill Due Tomorrow"
        content.body = "\(account.name) payment is due tomorrow. Current balance: \(account.currentBalance.currencyFormatted)."
        content.sound = .default
        content.categoryIdentifier = "BILL_REMINDER"

        var components = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func removeDueDateReminder(for account: Account) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["creditcard_due_\(account.id.uuidString)"]
        )
    }
}
