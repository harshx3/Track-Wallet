//
//  MonthlyReportView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 5/9/26.
//

import SwiftUI
import SwiftData

struct MonthlyReportView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query(sort: \Account.name) private var accounts: [Account]
    @Query private var recurringPayments: [RecurringPayment]

    @State private var selectedMonth = Date()
    @State private var exportFileURL: URL?
    @State private var showingShareSheet = false
    @State private var showingNoDataAlert = false
    @State private var showingExportError = false
    @State private var exportErrorMessage = ""

    private enum ExportType {
        case csv, pdf
    }

    private var monthTransactions: [Transaction] {
        let calendar = Calendar.current
        return allTransactions.filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }

    private var totalIncome: Decimal {
        monthTransactions.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var totalExpenses: Decimal {
        monthTransactions.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var netSavings: Decimal {
        totalIncome - totalExpenses
    }

    private var categoryBreakdown: [(name: String, icon: String, color: String, amount: Decimal, percentage: Double)] {
        let expenses = monthTransactions.filter { $0.type == .expense && $0.category != nil }
        let grouped = Dictionary(grouping: expenses) { $0.category!.id }
        guard totalExpenses > 0 else { return [] }

        return grouped.compactMap { _, txns -> (String, String, String, Decimal, Double)? in
            guard let cat = txns.first?.category else { return nil }
            let amount = txns.reduce(Decimal(0)) { $0 + $1.amount }
            let pct = Double(truncating: (amount / totalExpenses) as NSDecimalNumber)
            return (cat.name, cat.icon, cat.color, amount, pct.isFinite ? pct : 0)
        }.sorted { $0.3 > $1.3 }
    }

    private var topTransactions: [Transaction] {
        monthTransactions
            .filter { $0.type == .expense }
            .sorted { $0.amount > $1.amount }
    }

    var body: some View {
        List {
            monthPickerSection
            summarySection

            if !categoryBreakdown.isEmpty {
                categorySection
            }

            if !topTransactions.isEmpty {
                topTransactionsSection
            }

            exportSection
        }
        .navigationTitle("Reports")
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportFileURL {
                ShareSheetView(items: [url])
            }
        }
        .alert("No Data", isPresented: $showingNoDataAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("There are no transactions for the selected month.")
        }
        .alert("Export Failed", isPresented: $showingExportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportErrorMessage)
        }
    }

    // MARK: - Month Picker

    @ViewBuilder
    private var monthPickerSection: some View {
        Section {
            HStack {
                Button {
                    shiftMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(AppTypography.headlineLarge)

                Spacer()

                Button {
                    shiftMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundColor(canGoForward ? AppTheme.primary : AppTheme.textTertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canGoForward)
            }
            .padding(.vertical, AppSpacing.xs)
        }
        .listRowBackground(Color.clear)
    }

    private var canGoForward: Bool {
        let calendar = Calendar.current
        return !calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    private func shiftMonth(by value: Int) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: selectedMonth)
        components.day = 1
        guard let normalized = calendar.date(from: components),
              let shifted = calendar.date(byAdding: .month, value: value, to: normalized) else { return }

        if value > 0 {
            let now = Date()
            if calendar.isDate(shifted, equalTo: now, toGranularity: .month) || shifted < now {
                selectedMonth = shifted
            }
        } else {
            selectedMonth = shifted
        }
    }

    // MARK: - Summary

    @ViewBuilder
    private var summarySection: some View {
        Section {
            ReportStatRow(title: "Income", amount: totalIncome, color: AppTheme.income, icon: "arrow.down.circle.fill")
            ReportStatRow(title: "Expenses", amount: totalExpenses, color: AppTheme.expense, icon: "arrow.up.circle.fill")

            HStack {
                Image(systemName: netSavings >= 0 ? "plus.circle.fill" : "minus.circle.fill")
                    .foregroundColor(netSavings >= 0 ? AppTheme.income : AppTheme.expense)
                Text(netSavings >= 0 ? "Saved" : "Over Budget")
                    .font(AppTypography.bodyEmphasized)
                Spacer()
                Text(abs(netSavings).currencyFormatted)
                    .font(AppTypography.amountSmall)
                    .foregroundColor(netSavings >= 0 ? AppTheme.income : AppTheme.expense)
            }
            .padding(.vertical, 2)

            HStack {
                Image(systemName: "list.number")
                    .foregroundColor(AppTheme.textSecondary)
                Text("Transactions")
                    .font(AppTypography.body)
                Spacer()
                Text("\(monthTransactions.count)")
                    .font(AppTypography.bodyEmphasized)
                    .foregroundColor(AppTheme.textSecondary)
            }
        } header: {
            Text("Summary")
        }
    }

    // MARK: - Category Breakdown

    @ViewBuilder
    private var categorySection: some View {
        Section {
            ForEach(categoryBreakdown, id: \.0) { item in
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: item.1)
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6).fill(item.2.toColor))

                    Text(item.0)
                        .font(AppTypography.body)

                    Spacer()

                    Text("\(Int(item.4 * 100))%")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 36, alignment: .trailing)

                    Text(item.3.currencyFormatted)
                        .font(AppTypography.bodyEmphasized)
                        .foregroundColor(AppTheme.expense)
                        .frame(minWidth: 60, alignment: .trailing)
                }
            }
        } header: {
            Text("Spending by Category")
        }
    }

    // MARK: - Top Transactions

    @ViewBuilder
    private var topTransactionsSection: some View {
        Section {
            ForEach(topTransactions.prefix(10)) { transaction in
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: transaction.category?.icon ?? "arrow.up.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.expense))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.category?.name ?? "Expense")
                            .font(AppTypography.body)
                            .lineLimit(1)
                        Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()

                    Text(transaction.amount.currencyFormatted)
                        .font(AppTypography.bodyEmphasized)
                        .foregroundColor(AppTheme.expense)
                }
            }
        } header: {
            Text("Top Expenses")
        }
    }

    // MARK: - Export

    @ViewBuilder
    private var exportSection: some View {
        Section {
            Button {
                exportFile(.csv)
            } label: {
                Label("Export CSV", systemImage: "tablecells")
                    .foregroundColor(AppTheme.primary)
            }

            Button {
                exportFile(.pdf)
            } label: {
                Label("Export PDF", systemImage: "doc.richtext")
                    .foregroundColor(AppTheme.primary)
            }
        } header: {
            Text("Export")
        } footer: {
            Text("Share your monthly financial report.")
        }
    }

    private func exportFile(_ type: ExportType) {
        guard !monthTransactions.isEmpty else {
            showingNoDataAlert = true
            return
        }

        let url: URL?
        switch type {
        case .csv: url = createCSVFile()
        case .pdf: url = createPDFFile()
        }

        guard let fileURL = url, validateFile(at: fileURL) else {
            exportErrorMessage = "Could not create the \(type == .csv ? "CSV" : "PDF") file. Please try again."
            showingExportError = true
            return
        }

        exportFileURL = fileURL
        showingShareSheet = true
    }

    private func validateFile(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? UInt64, size > 0 else { return false }
        return true
    }

    private var monthFileName: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedMonth)
        let month = calendar.component(.month, from: selectedMonth)
        return String(format: "%d-%02d", year, month)
    }

    // MARK: - CSV

    private func csvQuote(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }

    private func createCSVFile() -> URL? {
        var csv = "Date,Type,Category,Account,Amount,Description\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.locale = Locale(identifier: "en_US_POSIX")

        for txn in monthTransactions.sorted(by: { $0.date < $1.date }) {
            let date = dateFormatter.string(from: txn.date)
            let type = txn.type.rawValue
            let category = csvQuote(txn.category?.name ?? "")
            let account = csvQuote(txn.fromAccount?.name ?? "")
            let amount = numberFormatter.string(from: txn.amount as NSDecimalNumber) ?? "\(txn.amount)"
            let desc = csvQuote(txn.transactionDescription)
            csv += "\(date),\(type),\(category),\(account),\(amount),\(desc)\n"
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("WalletFlows_Report_\(monthFileName).csv")
        try? FileManager.default.removeItem(at: url)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - PDF

    @MainActor
    private func createPDFFile() -> URL? {
        let reportContent = PDFReportContent(
            month: selectedMonth.formatted(.dateTime.month(.wide).year()),
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netSavings: netSavings,
            transactionCount: monthTransactions.count,
            categoryBreakdown: categoryBreakdown.map { ($0.0, $0.3, $0.4) },
            topTransactions: topTransactions.prefix(10).map { ($0.category?.name ?? "Expense", $0.amount, $0.date) }
        )

        let renderer = ImageRenderer(content: reportContent.frame(width: 595))
        renderer.scale = 2.0

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("WalletFlows_Report_\(monthFileName).pdf")
        try? FileManager.default.removeItem(at: url)

        renderer.render { size, context in
            guard size.width > 0, size.height > 0 else { return }
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }

        return url
    }
}

// MARK: - Report Stat Row

struct ReportStatRow: View {
    let title: String
    let amount: Decimal
    let color: Color
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(AppTypography.body)
            Spacer()
            Text(amount.currencyFormatted)
                .font(AppTypography.bodyEmphasized)
                .foregroundColor(color)
        }
    }
}

