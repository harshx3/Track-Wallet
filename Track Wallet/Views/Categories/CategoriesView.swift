//
//  CategoriesView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    
    @State private var showingAddCategory = false
    @State private var selectedCategory: Category?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if categories.isEmpty {
                        ContentUnavailableView(
                            "No Categories",
                            systemImage: "folder.fill",
                            description: Text("Create categories to organize your transactions")
                        )
                        .frame(height: 400)
                    } else {
                        ForEach(categories) { category in
                            CategoryCard(category: category)
                                .onTapGesture {
                                    selectedCategory = category
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteCategory(category)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Categories")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
            .sheet(item: $selectedCategory) { category in
                EditCategoryView(category: category)
            }
        }
    }
    
    private func deleteCategory(_ category: Category) {
        withAnimation {
            modelContext.delete(category)
        }
    }
}

struct CategoryCard: View {
    let category: Category
    
    var transactionCount: Int {
        category.transactions?.count ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.2))
                    )
                
                Spacer()
                
                Menu {
                    Text(category.type.rawValue)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(category.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                HStack(spacing: 4) {
                    Text("\(transactionCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("txns")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            category.color.toColor.opacity(0.8),
                            category.color.toColor.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: category.color.toColor.opacity(0.3), radius: 15, y: 8)
    }
}

#Preview {
    CategoriesView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self])
}
