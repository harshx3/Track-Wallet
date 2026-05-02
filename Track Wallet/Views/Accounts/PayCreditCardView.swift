//
//  PayCreditCardView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/28/26.
//

import SwiftUI
import SwiftData

struct PayCreditCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var accounts: [Account]

    let creditCardAccount: Account

    @State private var amount = ""
    @State private var selectedPaymentAccountID: UUID?
    @State private var transactionDescription = ""
    @State private var date = Date()
    @FocusState private var focusedField: Field?

    enum Field {
        case amount, description
    }

    var paymentAccounts: [Account] {
        accounts.filter { $0.isAsset && $0.id != creditCardAccount.id }
    }

    var selectedPaymentAccount: Account? {
        paymentAccounts.first { $0.id == selectedPaymentAccountID }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Current Due")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(creditCardAccount.currentBalance.currencyFormatted)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                    }

                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("Payment Details")
                }

                Section {
                    if paymentAccounts.isEmpty {
                        Text("No payment accounts available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(paymentAccounts) { account in
                            Button {
                                selectedPaymentAccountID = account.id
                            } label: {
                                HStack {
                                    Image(systemName: account.icon)
                                        .foregroundStyle(account.color.toColor)
                                        .frame(width: 24)
                                    Text(account.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(account.currentBalance.currencyFormatted)
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                    if selectedPaymentAccountID == account.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Pay From")
                        Spacer()
                        if selectedPaymentAccountID == nil {
                            Text("Required")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section {
                    TextField("Description (Optional)", text: $transactionDescription, axis: .vertical)
                        .lineLimit(2...4)
                        .focused($focusedField, equals: .description)
                } header: {
                    Text("Notes")
                }

                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Paying")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: creditCardAccount.icon)
                                    .foregroundStyle(creditCardAccount.color.toColor)
                                Text(creditCardAccount.name)
                                    .fontWeight(.medium)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Pay Credit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Pay") {
                        savePayment()
                    }
                    .disabled(amount.isEmpty || selectedPaymentAccountID == nil)
                    .fontWeight(.semibold)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let firstAccount = paymentAccounts.first {
                    selectedPaymentAccountID = firstAccount.id
                }
            }
        }
    }

    private func savePayment() {
        guard let paymentAccount = selectedPaymentAccount else { return }
        let amountValue = Decimal(string: amount) ?? 0
        guard amountValue > 0 else { return }

        let transaction = Transaction(
            amount: amountValue,
            type: .transfer,
            transactionDescription: transactionDescription.isEmpty ? "Credit Card Payment" : transactionDescription,
            paymentMethod: paymentAccount.name,
            date: date,
            fromAccount: paymentAccount,
            toAccount: creditCardAccount
        )

        paymentAccount.currentBalance -= amountValue
        creditCardAccount.currentBalance -= amountValue

        modelContext.insert(transaction)
        dismiss()
    }
}

#Preview {
    @Previewable @State var creditCard = Account(
        name: "Chase Sapphire",
        type: .creditCard,
        openingBalance: 5000,
        currentBalance: 1250,
        isAsset: false
    )

    PayCreditCardView(creditCardAccount: creditCard)
        .modelContainer(for: [Account.self, Transaction.self], inMemory: true)
}
