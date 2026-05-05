//
//  EditCategoryView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

struct EditCategoryView: View {
    @Environment(\.dismiss) private var dismiss

    let category: Category

    @State private var name = ""
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

                    HStack {
                        Text("Type")
                        Spacer()
                        Text(category.type.rawValue)
                            .foregroundStyle(.secondary)
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
            .navigationTitle("Edit Category")
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
            }
            .onAppear {
                name = category.name
                selectedColor = category.color
                selectedIcon = category.icon
                customColor = category.color.toColor
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
        category.name = name
        category.icon = selectedIcon
        category.color = selectedColor
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Category.self, configurations: config)

    let category = Category(name: "Food", icon: "fork.knife", color: "orange")
    container.mainContext.insert(category)

    return EditCategoryView(category: category)
        .modelContainer(container)
}
