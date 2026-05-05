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
    @State private var showingIconPicker = false
    @State private var customColor = Color.blue

    let colors = String.namedColors

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Category Name", text: $name)

                    Picker("Type", selection: $categoryType) {
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
                    }
                } header: {
                    Text("Category Details")
                }

                Section {
                    IconPickerButton(
                        icon: selectedIcon,
                        color: selectedColor.toColor,
                        action: { showingIconPicker = true }
                    )

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 10) {
                        ForEach(AppIcons.categoryIcons.prefix(24), id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                .frame(width: 48, height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedIcon == icon ? selectedColor.toColor : Color(.systemGray5))
                                )
                                .onTapGesture {
                                    selectedIcon = icon
                                }
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

                    ColorPicker("Custom Color", selection: $customColor, supportsOpacity: false)
                        .onChange(of: customColor) { _, newColor in
                            selectedColor = newColor.hexString
                        }
                } header: {
                    Text("Color")
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCategory() }
                        .disabled(name.isEmpty)
                        .fontWeight(.semibold)
                }
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
