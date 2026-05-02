//
//  AddCategoryView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var categoryType: TransactionType = .expense
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "folder.fill"
    
    let colors = ["blue", "green", "orange", "red", "purple", "pink", "indigo", "teal"]
    let icons = [
        "folder.fill", "cart.fill", "house.fill", "car.fill",
        "fork.knife", "gamecontroller.fill", "gift.fill", "heart.fill",
        "music.note", "book.fill", "graduationcap.fill", "airplane",
        "cross.case.fill", "sparkles", "tshirt.fill", "cup.and.saucer.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $name)
                    
                    Picker("Type", selection: $categoryType) {
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
                    }
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedIcon == icon ? selectedColor.toColor : Color(.systemGray5))
                                )
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { color in
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
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveCategory() {
        let category = Category(
            name: name,
            icon: selectedIcon,
            color: selectedColor,
            type: categoryType
        )
        
        modelContext.insert(category)
        dismiss()
    }
}

#Preview {
    AddCategoryView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self])
}
