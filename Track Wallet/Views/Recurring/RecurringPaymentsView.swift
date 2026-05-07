//
//  RecurringPaymentsView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 5/2/26.
//

import SwiftUI
import SwiftData

struct RecurringPaymentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringPayment.nextPaymentDate) private var payments: [RecurringPayment]

    @State private var showingAddPayment = false
    @State private var filterType: RecurringFilterType = .active

    var filteredPayments: [RecurringPayment] {
        switch filterType {
        case .active: return payments.filter { $0.isActive && !$0.isCompleted }
        case .upcoming: return payments.filter { $0.isActive && !$0.isCompleted }.sorted { $0.nextPaymentDate < $1.nextPaymentDate }
        case .completed: return payments.filter { $0.isCompleted || !$0.isActive }
        case .all: return payments
        }
    }

    var totalMonthlyCommitment: Decimal {
        payments.filter { $0.isActive && !$0.isCompleted && $0.frequency == .monthly }
            .reduce(Decimal(0)) { $0 + $1.installmentAmount }
    }

    var totalRemainingAmount: Decimal {
        payments.filter { $0.isActive && !$0.isCompleted && !$0.isSubscription }
            .reduce(Decimal(0)) { $0 + $1.remainingAmount }
    }

    var activeSubscriptionCount: Int {
        payments.filter { $0.isActive && !$0.isCompleted && $0.isSubscription }.count
    }

    var overduePayments: [RecurringPayment] {
        payments.filter { $0.isOverdue }
    }

    var body: some View {
        NavigationStack {
            List {
                // Summary
                if !payments.filter({ $0.isActive }).isEmpty {
                    Section {
                        VStack(spacing: AppSpacing.md) {
                            HStack(spacing: AppSpacing.md) {
                                SummaryCard(
                                    title: "Monthly",
                                    value: totalMonthlyCommitment.currencyFormatted,
                                    icon: "calendar",
                                    color: AppTheme.recurring
                                )

                                SummaryCard(
                                    title: "Remaining",
                                    value: totalRemainingAmount.currencyFormatted,
                                    icon: "hourglass",
                                    color: AppTheme.expense
                                )
                            }

                            if activeSubscriptionCount > 0 {
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: "infinity")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AppTheme.recurring)
                                    Text("\(activeSubscriptionCount) active subscription\(activeSubscriptionCount == 1 ? "" : "s")")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)
                    } header: {
                        Label("Summary", systemImage: "chart.pie.fill")
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                // Overdue
                if !overduePayments.isEmpty {
                    Section {
                        ForEach(overduePayments) { payment in
                            NavigationLink(destination: RecurringPaymentDetailView(payment: payment)) {
                                RecurringPaymentRow(payment: payment)
                            }
                        }
                    } header: {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.expense)
                    }
                }

                // Filter
                Section {
                    Picker("Filter", selection: $filterType) {
                        ForEach(RecurringFilterType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                // List
                if filteredPayments.isEmpty {
                    ContentUnavailableView(
                        filterType == .active ? "No Active Plans" :
                        filterType == .upcoming ? "No Upcoming Payments" :
                        filterType == .completed ? "No Completed Plans" : "No Recurring Payments",
                        systemImage: "arrow.clockwise.circle",
                        description: Text("Set up installment plans or subscriptions for your recurring expenses")
                    )
                } else {
                    Section {
                        ForEach(filteredPayments) { payment in
                            NavigationLink(destination: RecurringPaymentDetailView(payment: payment)) {
                                RecurringPaymentRow(payment: payment)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(payment)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                if payment.isActive && !payment.isCompleted {
                                    Button {
                                        payment.isActive = false
                                    } label: {
                                        Label(payment.isSubscription ? "Cancel" : "Pause", systemImage: payment.isSubscription ? "xmark.circle" : "pause.circle")
                                    }
                                    .tint(payment.isSubscription ? .red : .orange)
                                } else if !payment.isActive && !payment.isCompleted {
                                    Button {
                                        payment.isActive = true
                                    } label: {
                                        Label("Resume", systemImage: "play.circle")
                                    }
                                    .tint(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recurring")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddPayment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPayment) {
                AddRecurringPaymentView()
            }
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(AppTypography.caption)
            }
            .foregroundStyle(color)

            Text(value)
                .font(AppTypography.amountSmall)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Row

struct RecurringPaymentRow: View {
    let payment: RecurringPayment

    var statusColor: Color {
        if payment.isCompleted { return AppTheme.income }
        if payment.isOverdue { return AppTheme.expense }
        if payment.isSubscription { return AppTheme.recurring }
        return AppTheme.primary
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Progress / Status indicator
            ZStack {
                if payment.isSubscription && !payment.isCompleted {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: payment.isActive ? "infinity" : "pause.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(statusColor)
                } else {
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 3)
                        .frame(width: 40, height: 40)
                    Circle()
                        .trim(from: 0, to: CGFloat(payment.progress))
                        .stroke(statusColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: payment.isCompleted ? "checkmark" : "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(statusColor)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(payment.name)
                    .font(AppTypography.body)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let accountName = payment.account?.name {
                        Text(accountName)
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    if payment.isActive && !payment.isCompleted {
                        if payment.isSubscription {
                            Text("Ongoing")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(AppTheme.recurring))
                        } else {
                            Text("\(payment.completedInstallments)/\(payment.totalInstallments)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(statusColor))
                        }
                    }

                    if payment.isSplit {
                        Text("\(payment.splitCount) split")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.recurring)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(AppTheme.recurring.opacity(0.15)))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(payment.installmentAmount.currencyFormatted)
                    .font(AppTypography.bodyEmphasized)
                    .foregroundColor(statusColor)

                if payment.isActive && !payment.isCompleted {
                    Text(payment.nextPaymentDate.formatted(date: .abbreviated, time: .omitted))
                        .font(AppTypography.caption)
                        .foregroundColor(payment.isOverdue ? AppTheme.expense : AppTheme.textSecondary)
                } else if payment.isCompleted {
                    Text(payment.isSubscription ? "Cancelled" : "Completed")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.income)
                } else {
                    Text("Paused")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.transfer)
                }
            }
        }
        .opacity(payment.isCompleted ? 0.6 : 1.0)
    }
}

enum RecurringFilterType: String, CaseIterable {
    case active = "Active"
    case upcoming = "Upcoming"
    case completed = "Done"
    case all = "All"
}

#Preview {
    RecurringPaymentsView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self, RecurringPayment.self])
}
