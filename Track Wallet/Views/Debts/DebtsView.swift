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

    var filteredDebts: [Debt] {
        switch filterType {
        case .all: return debts
        case .lending: return debts.filter { $0.type == .lending && !$0.isPaid }
        case .borrowing: return debts.filter { $0.type == .borrowing && !$0.isPaid }
        case .active: return debts.filter { !$0.isPaid }
        case .settled: return debts.filter { $0.isPaid }
        }
    }

    var groupedByPerson: [PersonDebtGroup] {
        let grouped = Dictionary(grouping: filteredDebts) { $0.personName.trimmingCharacters(in: .whitespaces).lowercased() }
        return grouped.map { _, personDebts in
            PersonDebtGroup(
                personName: personDebts.first?.personName ?? "",
                debts: personDebts.sorted { $0.date > $1.date }
            )
        }.sorted { $0.personName.lowercased() < $1.personName.lowercased() }
    }

    var totalLending: Decimal {
        debts.filter { $0.type == .lending && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
    }

    var totalBorrowing: Decimal {
        debts.filter { $0.type == .borrowing && !$0.isPaid }.reduce(Decimal(0)) { $0 + $1.remainingAmount }
    }

    var body: some View {
        NavigationStack {
            List {
                if totalLending > 0 || totalBorrowing > 0 {
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

                if groupedByPerson.isEmpty {
                    ContentUnavailableView(
                        emptyStateTitle,
                        systemImage: emptyStateIcon,
                        description: Text(emptyStateDescription)
                    )
                } else {
                    Section {
                        ForEach(groupedByPerson) { group in
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

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(group.hasLending && !group.hasBorrowing ? AppTheme.transfer :
                          group.hasBorrowing && !group.hasLending ? AppTheme.expense :
                          AppTheme.primary)
                    .frame(width: 36, height: 36)

                Text(String(group.personName.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(group.personName)
                        .font(AppTypography.body)

                    if group.debts.count > 1 {
                        Text("\(group.debts.count)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(AppTheme.textSecondary))
                    }
                }

                HStack(spacing: 8) {
                    if group.hasLending {
                        Text("Lending")
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.transfer)
                    }
                    if group.hasBorrowing {
                        Text("Borrowing")
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.expense)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if group.totalLending > 0 {
                    Text(group.totalLending.currencyFormatted)
                        .font(AppTypography.bodyEmphasized)
                        .foregroundColor(AppTheme.transfer)
                }
                if group.totalBorrowing > 0 {
                    Text(group.totalBorrowing.currencyFormatted)
                        .font(AppTypography.bodyEmphasized)
                        .foregroundColor(AppTheme.expense)
                }
            }
        }
    }
}

// MARK: - Person Debts Detail View

struct PersonDebtsDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let personName: String
    @Query private var personDebts: [Debt]
    @State private var showingAddEntry = false

    init(personName: String) {
        self.personName = personName
        let name = personName
        _personDebts = Query(
            filter: #Predicate<Debt> { $0.personName == name },
            sort: \Debt.date,
            order: .reverse
        )
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
