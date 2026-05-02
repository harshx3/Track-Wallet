//
//  EditAccountView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct EditAccountView: View {
    @Environment(\.dismiss) private var dismiss
    
    let account: Account
    
    @State private var name = ""
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "dollarsign.circle.fill"
    @State private var isPaymentMethod = true
    @State private var selectedPaymentMethods: Set<String> = []
    @State private var creditLimit = ""
    @State private var websiteURL = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case name, creditLimit, websiteURL
    }
    
    let colors = ["blue", "green", "orange", "red", "purple", "pink", "indigo", "teal"]
    let icons = [
        "dollarsign.circle.fill", "banknote.fill", "building.columns.fill",
        "creditcard.fill", "wallet.pass.fill", "chart.line.uptrend.xyaxis",
        "briefcase.fill", "bag.fill"
    ]
    let availablePaymentMethods = ["Cash", "Cheque", "Zelle", "Wire Transfer", "ACH", "Apple Pay", "Venmo", "PayPal"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Account Name", text: $name)
                        .focused($focusedField, equals: .name)
                    
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(account.type.rawValue)
                            .foregroundStyle(.secondary)
                    }
                    
                    if account.type == .creditCard {
                        HStack {
                            Text("Credit Limit")
                            Spacer()
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $creditLimit)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .creditLimit)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                    }
                    
                    HStack {
                        Text(account.type == .creditCard ? "Current Due" : "Current Balance")
                        Spacer()
                        Text(account.balance.currencyFormatted)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Account Details")
                }
                
                // Payment Methods Section (not for credit cards)
                if account.type != .creditCard {
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
                            AccountIconView(account: account, size: 32)
                        }
                    }
                } header: {
                    Text("Website Icon (Optional)")
                } footer: {
                    Text("Enter a website to use its icon for this account")
                        .font(.caption)
                }

                Section("Appearance") {
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
            .navigationTitle("Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
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
            .onAppear {
                name = account.name
                selectedColor = account.color
                selectedIcon = account.icon
                isPaymentMethod = account.isPaymentMethod
                selectedPaymentMethods = Set(account.paymentMethods)
                creditLimit = account.type == .creditCard ? String(describing: account.creditLimit) : ""
                websiteURL = account.websiteURL
            }
        }
    }
    
    private func saveChanges() {
        account.name = name
        account.icon = selectedIcon
        account.color = selectedColor
        account.isPaymentMethod = isPaymentMethod
        account.paymentMethods = Array(selectedPaymentMethods)
        account.websiteURL = websiteURL.trimmingCharacters(in: .whitespaces)

        // Update credit limit for credit cards
        if account.type == .creditCard, let limitValue = Decimal(string: creditLimit) {
            account.creditLimit = limitValue
        }
        
        dismiss()
    }
}

#Preview {
    @Previewable @State var account: Account = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Account.self, configurations: config)
        
        let account = Account(name: "Chase Bank", type: .bank, openingBalance: 5000, currentBalance: 5000)
        container.mainContext.insert(account)
        
        return account
    }()
    
    EditAccountView(account: account)
        .modelContainer(for: Account.self, inMemory: true)
}
