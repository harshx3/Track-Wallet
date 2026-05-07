//
//  AddTransactionView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var accounts: [Account]
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var amount = ""
    @State private var transactionType: TransactionType = .expense
    @State private var selectedAccount: Account?
    @State private var selectedToAccount: Account?
    @State private var selectedCategory: Category?
    @State private var transactionDescription = ""
    @State private var date = Date()
    @State private var showingAddCategory = false
    @State private var showingInsufficientFundsAlert = false
    @State private var insufficientFundsMessage = ""
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case amount, description
    }

    var filteredCategories: [Category] {
        if transactionType == .transfer || transactionType == .reimbursed {
            return categories
        }
        return categories.filter { $0.type == transactionType }
    }

    var isCategoryRequired: Bool {
        transactionType == .expense || transactionType == .income
    }

    var paymentMethods: [Account] {
        accounts.filter { $0.isPaymentMethod }
    }

    var transferDestinations: [Account] {
        accounts.filter { $0.id != selectedAccount?.id }
    }

    var canSave: Bool {
        guard !amount.isEmpty, (Decimal(string: amount) ?? 0) > 0 else { return false }
        guard selectedAccount != nil else { return false }

        if transactionType == .transfer {
            guard selectedToAccount != nil else { return false }
        }

        if isCategoryRequired {
            guard selectedCategory != nil else { return false }
        }

        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $transactionType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Transaction Type")
                }

                Section {
                    HStack(spacing: 12) {
                        Text("$")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(AppTypography.amountMedium)
                            .focused($focusedField, equals: .amount)
                    }
                    .listRowInsets(EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16))

                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("Amount")
                }

                Section {
                    if filteredCategories.isEmpty {
                        VStack(spacing: 12) {
                            Text(isCategoryRequired ? "No categories for \(transactionType.rawValue.lowercased())" : "No categories available")
                                .font(.callout)
                                .foregroundStyle(.secondary)

                            Button(action: { showingAddCategory = true }) {
                                Label("Create Category", systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(filteredCategories) { category in
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

                                Button(action: { showingAddCategory = true }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("New")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .strokeBorder(.blue, lineWidth: 2)
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                } header: {
                    HStack {
                        Text("Category")
                        Spacer()
                        if isCategoryRequired {
                            if selectedCategory == nil && !filteredCategories.isEmpty {
                                Text("Required")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        } else {
                            Text("Optional")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    if paymentMethods.isEmpty {
                        Text("No payment methods available")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Select Account", selection: $selectedAccount) {
                            Text("Choose account...").tag(nil as Account?)
                                .foregroundStyle(.secondary)
                            ForEach(paymentMethods) { account in
                                Label {
                                    Text(account.name)
                                } icon: {
                                    Image(systemName: account.icon)
                                }
                                .tag(account as Account?)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Payment Method")
                        Spacer()
                        if selectedAccount == nil {
                            Text("Required")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                if transactionType == .transfer {
                    Section {
                        if transferDestinations.isEmpty {
                            Text("No other accounts available")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Select Destination", selection: $selectedToAccount) {
                                Text("Choose account...").tag(nil as Account?)
                                    .foregroundStyle(.secondary)
                                ForEach(transferDestinations) { account in
                                    Label {
                                        Text(account.name)
                                    } icon: {
                                        Image(systemName: account.icon)
                                    }
                                    .tag(account as Account?)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("To Account")
                            Spacer()
                            if selectedToAccount == nil {
                                Text("Required")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Section {
                    TextField("Add a note...", text: $transactionDescription, axis: .vertical)
                        .lineLimit(2...4)
                        .focused($focusedField, equals: .description)
                } header: {
                    Text("Description (Optional)")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
            .alert("Insufficient Funds", isPresented: $showingInsufficientFundsAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(insufficientFundsMessage)
            }
        }
        .onChange(of: transactionType) { _, _ in
            selectedToAccount = nil
            selectedCategory = nil
        }
        .onChange(of: selectedAccount) { _, _ in
            if selectedToAccount?.id == selectedAccount?.id {
                selectedToAccount = nil
            }
        }
    }

    private func validateTransaction() -> Bool {
        guard let account = selectedAccount else { return false }
        let amountValue = Decimal(string: amount) ?? 0

        switch transactionType {
        case .expense:
            if account.type == .cash || account.type == .bank || account.type == .debitCard {
                if account.currentBalance < amountValue {
                    insufficientFundsMessage = "You don't have enough balance in \(account.name). Available: \(account.currentBalance.currencyFormatted)"
                    showingInsufficientFundsAlert = true
                    return false
                }
            } else if account.type == .creditCard {
                let newBalance = account.currentBalance + amountValue
                if newBalance > account.creditLimit {
                    insufficientFundsMessage = "This transaction would exceed your credit limit. Available credit: \((account.creditLimit - account.currentBalance).currencyFormatted)"
                    showingInsufficientFundsAlert = true
                    return false
                }
            }

        case .transfer:
            if account.type == .cash || account.type == .bank || account.type == .debitCard {
                if account.currentBalance < amountValue {
                    insufficientFundsMessage = "You don't have enough balance in \(account.name). Available: \(account.currentBalance.currencyFormatted)"
                    showingInsufficientFundsAlert = true
                    return false
                }
            }

        case .income, .reimbursed:
            break
        }

        return true
    }

    private func saveTransaction() {
        guard let account = selectedAccount else { return }
        guard validateTransaction() else { return }

        let amountValue = Decimal(string: amount) ?? 0
        guard amountValue > 0 else { return }

        let transaction = Transaction(
            amount: amountValue,
            type: transactionType,
            transactionDescription: transactionDescription,
            date: date,
            fromAccount: account,
            toAccount: transactionType == .transfer ? selectedToAccount : nil,
            category: selectedCategory
        )

        switch transactionType {
        case .income:
            account.currentBalance += amountValue
        case .expense:
            if account.type == .creditCard {
                account.currentBalance += amountValue
            } else {
                account.currentBalance -= amountValue
            }
        case .transfer:
            account.currentBalance -= amountValue
            if let toAccount = selectedToAccount {
                if toAccount.isAsset {
                    toAccount.currentBalance += amountValue
                } else {
                    toAccount.currentBalance -= amountValue
                }
            }
        case .reimbursed:
            account.currentBalance += amountValue
        }

        modelContext.insert(transaction)
        dismiss()
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.subheadline)
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isSelected ? .white : category.color.toColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? category.color.toColor : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(category.color.toColor, lineWidth: isSelected ? 0 : 2)
            )
            .shadow(color: isSelected ? category.color.toColor.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Account.self, Transaction.self, Category.self, Debt.self, configurations: config)

    return AddTransactionView()
        .modelContainer(container)
}
