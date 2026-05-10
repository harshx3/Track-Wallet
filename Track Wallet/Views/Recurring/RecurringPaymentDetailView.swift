//
//  RecurringPaymentDetailView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 5/2/26.
//

import SwiftUI
import SwiftData

struct RecurringPaymentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let payment: RecurringPayment

    @State private var showingDeleteAlert = false
    @State private var showingProcessAlert = false
    @State private var showingCancelAlert = false
    @State private var notificationDenied = false

    var body: some View {
        List {
            // Header
            Section {
                VStack(spacing: AppSpacing.md) {
                    if payment.isSubscription {
                        subscriptionHeader
                    } else {
                        installmentHeader
                    }

                    Text(payment.name)
                        .font(AppTypography.headlineLarge)
                        .multilineTextAlignment(.center)

                    if !payment.recurringDescription.isEmpty {
                        Text(payment.recurringDescription)
                            .font(AppTypography.callout)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    if payment.isSubscription {
                        subscriptionStats
                    } else {
                        installmentStats
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)

            // Plan Details
            Section {
                DetailRow(icon: "dollarsign.circle.fill", title: payment.isSubscription ? "Payment" : "Installment", value: "\(payment.installmentAmount.currencyFormatted)\(payment.frequency.shortLabel)", color: AppTheme.primary)

                if !payment.isSubscription {
                    DetailRow(icon: "number.circle.fill", title: "Progress", value: "\(payment.completedInstallments) of \(payment.totalInstallments)", color: AppTheme.transfer)
                } else {
                    DetailRow(icon: "number.circle.fill", title: "Payments Made", value: "\(payment.completedInstallments)", color: AppTheme.transfer)
                }

                DetailRow(icon: payment.frequency.icon, title: "Frequency", value: payment.frequency.rawValue, color: AppTheme.asset)

                if payment.frequency == .monthly || payment.frequency == .quarterly {
                    DetailRow(icon: "calendar.circle.fill", title: "Day of Month", value: ordinalDay(payment.dayOfMonth), color: .indigo)
                }

                DetailRow(icon: payment.resolvedPlanType.icon, title: "Type", value: payment.resolvedPlanType.label, color: AppTheme.recurring)

                if payment.isSubscription && payment.frequency != .yearly {
                    DetailRow(icon: "calendar.badge.clock", title: "Yearly Cost", value: payment.yearlyCost.currencyFormatted, color: AppTheme.expense)
                }
            } header: {
                Label("Plan Details", systemImage: "doc.text.fill")
            }

            // Split Members
            if payment.isSplit {
                Section {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.income))
                        Text("You")
                            .font(AppTypography.body)
                        Spacer()
                        Text(payment.perPersonAmount.currencyFormatted)
                            .font(AppTypography.bodyEmphasized)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    ForEach(payment.splitMembers, id: \.self) { member in
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.recurring))
                            Text(member)
                                .font(AppTypography.body)
                            Spacer()
                            Text(payment.perPersonAmount.currencyFormatted)
                                .font(AppTypography.bodyEmphasized)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

                    HStack {
                        Text("Total")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(payment.splitCount) people")
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(payment.installmentAmount.currencyFormatted)
                            .font(AppTypography.bodyEmphasized)
                    }
                } header: {
                    Label("Split (\(payment.splitCount) people)", systemImage: "person.2.fill")
                }
            }

            // Account & Category
            Section {
                if let account = payment.account {
                    HStack(spacing: AppSpacing.sm) {
                        AccountIconView(account: account, size: 32, cornerRadius: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name)
                                .font(AppTypography.body)
                            Text(account.type.rawValue)
                                .font(AppTypography.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Text(account.currentBalance.currencyFormatted)
                            .font(AppTypography.bodyEmphasized)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                if let category = payment.category {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: category.icon)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(category.color.toColor))
                        Text(category.name)
                            .font(AppTypography.body)
                    }
                }
            } header: {
                Label("Account & Category", systemImage: "creditcard.fill")
            }

            // Schedule
            Section {
                DetailRow(icon: "play.circle.fill", title: "Started", value: payment.startDate.formatted(date: .abbreviated, time: .omitted), color: AppTheme.income)

                if payment.isSubscription, let endDate = payment.endDate {
                    DetailRow(icon: "stop.circle.fill", title: "Ends", value: endDate.formatted(date: .abbreviated, time: .omitted), color: AppTheme.expense)
                }

                if payment.isActive && !payment.isCompleted {
                    DetailRow(
                        icon: "clock.fill",
                        title: "Next Payment",
                        value: payment.nextPaymentDate.formatted(date: .abbreviated, time: .omitted),
                        color: payment.isOverdue ? AppTheme.expense : AppTheme.primary
                    )
                }

                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: statusIcon)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(RoundedRectangle(cornerRadius: 8).fill(statusColor))
                    Text("Status")
                        .font(AppTypography.body)
                    Spacer()
                    Text(statusText)
                        .font(AppTypography.bodyEmphasized)
                        .foregroundColor(statusColor)
                }

                if payment.isActive && !payment.isCompleted {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.transfer))
                        Text("Reminder")
                            .font(AppTypography.body)
                        Spacer()
                        Menu {
                            Button("None") { setReminder(-1) }
                            Button("Same Day") { setReminder(0) }
                            Button("1 Day Before") { setReminder(1) }
                            Button("3 Days Before") { setReminder(3) }
                            Button("7 Days Before") { setReminder(7) }
                        } label: {
                            Text(reminderLabel)
                                .font(AppTypography.bodyEmphasized)
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                }
            } header: {
                Label("Schedule", systemImage: "calendar")
            }

            // Actions
            if payment.isActive && !payment.isCompleted {
                Section {
                    Button {
                        showingProcessAlert = true
                    } label: {
                        Label("Process Payment Now", systemImage: "bolt.circle.fill")
                            .font(AppTypography.bodyEmphasized)
                            .foregroundColor(AppTheme.primary)
                    }

                    if payment.isSubscription {
                        Button {
                            showingCancelAlert = true
                        } label: {
                            Label("Cancel Subscription", systemImage: "xmark.circle.fill")
                                .foregroundColor(AppTheme.expense)
                        }
                    } else {
                        Button {
                            payment.isActive = false
                        } label: {
                            Label("Pause Plan", systemImage: "pause.circle.fill")
                                .foregroundColor(AppTheme.transfer)
                        }
                    }
                } header: {
                    Label("Actions", systemImage: "hand.tap.fill")
                }
            } else if !payment.isActive && !payment.isCompleted {
                Section {
                    Button {
                        payment.isActive = true
                    } label: {
                        Label("Resume Plan", systemImage: "play.circle.fill")
                            .foregroundColor(AppTheme.income)
                    }
                }
            }

            // Delete
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Delete Plan", systemImage: "trash")
                            .font(AppTypography.bodyEmphasized)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Plan Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Process Payment", isPresented: $showingProcessAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Process") {
                processPayment()
            }
        } message: {
            Text("Deduct \(payment.installmentAmount.currencyFormatted) from \(payment.account?.name ?? "account")? This will create a transaction and update the balance.")
        }
        .alert("Cancel Subscription", isPresented: $showingCancelAlert) {
            Button("Keep Active", role: .cancel) { }
            Button("Cancel Subscription", role: .destructive) {
                payment.isActive = false
            }
        } message: {
            Text("This will stop future payments for \(payment.name). You can resume it later if needed.")
        }
        .alert("Notifications Disabled", isPresented: $notificationDenied) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Enable notifications in Settings to receive payment reminders.")
        }
        .alert("Delete Plan", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(payment)
                dismiss()
            }
        } message: {
            Text("This will permanently delete this recurring plan. Past transactions will not be affected.")
        }
    }

    // MARK: - Subscription Header

    @ViewBuilder
    private var subscriptionHeader: some View {
        ZStack {
            Circle()
                .fill(progressColor.opacity(0.12))
                .frame(width: 100, height: 100)

            Image(systemName: payment.isActive ? "infinity" : "pause.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(progressColor)
        }
        .padding(.top, AppSpacing.sm)
    }

    // MARK: - Installment Header

    @ViewBuilder
    private var installmentHeader: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.border, lineWidth: 8)
                .frame(width: 100, height: 100)
            Circle()
                .trim(from: 0, to: CGFloat(payment.progress))
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(payment.progress * 100))%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(progressColor)
                Text("paid")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.top, AppSpacing.sm)
    }

    // MARK: - Stats

    @ViewBuilder
    private var subscriptionStats: some View {
        HStack(spacing: AppSpacing.lg) {
            StatBadge(
                title: "Total Paid",
                value: payment.paidAmount.currencyFormatted,
                color: AppTheme.primary
            )
            StatBadge(
                title: "Payments",
                value: "\(payment.completedInstallments)",
                color: AppTheme.transfer
            )
            StatBadge(
                title: "Per Cycle",
                value: payment.installmentAmount.currencyFormatted,
                color: AppTheme.recurring
            )
        }
        .padding(.bottom, AppSpacing.xs)
    }

    @ViewBuilder
    private var installmentStats: some View {
        HStack(spacing: AppSpacing.lg) {
            StatBadge(
                title: "Paid",
                value: payment.paidAmount.currencyFormatted,
                color: AppTheme.income
            )
            StatBadge(
                title: "Remaining",
                value: payment.remainingAmount.currencyFormatted,
                color: AppTheme.expense
            )
            StatBadge(
                title: "Total",
                value: payment.totalAmount.currencyFormatted,
                color: AppTheme.primary
            )
        }
        .padding(.bottom, AppSpacing.xs)
    }

    // MARK: - Computed

    private var progressColor: Color {
        if payment.isCompleted { return AppTheme.income }
        if payment.isOverdue { return AppTheme.expense }
        if payment.isSubscription { return AppTheme.recurring }
        return AppTheme.primary
    }

    private var statusText: String {
        if payment.isCompleted {
            return payment.isSubscription ? "Cancelled" : "Completed"
        }
        if !payment.isActive { return "Paused" }
        if payment.isOverdue { return "Overdue" }
        return "Active"
    }

    private var statusColor: Color {
        if payment.isCompleted { return AppTheme.income }
        if !payment.isActive { return AppTheme.transfer }
        if payment.isOverdue { return AppTheme.expense }
        return AppTheme.primary
    }

    private var statusIcon: String {
        if payment.isCompleted { return "checkmark.circle.fill" }
        if !payment.isActive { return "pause.circle.fill" }
        if payment.isOverdue { return "exclamationmark.circle.fill" }
        return "bolt.circle.fill"
    }

    private func ordinalDay(_ day: Int) -> String {
        let suffixes = ["th", "st", "nd", "rd"]
        let idx = (day % 100 >= 11 && day % 100 <= 13) ? 0 : min(day % 10, 3)
        return "\(day)\(suffixes[idx])"
    }

    private var reminderLabel: String {
        switch payment.reminderDays {
        case 0: return "Same Day"
        case 1: return "1 Day Before"
        case 3: return "3 Days Before"
        case 7: return "7 Days Before"
        default: return "None"
        }
    }

    private func setReminder(_ days: Int) {
        if days >= 0 {
            NotificationManager.shared.requestPermission { granted in
                if granted {
                    payment.reminderDays = days
                    NotificationManager.shared.schedulePaymentReminder(for: payment)
                    HapticManager.notification(.success)
                } else {
                    notificationDenied = true
                }
            }
        } else {
            payment.reminderDays = -1
            NotificationManager.shared.removeReminder(for: payment)
        }
    }

    private func processPayment() {
        guard let account = payment.account else { return }
        guard payment.isActive, !payment.isCompleted else { return }

        let description: String
        if payment.isSubscription {
            description = "\(payment.name) — payment #\(payment.completedInstallments + 1)"
        } else {
            description = "Recurring: \(payment.name) (\(payment.completedInstallments + 1)/\(payment.totalInstallments))"
        }

        let transaction = Transaction(
            amount: payment.installmentAmount,
            type: .expense,
            transactionDescription: description,
            date: Date(),
            fromAccount: account,
            category: payment.category
        )

        if account.type == .creditCard {
            account.currentBalance += payment.installmentAmount
        } else {
            account.currentBalance -= payment.installmentAmount
        }

        modelContext.insert(transaction)
        payment.advanceToNextPayment()

        if payment.reminderDays >= 0 {
            NotificationManager.shared.schedulePaymentReminder(for: payment)
        }

        HapticManager.notification(.success)
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xs)
                .fill(color.opacity(0.1))
        )
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(color))

            Text(title)
                .font(AppTypography.body)

            Spacer()

            Text(value)
                .font(AppTypography.bodyEmphasized)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RecurringPayment.self, Account.self, Transaction.self, Category.self, configurations: config)

    let account = Account(name: "Chase Card", type: .creditCard, openingBalance: 5000, currentBalance: 1200, isAsset: false)
    container.mainContext.insert(account)

    let payment = RecurringPayment(
        name: "MacBook Pro EMI",
        planType: .installment,
        totalAmount: 2000,
        installmentAmount: 100,
        dayOfMonth: 15,
        totalInstallments: 20,
        recurringDescription: "Monthly installment for MacBook Pro",
        account: account
    )
    container.mainContext.insert(payment)

    return NavigationStack {
        RecurringPaymentDetailView(payment: payment)
    }
    .modelContainer(container)
}
