//
//  AddRecurringPaymentView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 5/2/26.
//

import SwiftUI
import SwiftData

struct AddRecurringPaymentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var accounts: [Account]
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var name = ""
    @State private var planType: RecurringPlanType = .installment
    @State private var totalAmount = ""
    @State private var installmentAmount = ""
    @State private var frequency: PaymentFrequency = .monthly
    @State private var dayOfMonth = 1
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var selectedAccountID: UUID?
    @State private var selectedCategory: Category?
    @State private var recurringDescription = ""
    @State private var showingAddCategory = false
    @State private var isSplit = false
    @State private var splitMembers: [String] = []
    @State private var newMemberName = ""
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, totalAmount, installmentAmount, description, memberName
    }

    var paymentAccounts: [Account] {
        accounts.filter { $0.isPaymentMethod }
    }

    var selectedAccount: Account? {
        paymentAccounts.first { $0.id == selectedAccountID }
    }

    var expenseCategories: [Category] {
        categories.filter { $0.type == .expense }
    }

    var calculatedInstallments: Int {
        guard planType == .installment else { return 0 }
        guard let total = Decimal(string: totalAmount),
              let installment = Decimal(string: installmentAmount),
              installment > 0, total > 0 else { return 0 }
        let result = total / installment
        return Int(ceil(Double(truncating: result as NSDecimalNumber)))
    }

    var calculatedEndDate: Date? {
        guard planType == .installment, calculatedInstallments > 0 else { return nil }
        let calendar = Calendar.current
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: calculatedInstallments, to: startDate)
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: calculatedInstallments * 2, to: startDate)
        case .monthly:
            return calendar.date(byAdding: .month, value: calculatedInstallments, to: startDate)
        case .quarterly:
            return calendar.date(byAdding: .month, value: calculatedInstallments * 3, to: startDate)
        case .yearly:
            return calendar.date(byAdding: .year, value: calculatedInstallments, to: startDate)
        }
    }

    var canSave: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespaces).isEmpty
        let hasInstallment = (Decimal(string: installmentAmount) ?? 0) > 0
        let hasAccount = selectedAccountID != nil

        if planType == .installment {
            let hasTotal = (Decimal(string: totalAmount) ?? 0) > 0
            return hasName && hasTotal && hasInstallment && calculatedInstallments > 0 && hasAccount
        } else {
            return hasName && hasInstallment && hasAccount
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Plan Type
                Section {
                    Picker("Plan Type", selection: $planType) {
                        ForEach(RecurringPlanType.allCases, id: \.self) { type in
                            Label(type.label, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                } footer: {
                    Text(planType == .installment
                         ? "Fixed plan with a total amount (e.g., EMI, loan)"
                         : "Ongoing payment with no fixed total (e.g., Netflix, mobile recharge)")
                        .font(AppTypography.caption)
                }

                // Details
                Section {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: planType.icon)
                            .foregroundStyle(AppTheme.recurring)
                            .frame(width: 20)
                        TextField("Plan Name", text: $name)
                            .focused($focusedField, equals: .name)
                    }

                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "text.alignleft")
                            .foregroundStyle(AppTheme.textTertiary)
                            .frame(width: 20)
                        TextField("Description (Optional)", text: $recurringDescription, axis: .vertical)
                            .lineLimit(2...4)
                            .focused($focusedField, equals: .description)
                    }
                } header: {
                    Label("Details", systemImage: "doc.text")
                }

                // Amount
                Section {
                    if planType == .installment {
                        HStack {
                            Text("Total Amount")
                            Spacer()
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $totalAmount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                                .focused($focusedField, equals: .totalAmount)
                        }
                    }

                    HStack {
                        Text(planType == .installment ? "Installment" : "Amount")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $installmentAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                            .focused($focusedField, equals: .installmentAmount)
                    }

                    if planType == .installment && calculatedInstallments > 0 {
                        HStack {
                            Text("Installments")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(calculatedInstallments) payments")
                                .font(AppTypography.bodyEmphasized)
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                } header: {
                    Label("Amount", systemImage: "dollarsign.circle.fill")
                }

                // Split
                Section {
                    Toggle("Split with Others", isOn: $isSplit.animation(.easeInOut(duration: 0.2)))

                    if isSplit {
                        HStack {
                            Image(systemName: "person.fill.badge.plus")
                                .foregroundStyle(AppTheme.textTertiary)
                                .frame(width: 20)
                            TextField("Person Name", text: $newMemberName)
                                .focused($focusedField, equals: .memberName)
                            Button {
                                let trimmed = newMemberName.trimmingCharacters(in: .whitespaces)
                                if !trimmed.isEmpty && !splitMembers.contains(trimmed) {
                                    splitMembers.append(trimmed)
                                    newMemberName = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(AppTheme.primary)
                            }
                            .disabled(newMemberName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }

                        ForEach(splitMembers, id: \.self) { member in
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(AppTheme.recurring)
                                    .frame(width: 20)
                                Text(member)
                                Spacer()
                                Button {
                                    splitMembers.removeAll { $0 == member }
                                    if splitMembers.isEmpty { isSplit = false }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(AppTheme.income)
                                .frame(width: 20)
                            Text("You")
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                        }

                        if !splitMembers.isEmpty, let installment = Decimal(string: installmentAmount), installment > 0 {
                            let perPerson = installment / Decimal(splitMembers.count + 1)
                            HStack {
                                Text("Per Person")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(perPerson.currencyFormatted) each")
                                    .font(AppTypography.bodyEmphasized)
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                    }
                } header: {
                    Label("Split", systemImage: "person.2.fill")
                } footer: {
                    if isSplit {
                        Text("Add people sharing this payment. The total amount is split equally.")
                    }
                }

                // Schedule
                Section {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(PaymentFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }

                    if frequency == .monthly || frequency == .quarterly {
                        Picker("Day of Month", selection: $dayOfMonth) {
                            ForEach(1...28, id: \.self) { day in
                                Text(ordinalDay(day)).tag(day)
                            }
                        }
                    }

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                    if planType == .installment {
                        if let endDate = calculatedEndDate {
                            HStack {
                                Text("Estimated End")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(endDate.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Toggle("Set End Date", isOn: $hasEndDate)

                        if hasEndDate {
                            DatePicker(
                                "End Date",
                                selection: $endDate,
                                in: startDate...,
                                displayedComponents: .date
                            )
                        }
                    }
                } header: {
                    Label("Schedule", systemImage: "calendar.badge.clock")
                }

                // Payment Method
                Section {
                    if paymentAccounts.isEmpty {
                        Text("No payment accounts available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(paymentAccounts) { account in
                            Button {
                                selectedAccountID = account.id
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    AccountIconView(account: account, size: 28, cornerRadius: 6)
                                    Text(account.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(account.currentBalance.currencyFormatted)
                                        .font(AppTypography.caption)
                                        .foregroundStyle(.secondary)
                                    if selectedAccountID == account.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.primary)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Label("Payment Method", systemImage: "creditcard.fill")
                        Spacer()
                        if selectedAccountID == nil {
                            Text("Required")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                // Category
                if !expenseCategories.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(expenseCategories) { category in
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
                            Label("Category", systemImage: "tag.fill")
                            Spacer()
                            Text("Optional")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Preview
                if canSave {
                    Section {
                        VStack(spacing: AppSpacing.sm) {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: planType == .subscription ? "infinity" : "arrow.clockwise.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(AppTheme.recurring)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(name)
                                        .font(AppTypography.bodyEmphasized)
                                    if let account = selectedAccount {
                                        Text("\(installmentAmount.isEmpty ? "$0" : "$\(installmentAmount)")\(frequency.shortLabel) from \(account.name)")
                                            .font(AppTypography.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if planType == .subscription {
                                    Text("Ongoing")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(AppTheme.recurring))
                                }
                            }

                            if planType == .installment {
                                ProgressView(value: 0)
                                    .tint(AppTheme.primary)

                                HStack {
                                    Text("0 of \(calculatedInstallments) payments")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    if let total = Decimal(string: totalAmount) {
                                        Text(total.currencyFormatted)
                                            .font(AppTypography.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } else {
                                HStack {
                                    Text(hasEndDate ? "Until \(endDate.formatted(date: .abbreviated, time: .omitted))" : "Runs until cancelled")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }

                            if isSplit && !splitMembers.isEmpty, let installment = Decimal(string: installmentAmount), installment > 0 {
                                let count = splitMembers.count + 1
                                let perPerson = installment / Decimal(count)
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2.fill")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.recurring)
                                    Text("\(count) people")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(perPerson.currencyFormatted)/person")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppTheme.recurring)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Label("Preview", systemImage: "eye.fill")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Recurring Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
        }
    }

    private func ordinalDay(_ day: Int) -> String {
        let suffixes = ["th", "st", "nd", "rd"]
        let idx = (day % 100 >= 11 && day % 100 <= 13) ? 0 : min(day % 10, 3)
        return "\(day)\(suffixes[idx])"
    }

    private func save() {
        let installment = Decimal(string: installmentAmount) ?? 0
        guard installment > 0 else { return }

        if planType == .installment {
            let total = Decimal(string: totalAmount) ?? 0
            guard total > 0 else { return }

            let members = isSplit ? splitMembers : []
            let payment = RecurringPayment(
                name: name.trimmingCharacters(in: .whitespaces),
                planType: .installment,
                totalAmount: total,
                installmentAmount: installment,
                frequency: frequency,
                dayOfMonth: dayOfMonth,
                startDate: startDate,
                totalInstallments: calculatedInstallments,
                recurringDescription: recurringDescription,
                account: selectedAccount,
                category: selectedCategory,
                splitMembers: members
            )
            modelContext.insert(payment)
        } else {
            let members = isSplit ? splitMembers : []
            let payment = RecurringPayment(
                name: name.trimmingCharacters(in: .whitespaces),
                planType: .subscription,
                installmentAmount: installment,
                frequency: frequency,
                dayOfMonth: dayOfMonth,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                recurringDescription: recurringDescription,
                account: selectedAccount,
                category: selectedCategory,
                splitMembers: members
            )
            modelContext.insert(payment)
        }

        dismiss()
    }
}

#Preview {
    AddRecurringPaymentView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self, RecurringPayment.self])
}
