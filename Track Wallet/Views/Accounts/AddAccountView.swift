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
    @FocusState private var focusedField: Field?

    enum Field {
        case name, openingBalance, currentBalance, websiteURL
    }
    
    let colors = ["blue", "green", "orange", "red", "purple", "pink", "indigo", "teal"]
    let icons = [
        "dollarsign.circle.fill", "banknote.fill", "building.columns.fill",
        "creditcard.fill", "wallet.pass.fill", "chart.line.uptrend.xyaxis",
        "briefcase.fill", "bag.fill"
    ]
    
    let availablePaymentMethods = ["Cash", "Cheque", "Zelle", "Wire Transfer", "ACH", "Apple Pay", "Venmo", "PayPal"]
    
    // Dynamic label based on account type
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
                        .font(.body)
                    
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
                            .foregroundStyle(.primary)
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
                            .foregroundStyle(.primary)
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
                
                // Payment Methods Section
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
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(.secondary)
                        TextField("e.g. chase.com", text: $websiteURL)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .websiteURL)
                    }

                    if !websiteURL.isEmpty {
                        HStack {
                            Text("Preview")
                                .foregroundStyle(.secondary)
                            Spacer()
                            let previewAccount = Account(name: "", type: .bank, icon: selectedIcon, color: selectedColor, websiteURL: websiteURL)
                            AccountIconView(account: previewAccount, size: 32)
                        }
                    }
                } header: {
                    Text("Website Icon (Optional)")
                } footer: {
                    Text("Enter a website to use its icon for this account")
                        .font(.caption)
                }

                Section("Appearance") {
                    // Icon Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                    focusedField = nil
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundStyle(selectedIcon == icon ? .white : selectedColor.toColor)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedIcon == icon ? selectedColor.toColor : selectedColor.toColor.opacity(0.2))
                                        )
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(colors, id: \.self) { color in
                                    Button {
                                        selectedColor = color
                                        focusedField = nil
                                    } label: {
                                        Circle()
                                            .fill(color.toColor)
                                            .frame(width: 50, height: 50)
                                            .overlay {
                                                if selectedColor == color {
                                                    Image(systemName: "checkmark")
                                                        .foregroundStyle(.white)
                                                        .fontWeight(.bold)
                                                        .font(.title3)
                                                }
                                            }
                                            .overlay {
                                                Circle()
                                                    .strokeBorder(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAccount()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        focusedField = nil
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .fontWeight(.semibold)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            // Set default icon based on account type
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
        
        modelContext.insert(account)
        dismiss()
    }
}

#Preview {
    AddAccountView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self])
}
