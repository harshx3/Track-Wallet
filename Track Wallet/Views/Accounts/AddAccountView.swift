//
//  AddAccountView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct AddAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var accountType: AccountType = .bank
    @State private var openingBalance = ""
    @State private var currentBalance = ""
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "dollarsign.circle.fill"
    @State private var isPaymentMethod = true
    @State private var selectedPaymentMethods: Set<String> = []
    @State private var websiteURL = ""
    @State private var hasDueDate = false
    @State private var nextDueDate = Date()
    @State private var showingIconPicker = false
    @State private var customColor = Color.blue
    @FocusState private var focusedField: Field?

    enum Field {
        case name, openingBalance, currentBalance, websiteURL
    }

    let colors = String.namedColors
    let availablePaymentMethods = ["Cash", "Cheque", "Zelle", "Wire Transfer", "ACH", "Apple Pay", "Venmo", "PayPal"]

    var openingBalanceLabel: String {
        accountType == .creditCard ? "Credit Limit" : "Opening Balance"
    }

    var currentBalanceLabel: String {
        accountType == .creditCard ? "Current Due" : "Current Balance"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Account Name", text: $name)
                        .focused($focusedField, equals: .name)

                    Picker("Account Type", selection: $accountType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Account Details")
                } footer: {
                    if accountType == .creditCard {
                        Text("For credit cards, enter your credit limit and current amount due.")
                            .font(.caption)
                    }
                }

                Section {
                    HStack {
                        Text(openingBalanceLabel)
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $openingBalance)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .openingBalance)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    HStack {
                        Text(currentBalanceLabel)
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $currentBalance)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .currentBalance)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                } header: {
                    Text("Balance")
                }

                Section {
                    TextField("e.g. chase.com", text: $websiteURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .websiteURL)
                } header: {
                    Text("Website")
                } footer: {
                    Text("Used to show the account's logo.")
                }

                if accountType == .creditCard {
                    Section {
                        Toggle("Set Due Date", isOn: $hasDueDate.animation())

                        if hasDueDate {
                            DatePicker(
                                "Next Due Date",
                                selection: $nextDueDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                        }
                    } header: {
                        Text("Billing")
                    } footer: {
                        Text("Set your next bill due date to get payment reminders. It auto-advances each month.")
                    }
                }

                if accountType != .creditCard {
                    Section {
                        ForEach(availablePaymentMethods, id: \.self) { method in
                            Button {
                                if selectedPaymentMethods.contains(method) {
                                    selectedPaymentMethods.remove(method)
                                } else {
                                    selectedPaymentMethods.insert(method)
                                }
                            } label: {
                                HStack {
                                    Text(method)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedPaymentMethods.contains(method) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Payment Methods")
                    } footer: {
                        Text("Select payment methods available for this account")
                            .font(.caption)
                    }
                }

                Section {
                    IconPickerButton(
                        icon: selectedIcon,
                        color: selectedColor.toColor,
                        action: { showingIconPicker = true }
                    )

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 10) {
                        ForEach(AppIcons.accountIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                                focusedField = nil
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundStyle(selectedIcon == icon ? .white : selectedColor.toColor)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedIcon == icon ? selectedColor.toColor : selectedColor.toColor.opacity(0.15))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)

                    Button {
                        showingIconPicker = true
                    } label: {
                        Label("Browse All Icons", systemImage: "square.grid.2x2")
                            .font(AppTypography.callout)
                    }
                } header: {
                    Text("Icon")
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                                focusedField = nil
                            } label: {
                                Circle()
                                    .fill(color.toColor)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .fontWeight(.bold)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)

                    ColorPicker("Custom Color", selection: $customColor, supportsOpacity: false)
                        .onChange(of: customColor) { _, newColor in
                            selectedColor = newColor.hexString
                        }
                } header: {
                    Text("Color")
                }

                Section {
                    Toggle("Use as Payment Method", isOn: $isPaymentMethod)
                } footer: {
                    Text("Enable to use this account when adding transactions")
                        .font(.caption)
                }
            }
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAccount() }
                        .disabled(name.isEmpty)
                        .fontWeight(.semibold)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(
                    selectedIcon: $selectedIcon,
                    accentColor: selectedColor.toColor,
                    icons: AppIcons.allGroups
                )
            }
        }
        .onAppear {
            selectedIcon = accountType.icon
        }
        .onChange(of: accountType) { _, newType in
            selectedIcon = newType.icon
        }
    }

    private func saveAccount() {
        let openingBalanceValue = Decimal(string: openingBalance) ?? 0
        let currentBalanceValue = Decimal(string: currentBalance) ?? 0

        let account = Account(
            name: name,
            type: accountType,
            openingBalance: openingBalanceValue,
            currentBalance: currentBalanceValue,
            icon: selectedIcon,
            color: selectedColor,
            isPaymentMethod: isPaymentMethod,
            isAsset: accountType.isAsset,
            paymentMethods: Array(selectedPaymentMethods),
            websiteURL: websiteURL.trimmingCharacters(in: .whitespaces)
        )
        if accountType == .creditCard && hasDueDate {
            account.nextBillDueDate = nextDueDate
        }

        modelContext.insert(account)

        if accountType == .creditCard && hasDueDate {
            NotificationManager.shared.scheduleDueDateReminder(for: account)
        }

        dismiss()
    }
}

#Preview {
    AddAccountView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self])
}
