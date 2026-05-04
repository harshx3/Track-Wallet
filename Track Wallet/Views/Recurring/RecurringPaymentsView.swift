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
        payments.filter { $0.isActive && !$0.isCompleted }
            .reduce(Decimal(0)) { $0 + $1.remainingAmount }
    }

    var overduePayments: [RecurringPayment] {
        payments.filter { $0.isOverdue }
    }

    var body: some View {
        NavigationStack {
            List {
                if !payments.filter({ $0.isActive }).isEmpty {
                    Section {
                        HStack(spacing: AppSpacing.md) {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text("Monthly")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                Text(totalMonthlyCommitment.currencyFormatted)
                                    .font(AppTypography.amountSmall)
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Rectangle()
                                .fill(AppTheme.border)
                                .frame(width: 1, height: 40)

                            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                                Text("Remaining")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                Text(totalRemainingAmount.currencyFormatted)
                                    .font(AppTypography.amountSmall)
                                    .foregroundColor(AppTheme.expense)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.vertical, AppSpacing.xs)
                    } header: {
                        Label("Summary", systemImage: "chart.pie.fill")
                    }
                }

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

                if filteredPayments.isEmpty {
                    ContentUnavailableView(
                        filterType == .active ? "No Active Plans" :
                        filterType == .upcoming ? "No Upcoming Payments" :
                        filterType == .completed ? "No Completed Plans" : "No Recurring Payments",
                        systemImage: "arrow.clockwise.circle",
                        description: Text("Set up installment plans for your recurring expenses")
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
                                        Label("Pause", systemImage: "pause.circle")
                                    }
                                    .tint(.orange)
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

// MARK: - Row

struct RecurringPaymentRow: View {
    let payment: RecurringPayment

    var statusColor: Color {
        if payment.isCompleted { return AppTheme.income }
        if payment.isOverdue { return AppTheme.expense }
        return AppTheme.primary
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
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
                        Text("\(payment.completedInstallments)/\(payment.totalInstallments)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(statusColor))
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
                    Text("Completed")
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
