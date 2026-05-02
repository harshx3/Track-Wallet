//
//  AddDepositView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/28/26.
//

import SwiftUI
import SwiftData

struct AddDepositView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Category.name) private var categories: [Category]

    let account: Account

    @State private var amount = ""
    @State private var selectedPaymentMethod = "Cash"
    @State private var selectedCategory: Category?
    @State private var transactionDescription = ""
    @State private var date = Date()
    @FocusState private var focusedField: Field?

    enum Field {
        case amount, description
    }

    let paymentMethods = ["Cash", "Cheque", "Zelle", "ACH", "Wire Transfer", "Apple Pay", "Venmo", "PayPal"]

    var incomeCategories: [Category] {
        categories.filter { $0.type == .income }
    }

    var depositTitle: String {
        account.type == .cash ? "Add Cash" : "Deposit"
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

                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("Deposit Details")
                }

                if !incomeCategories.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(incomeCategories) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory?.id == category.id,
                                        action: {
                                            if selectedCategory?.id == category.id {
                                                selectedCategory = nil
                                            } else {
                                                selectedCategory = category
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    } header: {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text("Optional")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Picker("Payment Method", selection: $selectedPaymentMethod) {
                        ForEach(paymentMethods, id: \.self) { method in
                            HStack {
                                Image(systemName: iconForPaymentMethod(method))
                                Text(method)
                            }
                            .tag(method)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("How did you receive this?")
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
                            Text("Depositing to")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: account.icon)
                                    .foregroundStyle(account.color.toColor)
                                Text(account.name)
                                    .fontWeight(.medium)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(depositTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDeposit()
                    }
                    .disabled(amount.isEmpty)
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
        }
    }

    private func iconForPaymentMethod(_ method: String) -> String {
        switch method {
        case "Cash": return "banknote.fill"
        case "Cheque": return "doc.text.fill"
        case "Zelle": return "bolt.fill"
        case "ACH": return "building.columns.fill"
        case "Wire Transfer": return "arrow.left.arrow.right"
        case "Apple Pay": return "apple.logo"
        case "Venmo": return "dollarsign.circle.fill"
        case "PayPal": return "p.circle.fill"
        default: return "dollarsign.circle.fill"
        }
    }

    private func saveDeposit() {
        let amountValue = Decimal(string: amount) ?? 0
        guard amountValue > 0 else { return }

        let transaction = Transaction(
            amount: amountValue,
            type: .income,
            transactionDescription: transactionDescription.isEmpty ? "\(depositTitle) via \(selectedPaymentMethod)" : transactionDescription,
            paymentMethod: selectedPaymentMethod,
            date: date,
            fromAccount: nil,
            toAccount: account,
            category: selectedCategory
        )

        account.currentBalance += amountValue

        modelContext.insert(transaction)
        dismiss()
    }
}

#Preview {
    @Previewable @State var account = Account(
        name: "Cash Wallet",
        type: .cash,
        currentBalance: 100
    )

    AddDepositView(account: account)
        .modelContainer(for: [Account.self, Transaction.self, Category.self], inMemory: true)
}
