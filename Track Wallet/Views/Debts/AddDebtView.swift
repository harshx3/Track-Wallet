//
//  AddDebtView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct AddDebtView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Debt.date, order: .reverse) private var allDebts: [Debt]

    let existingPersonName: String?

    @State private var personName = ""
    @State private var amount = ""
    @State private var debtType: DebtType = .lending
    @State private var debtDescription = ""
    @State private var date = Date()
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case personName, amount, description
    }

    init(existingPersonName: String? = nil) {
        self.existingPersonName = existingPersonName
    }

    var existingPersonNames: [String] {
        let names = Set(allDebts.map { $0.personName })
        return names.sorted()
    }

    var filteredSuggestions: [String] {
        guard !personName.isEmpty, existingPersonName == nil else { return [] }
        return existingPersonNames.filter {
            $0.localizedCaseInsensitiveContains(personName) && $0.lowercased() != personName.lowercased()
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Debt Details") {
                    if let existing = existingPersonName {
                        HStack {
                            Text("Person")
                            Spacer()
                            Text(existing)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    } else {
                        TextField("Person Name", text: $personName)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .personName)

                        if !filteredSuggestions.isEmpty {
                            ForEach(filteredSuggestions, id: \.self) { name in
                                Button {
                                    personName = name
                                    focusedField = nil
                                } label: {
                                    Label(name, systemImage: "person.fill")
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }
                        }
                    }

                    Picker("Type", selection: $debtType) {
                        ForEach(DebtType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("$")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .focused($focusedField, equals: .amount)
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Toggle("Set Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }

                    TextField("Description (Optional)", text: $debtDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .description)
                }

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: debtType.icon)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(debtType == .lending ? Color.orange : Color.purple)
                            )

                        Text(debtType == .lending ? "You lent money to \(displayName)" : "You borrowed money from \(displayName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(existingPersonName != nil ? "Add Entry" : "New Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDebt()
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
            .onAppear {
                if let existing = existingPersonName {
                    personName = existing
                }
            }
        }
    }

    private var displayName: String {
        let name = existingPersonName ?? personName
        return name.isEmpty ? "someone" : name
    }

    private var canSave: Bool {
        let nameValid = existingPersonName != nil || !personName.trimmingCharacters(in: .whitespaces).isEmpty
        let amountValid = !amount.isEmpty && (Decimal(string: amount) ?? 0) > 0
        return nameValid && amountValid
    }

    private func saveDebt() {
        let amountValue = Decimal(string: amount) ?? 0
        guard amountValue > 0 else { return }

        let finalName = existingPersonName ?? personName.trimmingCharacters(in: .whitespaces)
        guard !finalName.isEmpty else { return }

        let debt = Debt(
            personName: finalName,
            amount: amountValue,
            type: debtType,
            debtDescription: debtDescription,
            date: date,
            dueDate: hasDueDate ? dueDate : nil
        )

        modelContext.insert(debt)
        dismiss()
    }
}

#Preview {
    AddDebtView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self])
}
