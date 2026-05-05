//
//  IconPicker.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 5/4/26.
//

import SwiftUI

struct IconGroup: Identifiable {
    let id = UUID()
    let name: String
    let icons: [String]
}

struct AppIcons {
    static let allGroups: [IconGroup] = [
        IconGroup(name: "Finance", icons: [
            "dollarsign.circle.fill", "banknote.fill", "creditcard.fill",
            "building.columns.fill", "wallet.pass.fill", "chart.line.uptrend.xyaxis",
            "chart.bar.fill", "chart.pie.fill", "percent",
            "indianrupeesign.circle.fill", "eurosign.circle.fill", "sterlingsign.circle.fill",
            "yensign.circle.fill", "bitcoinsign.circle.fill"
        ]),
        IconGroup(name: "Shopping", icons: [
            "cart.fill", "bag.fill", "basket.fill", "storefront.fill",
            "gift.fill", "shippingbox.fill", "tag.fill", "barcode"
        ]),
        IconGroup(name: "Food & Drink", icons: [
            "fork.knife", "cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill",
            "wineglass.fill", "birthday.cake.fill", "carrot.fill",
            "mug.fill", "waterbottle.fill"
        ]),
        IconGroup(name: "Transport", icons: [
            "car.fill", "bus.fill", "tram.fill", "airplane",
            "bicycle", "fuelpump.fill", "ferry.fill", "scooter"
        ]),
        IconGroup(name: "Home", icons: [
            "house.fill", "bed.double.fill", "sofa.fill", "lightbulb.fill",
            "washer.fill", "fan.fill", "wifi.router.fill", "key.fill"
        ]),
        IconGroup(name: "Health", icons: [
            "heart.fill", "cross.case.fill", "pills.fill", "stethoscope",
            "brain.head.profile.fill", "figure.run", "dumbbell.fill", "figure.yoga"
        ]),
        IconGroup(name: "Education", icons: [
            "book.fill", "graduationcap.fill", "pencil.and.ruler.fill", "backpack.fill",
            "text.book.closed.fill", "globe.americas.fill", "puzzlepiece.fill", "brain.fill"
        ]),
        IconGroup(name: "Entertainment", icons: [
            "music.note", "gamecontroller.fill", "film.fill", "tv.fill",
            "headphones", "theatermasks.fill", "sportscourt.fill", "ticket.fill",
            "popcorn.fill", "play.rectangle.fill"
        ]),
        IconGroup(name: "Travel", icons: [
            "suitcase.fill", "map.fill", "camera.fill", "binoculars.fill",
            "mountain.2.fill", "beach.umbrella.fill", "tent.fill", "globe.europe.africa.fill"
        ]),
        IconGroup(name: "Tech", icons: [
            "desktopcomputer", "laptopcomputer", "iphone", "applewatch",
            "printer.fill", "wifi", "antenna.radiowaves.left.and.right", "server.rack"
        ]),
        IconGroup(name: "Work", icons: [
            "briefcase.fill", "folder.fill", "doc.text.fill", "paperclip",
            "calendar", "clock.fill", "person.2.fill", "building.2.fill"
        ]),
        IconGroup(name: "Lifestyle", icons: [
            "sparkles", "tshirt.fill", "eyeglasses", "paintbrush.fill",
            "scissors", "comb.fill", "pawprint.fill", "leaf.fill",
            "flame.fill", "snowflake", "star.fill", "moon.fill"
        ]),
        IconGroup(name: "Bills", icons: [
            "phone.fill", "envelope.fill", "drop.fill", "bolt.fill",
            "antenna.radiowaves.left.and.right", "shield.fill", "wrench.fill",
            "hammer.fill"
        ])
    ]

    static let allIcons: [String] = allGroups.flatMap { $0.icons }

    static let categoryIcons: [String] = [
        "folder.fill", "cart.fill", "house.fill", "car.fill",
        "fork.knife", "gamecontroller.fill", "gift.fill", "heart.fill",
        "music.note", "book.fill", "graduationcap.fill", "airplane",
        "cross.case.fill", "sparkles", "tshirt.fill", "cup.and.saucer.fill",
        "bag.fill", "briefcase.fill", "film.fill", "tv.fill",
        "bus.fill", "fuelpump.fill", "lightbulb.fill", "wifi",
        "phone.fill", "bolt.fill", "drop.fill", "flame.fill",
        "pills.fill", "figure.run", "camera.fill", "paintbrush.fill",
        "pawprint.fill", "leaf.fill", "star.fill", "tag.fill",
        "doc.text.fill", "envelope.fill", "wrench.fill", "dumbbell.fill",
        "birthday.cake.fill", "popcorn.fill", "ticket.fill", "headphones",
        "creditcard.fill", "banknote.fill", "percent", "shield.fill"
    ]

    static let accountIcons: [String] = [
        "dollarsign.circle.fill", "banknote.fill", "building.columns.fill",
        "creditcard.fill", "wallet.pass.fill", "chart.line.uptrend.xyaxis",
        "briefcase.fill", "bag.fill", "chart.bar.fill", "chart.pie.fill",
        "building.2.fill", "lock.fill", "key.fill", "star.fill",
        "globe.americas.fill", "person.fill"
    ]
}

struct IconPickerView: View {
    @Binding var selectedIcon: String
    let accentColor: Color
    let icons: [IconGroup]

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    var filteredGroups: [IconGroup] {
        if searchText.isEmpty { return icons }
        let query = searchText.lowercased()
        return icons.compactMap { group in
            let matched = group.icons.filter { $0.lowercased().contains(query) || group.name.lowercased().contains(query) }
            return matched.isEmpty ? nil : IconGroup(name: group.name, icons: matched)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ForEach(filteredGroups) { group in
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(group.name)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(.horizontal, AppSpacing.md)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 10) {
                                ForEach(group.icons, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                        dismiss()
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.title3)
                                            .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                            .frame(width: 48, height: 48)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(selectedIcon == icon ? accentColor : Color(.systemGray5))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                        }
                    }
                }
                .padding(.vertical, AppSpacing.md)
            }
            .searchable(text: $searchText, prompt: "Search icons")
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct IconPickerButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Icon")
                        .font(AppTypography.body)
                        .foregroundStyle(.primary)
                    Text("Tap to change")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
