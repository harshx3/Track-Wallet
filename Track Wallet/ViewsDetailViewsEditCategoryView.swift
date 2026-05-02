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
                    
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(category.type.rawValue)
                            .foregroundStyle(.secondary)
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
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = category.name
                selectedColor = category.color
                selectedIcon = category.icon
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
