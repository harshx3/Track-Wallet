//
//  DebtsView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct DebtsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Debt.date, order: .reverse) private var debts: [Debt]

    @State private var showingAddDebt = false
    @State private var filterType: DebtFilterType = .active

    var allGroupsByPerson: [PersonDebtGroup] {
        let grouped = Dictionary(grouping: debts) {
            $0.personName.trimmingCharacters(in: .whitespaces).lowercased()
        }
        return grouped.map { _, personDebts in
            PersonDebtGroup(
                personName: personDebts.first?.personName ?? "",
                debts: personDebts.sorted { $0.date > $1.date }
            )
        }.sorted { $0.personName.lowercased() < $1.personName.lowercased() }
    }

    var displayGroups: [PersonDebtGroup] {
        switch filterType {
        case .all:
            return allGroupsByPerson
        case .active:
            return allGroupsByPerson.filter { $0.activeCount > 0 && !$0.isNetSettled }
        case .lending:
            return allGroupsByPerson.filter { $0.netBalance > 0 }
        case .borrowing:
            return allGroupsByPerson.filter { $0.netBalance < 0 }
        case .settled:
            return allGroupsByPerson.filter { group in
                group.isNetSettled || (group.activeCount == 0 && group.debts.contains { $0.isPaid })
            }
        }
    }

    var netReceivable: Decimal {
        allGroupsByPerson.reduce(Decimal(0)) { $0 + max(0, $1.netBalance) }
    }

    var netPayable: Decimal {
        allGroupsByPerson.reduce(Decimal(0)) { $0 + max(0, -$1.netBalance) }
    }

    var body: some View {
        NavigationStack {
            List {
                if netReceivable > 0 || netPayable > 0 {
                    Section {
                        if netReceivable > 0 {
                            HStack {
                                Label("You'll Receive", systemImage: "arrow.up.circle.fill")
                                    .foregroundColor(AppTheme.transfer)
                                Spacer()
                                Text(netReceivable.currencyFormatted)
                                    .font(AppTypography.bodyEmphasized)
                                    .foregroundColor(AppTheme.transfer)
                            }
                        }
                        if netPayable > 0 {
                            HStack {
                                Label("You Owe", systemImage: "arrow.down.circle.fill")
                                    .foregroundColor(AppTheme.expense)
                                Spacer()
                                Text(netPayable.currencyFormatted)
                                    .font(AppTypography.bodyEmphasized)
                                    .foregroundColor(AppTheme.expense)
                            }
                        }
                        if netReceivable > 0 && netPayable > 0 {
                            let overall = netReceivable - netPayable
                            HStack {
                                Label("Net Balance", systemImage: "equal.circle.fill")
                                    .foregroundColor(overall > 0 ? AppTheme.transfer : overall < 0 ? AppTheme.expense : AppTheme.income)
                                Spacer()
                                Text(overall > 0 ? "+\(overall.currencyFormatted)" : abs(overall).currencyFormatted)
                                    .font(AppTypography.bodyEmphasized)
                                    .foregroundColor(overall > 0 ? AppTheme.transfer : AppTheme.expense)
                            }
                        }
                    } header: {
                        Text("Summary")
                    }
                }

                Section {
                    Picker("Filter", selection: $filterType) {
                        ForEach(DebtFilterType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                if displayGroups.isEmpty {
                    ContentUnavailableView(
                        emptyStateTitle,
                        systemImage: emptyStateIcon,
                        description: Text(emptyStateDescription)
                    )
                } else {
                    Section {
                        ForEach(displayGroups) { group in
                            NavigationLink(destination: PersonDebtsDetailView(personName: group.personName)) {
                                PersonDebtRow(group: group)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Debts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddDebt = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDebt) {
                AddDebtView()
            }
        }
    }

    private var emptyStateTitle: String {
        switch filterType {
        case .all: return "No Debts"
        case .lending: return "No Active Lending"
        case .borrowing: return "No Active Borrowing"
        case .active: return "No Active Debts"
        case .settled: return "No Settled Debts"
        }
    }

    private var emptyStateIcon: String {
        switch filterType {
        case .all, .active: return "person.2"
        case .lending: return "arrow.up.circle"
        case .borrowing: return "arrow.down.circle"
        case .settled: return "checkmark.circle"
        }
    }

    private var emptyStateDescription: String {
        switch filterType {
        case .all: return "Track money you lend or borrow"
        case .lending: return "No money lent to others"
        case .borrowing: return "No money borrowed from others"
        case .active: return "All debts are settled"
        case .settled: return "No settled transactions yet"
        }
    }
}

// MARK: - Person Debt Group

struct PersonDebtGroup: Identifiable {
    var id: String { personName.lowercased() }
    let personName: String
    let debts: [Debt]

    var totalLending: Decimal {
        debts.filter { $0.type == .lending && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
    }

    var totalBorrowing: Decimal {
        debts.filter { $0.type == .borrowing && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
    }

    var netBalance: Decimal {
        totalLending - totalBorrowing
    }

    var isNetSettled: Bool {
        netBalance == 0 && (totalLending > 0 || totalBorrowing > 0)
    }

    var activeCount: Int {
        debts.filter { !$0.isPaid }.count
    }

    var hasLending: Bool {
        debts.contains { $0.type == .lending && !$0.isPaid }
    }

    var hasBorrowing: Bool {
        debts.contains { $0.type == .borrowing && !$0.isPaid }
    }
}

// MARK: - Person Debt Row

struct PersonDebtRow: View {
    let group: PersonDebtGroup

    private var avatarColor: Color {
        if group.isNetSettled { return AppTheme.income }
        if group.netBalance > 0 { return AppTheme.transfer }
        if group.netBalance < 0 { return AppTheme.expense }
        return AppTheme.primary
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 36, height: 36)

                Text(String(group.personName.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(group.personName)
                        .font(AppTypography.body)

                    if group.activeCount > 1 {
                        Text("\(group.activeCount)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(AppTheme.textSecondary))
                    }
                }

                if group.isNetSettled {
                    Text("Settled")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.income)
                } else {
                    HStack(spacing: 8) {
                        if group.hasLending {
                            Text("Lent \(group.totalLending.currencyFormatted)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppTheme.transfer)
                        }
                        if group.hasBorrowing {
                            Text("Owe \(group.totalBorrowing.currencyFormatted)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppTheme.expense)
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if group.isNetSettled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.income)
                } else if group.netBalance > 0 {
                    Text("+\(group.netBalance.currencyFormatted)")
                        .font(AppTypography.bodyEmphasized)
                        .foregroundColor(AppTheme.transfer)
                    Text("to receive")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                } else if group.netBalance < 0 {
                    Text(abs(group.netBalance).currencyFormatted)
                        .font(AppTypography.bodyEmphasized)
                        .foregroundColor(AppTheme.expense)
                    Text("to pay")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Person Debts Detail View

struct PersonDebtsDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let personName: String
    @Query(sort: \Debt.date, order: .reverse) private var allDebts: [Debt]
    @State private var showingAddEntry = false

    init(personName: String) {
        self.personName = personName
    }

    var personDebts: [Debt] {
        allDebts.filter {
            $0.personName.trimmingCharacters(in: .whitespaces).lowercased() == personName.trimmingCharacters(in: .whitespaces).lowercased()
        }
    }

    var activeDebts: [Debt] {
        personDebts.filter { !$0.isPaid }
    }

    var settledDebts: [Debt] {
        personDebts.filter { $0.isPaid }
    }

    var totalLending: Decimal {
        personDebts.filter { $0.type == .lending && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
    }

    var totalBorrowing: Decimal {
        personDebts.filter { $0.type == .borrowing && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
    }

    var netBalance: Decimal {
        totalLending - totalBorrowing
    }

    var body: some View {
        List {
            Section {
                if totalLending > 0 {
                    HStack {
                        Label("You'll Receive", systemImage: "arrow.up.circle.fill")
                            .foregroundColor(AppTheme.transfer)
                        Spacer()
                        Text(totalLending.currencyFormatted)
                            .font(AppTypography.bodyEmphasized)
                            .foregroundColor(AppTheme.transfer)
                    }
                }
                if totalBorrowing > 0 {
                    HStack {
                        Label("You Owe", systemImage: "arrow.down.circle.fill")
                            .foregroundColor(AppTheme.expense)
                        Spacer()
                        Text(totalBorrowing.currencyFormatted)
                            .font(AppTypography.bodyEmphasized)
                            .foregroundColor(AppTheme.expense)
                    }
                }
                if totalLending > 0 && totalBorrowing > 0 {
                    HStack {
                        Label(netBalance == 0 ? "Net: Settled" : "Net Balance",
                              systemImage: netBalance == 0 ? "checkmark.circle.fill" : "equal.circle.fill")
                            .foregroundColor(netBalance == 0 ? AppTheme.income : netBalance > 0 ? AppTheme.transfer : AppTheme.expense)
                        Spacer()
                        if netBalance != 0 {
                            Text(netBalance > 0 ? "+\(netBalance.currencyFormatted)" : abs(netBalance).currencyFormatted)
                                .font(AppTypography.bodyEmphasized)
                                .foregroundColor(netBalance > 0 ? AppTheme.transfer : AppTheme.expense)
                        }
                    }
                }
                if totalLending == 0 && totalBorrowing == 0 {
                    HStack {
                        Text("All Settled")
                            .foregroundColor(AppTheme.income)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.income)
                    }
                }
            } header: {
                Text("Summary")
            }

            if !activeDebts.isEmpty {
                Section {
                    ForEach(activeDebts) { debt in
                        NavigationLink(destination: DebtDetailView(debt: debt)) {
                            DebtEntryRow(debt: debt)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(debt)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                debt.isPaid = true
                            } label: {
                                Label("Settle", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                    }
                } header: {
                    Text("Active (\(activeDebts.count))")
                }
            }

            if !settledDebts.isEmpty {
                Section {
                    ForEach(settledDebts) { debt in
                        NavigationLink(destination: DebtDetailView(debt: debt)) {
                            DebtEntryRow(debt: debt)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(debt)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                debt.isPaid = false
                            } label: {
                                Label("Reactivate", systemImage: "arrow.counterclockwise")
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    Text("Settled (\(settledDebts.count))")
                }
            }

            Section {
                Button {
                    showingAddEntry = true
                } label: {
                    Label("Add Entry", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle(personName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddEntry) {
            AddDebtView(existingPersonName: personName)
        }
    }
}

// MARK: - Debt Entry Row

struct DebtEntryRow: View {
    let debt: Debt

    var typeColor: Color {
        debt.type == .lending ? AppTheme.transfer : AppTheme.expense
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: debt.type.icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(typeColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(debt.type.rawValue)
                        .font(AppTypography.body)

                    if debt.isPaid {
                        Text("Settled")
                            .font(.caption2)
                            .foregroundColor(AppTheme.income)
                    }
                }

                HStack(spacing: 8) {
                    Text(debt.date.formatted(date: .abbreviated, time: .omitted))
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    if let dueDate = debt.dueDate {
                        Text("Due \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(AppTypography.caption)
                            .foregroundColor(dueDate < Date() && !debt.isPaid ? AppTheme.expense : AppTheme.textSecondary)
                    }
                }

                if let account = debt.account {
                    Text(debt.type == .lending ? "From: \(account.name)" : "To: \(account.name)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.primary)
                        .lineLimit(1)
                }

                if !debt.debtDescription.isEmpty {
                    Text(debt.debtDescription)
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(debt.remainingAmount.currencyFormatted)
                    .font(AppTypography.bodyEmphasized)
                    .foregroundColor(debt.isPaid ? AppTheme.income : typeColor)

                if debt.remainingAmount != debt.amount {
                    Text("of \(debt.amount.currencyFormatted)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .opacity(debt.isPaid ? 0.6 : 1.0)
    }
}

// MARK: - Filter

enum DebtFilterType: String, CaseIterable {
    case active = "Active"
    case lending = "Lent"
    case borrowing = "Owed"
    case settled = "Settled"
    case all = "All"
}

#Preview {
    DebtsView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self])
}
