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
    @State private var showingIconPicker = false
    @FocusState private var focusedField: Field?

    enum Field {
        case name, creditLimit, websiteURL
    }

    let colors = ["blue", "green", "orange", "red", "purple", "pink", "indigo", "teal", "yellow", "cyan", "mint", "brown"]
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
            .navigationTitle("Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
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
            .onAppear {
                name = account.name
                selectedColor = account.color
                selectedIcon = account.icon
                isPaymentMethod = account.isPaymentMethod
                selectedPaymentMethods = Set(account.paymentMethods)
                creditLimit = account.type == .creditCard ? String(describing: account.creditLimit) : ""
                websiteURL = account.websiteURL
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(
                    selectedIcon: $selectedIcon,
                    accentColor: selectedColor.toColor,
                    icons: AppIcons.allGroups
                )
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
