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

    var body: some View {
        List {
            Section {
                VStack(spacing: AppSpacing.md) {
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

                    Text(payment.name)
                        .font(AppTypography.headlineLarge)
                        .multilineTextAlignment(.center)

                    if !payment.recurringDescription.isEmpty {
                        Text(payment.recurringDescription)
                            .font(AppTypography.callout)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

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
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)

            Section {
                DetailRow(icon: "dollarsign.circle.fill", title: "Installment", value: "\(payment.installmentAmount.currencyFormatted)\(payment.frequency.shortLabel)", color: AppTheme.primary)
                DetailRow(icon: "number.circle.fill", title: "Progress", value: "\(payment.completedInstallments) of \(payment.totalInstallments)", color: AppTheme.transfer)
                DetailRow(icon: payment.frequency.icon, title: "Frequency", value: payment.frequency.rawValue, color: AppTheme.asset)

                if payment.frequency == .monthly || payment.frequency == .quarterly {
                    DetailRow(icon: "calendar.circle.fill", title: "Day of Month", value: ordinalDay(payment.dayOfMonth), color: .indigo)
                }
            } header: {
                Label("Plan Details", systemImage: "doc.text.fill")
            }

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

            Section {
                DetailRow(icon: "play.circle.fill", title: "Started", value: payment.startDate.formatted(date: .abbreviated, time: .omitted), color: AppTheme.income)

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
            } header: {
                Label("Schedule", systemImage: "calendar")
            }

            if payment.isActive && !payment.isCompleted {
                Section {
                    Button {
                        showingProcessAlert = true
                    } label: {
                        Label("Process Payment Now", systemImage: "bolt.circle.fill")
                            .font(AppTypography.bodyEmphasized)
                            .foregroundColor(AppTheme.primary)
                    }

                    Button {
                        payment.isActive = false
                    } label: {
                        Label("Pause Plan", systemImage: "pause.circle.fill")
                            .foregroundColor(AppTheme.transfer)
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

    private var progressColor: Color {
        if payment.isCompleted { return AppTheme.income }
        if payment.isOverdue { return AppTheme.expense }
        return AppTheme.primary
    }

    private var statusText: String {
        if payment.isCompleted { return "Completed" }
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

    private func processPayment() {
        guard let account = payment.account else { return }
        guard payment.isActive, !payment.isCompleted else { return }

        let transaction = Transaction(
            amount: payment.installmentAmount,
            type: .expense,
            transactionDescription: "Recurring: \(payment.name) (\(payment.completedInstallments + 1)/\(payment.totalInstallments))",
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