// MARK: - PDF Report Content

struct PDFReportContent: View {
    let month: String
    let totalIncome: Decimal
    let totalExpenses: Decimal
    let netSavings: Decimal
    let transactionCount: Int
    let categoryBreakdown: [(String, Decimal, Double)]
    let topTransactions: [(String, Decimal, Date)]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Wallet Flows")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("Monthly Report — \(month)")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)

            Divider()

            HStack(spacing: 24) {
                PDFStatBox(title: "Income", value: totalIncome.currencyFormatted, color: .green)
                PDFStatBox(title: "Expenses", value: totalExpenses.currencyFormatted, color: .red)
                PDFStatBox(title: netSavings >= 0 ? "Saved" : "Over", value: abs(netSavings).currencyFormatted, color: netSavings >= 0 ? .green : .red)
                PDFStatBox(title: "Transactions", value: "\(transactionCount)", color: .blue)
            }

            if !categoryBreakdown.isEmpty {
                Text("Spending by Category")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)

                ForEach(categoryBreakdown.prefix(8), id: \.0) { item in
                    HStack {
                        Text(item.0)
                            .font(.system(size: 13))
                        Spacer()
                        Text("\(Int(item.2 * 100))%")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 36, alignment: .trailing)
                        Text(item.1.currencyFormatted)
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }

            if !topTransactions.isEmpty {
                Divider()

                Text("Top Expenses")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)

                ForEach(topTransactions.indices, id: \.self) { i in
                    let item = topTransactions[i]
                    HStack {
                        Text(item.0)
                            .font(.system(size: 13))
                        Spacer()
                        Text(item.2.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(item.1.currencyFormatted)
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }

            Divider()

            Text("Generated by Wallet Flows \u{2022} \(Date().formatted(date: .abbreviated, time: .shortened))")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(40)
        .background(.white)
    }
}

struct PDFStatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Share Sheet

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        MonthlyReportView()
    }
    .modelContainer(for: [Transaction.self, Account.self, Category.self, RecurringPayment.self])
}
