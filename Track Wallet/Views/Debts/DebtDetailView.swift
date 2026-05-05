//
//  DebtDetailView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct DebtDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let debt: Debt
    
    @State private var showingPaymentSheet = false
    @State private var paymentAmount = ""
    
    var debtTransactions: [Transaction] {
        debt.transactions?.sorted(by: { $0.date > $1.date }) ?? []
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Person")
                    Spacer()
                    Text(debt.personName)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Type")
                    Spacer()
                    Text(debt.type.rawValue)
                        .foregroundColor(AppTheme.textSecondary)
                }

                HStack {
                    Text("Original Amount")
                    Spacer()
                    Text(debt.amount.currencyFormatted)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Remaining")
                    Spacer()
                    Text(debt.remainingAmount.currencyFormatted)
                        .fontWeight(.semibold)
                        .foregroundColor(debt.isPaid ? AppTheme.income : AppTheme.textPrimary)
                }

                if let account = debt.account {
                    HStack {
                        Text(debt.type == .lending ? "Paid From" : "Received In")
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: account.icon)
                                .font(.caption)
                            Text(account.name)
                        }
                        .foregroundColor(AppTheme.primary)
                    }
                }
            }

            Section {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(debt.date.formatted(date: .long, time: .omitted))
                        .foregroundColor(AppTheme.textSecondary)
                }

                if let dueDate = debt.dueDate {
                    HStack {
                        Text("Due Date")
                        Spacer()
                        Text(dueDate.formatted(date: .long, time: .omitted))
                            .foregroundColor(dueDate < Date() && !debt.isPaid ? AppTheme.expense : AppTheme.textSecondary)
                    }
                }

                HStack {
                    Text("Status")
                    Spacer()
                    Text(debt.isPaid ? "Settled" : "Active")
                        .foregroundColor(debt.isPaid ? AppTheme.income : AppTheme.transfer)
                }
            }

            if !debt.debtDescription.isEmpty {
                Section("Description") {
                    Text(debt.debtDescription)
                }
            }

            if !debtTransactions.isEmpty {
                Section("Payment History") {
                    ForEach(debtTransactions) { transaction in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(AppTypography.body)
                                if !transaction.transactionDescription.isEmpty {
                                    Text(transaction.transactionDescription)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                            Spacer()
                            Text(transaction.amount.currencyFormatted)
                                .font(AppTypography.bodyEmphasized)
                        }
                    }
                }
            }

            if !debt.isPaid {
                Section {
                    Button {
                        showingPaymentSheet = true
                    } label: {
                        Label("Record Payment", systemImage: "plus.circle")
                    }

                    Button {
                        markAsPaid()
                    } label: {
                        Label("Mark as Settled", systemImage: "checkmark.circle")
                    }
                    .foregroundColor(AppTheme.income)
                }
            }
        }
        .navigationTitle("Debt Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaymentSheet) {
            paymentSheet
        }
    }
    
    private var paymentSheet: some View {
        NavigationStack {
            Form {
                Section("Payment Amount") {
                    HStack {
                        Text("$")
                        TextField("Amount", text: $paymentAmount)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Remaining:")
                        Spacer()
                        Text(debt.remainingAmount.currencyFormatted)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Record Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingPaymentSheet = false
                        paymentAmount = ""
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        recordPayment()
                    }
                    .disabled(paymentAmount.isEmpty)
                }
            }
        }
    }
    
    private func recordPayment() {
        let amount = Decimal(string: paymentAmount) ?? 0
        guard amount > 0 else { return }

        let transaction = Transaction(
            amount: amount,
            type: debt.type == .lending ? .income : .expense,
            transactionDescription: "Payment for \(debt.personName)",
            debt: debt
        )

        modelContext.insert(transaction)

        if debt.remainingAmount <= 0 {
            debt.isPaid = true
        }

        showingPaymentSheet = false
        paymentAmount = ""
    }
    
    private func markAsPaid() {
        debt.isPaid = true
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Debt.self, configurations: config)
    
    let debt = Debt(
        personName: "John Doe",
        amount: 1000,
        type: .lending,
        debtDescription: "Borrowed for emergency"
    )
    
    container.mainContext.insert(debt)
    
    return DebtDetailView(debt: debt)
        .modelContainer(container)
}
