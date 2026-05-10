//
//  BudgetsView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 5/9/26.
//

import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var selectedCategory: Category?

    var expenseCategories: [Category] {
        categories.filter { $0.type == .expense }
    }

    var budgetCategories: [Category] {
        expenseCategories.filter { $0.monthlyBudget > 0 }
    }

    var unbudgetedCategories: [Category] {
        expenseCategories.filter { $0.monthlyBudget <= 0 }
    }

    var totalBudget: Decimal {
        budgetCategories.reduce(Decimal(0)) { $0 + $1.monthlyBudget }
    }

    var totalSpent: Decimal {
        budgetCategories.reduce(Decimal(0)) { $0 + $1.spentThisMonth() }
    }

    var overallProgress: Double {
        guard totalBudget > 0 else { return 0 }
        let value = Double(truncating: (totalSpent / totalBudget) as NSDecimalNumber)
        return value.isFinite ? min(2.0, max(0, value)) : 0
    }

    var body: some View {
        NavigationStack {
            List {
                if budgetCategories.isEmpty {
                    ContentUnavailableView {
                        Label("No Budgets Set", systemImage: "gauge.with.dots.needle.33percent")
                    } description: {
                        Text("Set monthly limits on your expense categories to track spending.")
                    }
                } else {
                    Section {
                        VStack(spacing: AppSpacing.sm) {
                            HStack {
                                Text("Total Budget")
                                    .font(AppTypography.body)
                                Spacer()
                                Text("\(totalSpent.currencyFormatted) of \(totalBudget.currencyFormatted)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            ProgressView(value: min(1.0, overallProgress))
                                .tint(overallProgressColor)

                            HStack {
                                Text("\(Int(min(100, overallProgress * 100)))% used")
                                    .font(AppTypography.caption)
                                    .foregroundColor(overallProgressColor)
                                Spacer()
                                let remaining = totalBudget - totalSpent
                                Text(remaining >= 0 ? "\(remaining.currencyFormatted) remaining" : "\(abs(remaining).currencyFormatted) over budget")
                                    .font(AppTypography.caption)
                                    .foregroundColor(remaining >= 0 ? AppTheme.textSecondary : AppTheme.expense)
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)
                    } header: {
                        Text("Overview")
                    }

                    Section {
                        ForEach(budgetCategories.sorted(by: { $0.budgetProgress() > $1.budgetProgress() })) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                BudgetProgressRow(category: category)
                            }
                            .tint(AppTheme.textPrimary)
                        }
                    } header: {
                        Text("Budget Categories")
                    }
                }

                if !unbudgetedCategories.isEmpty {
                    Section {
                        ForEach(unbudgetedCategories) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: category.icon)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(RoundedRectangle(cornerRadius: 6).fill(category.color.toColor))

                                    Text(category.name)
                                        .font(AppTypography.body)
                                        .foregroundColor(AppTheme.textPrimary)

                                    Spacer()

                                    let spent = category.spentThisMonth()
                                    if spent > 0 {
                                        Text("\(spent.currencyFormatted) spent")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }

                                    Text("Set Budget")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppTheme.primary)
                                }
                            }
                        }
                    } header: {
                        Text("Without Budget")
                    } footer: {
                        Text("Tap a category to set a monthly spending limit.")
                    }
                }
            }
            .navigationTitle("Budgets")
            .sheet(item: $selectedCategory) { category in
                EditCategoryView(category: category)
            }
        }
    }

    private var overallProgressColor: Color {
        if overallProgress < 0.7 { return AppTheme.income }
        if overallProgress < 1.0 { return AppTheme.transfer }
        return AppTheme.expense
    }
}

#Preview {
    BudgetsView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self])
}
