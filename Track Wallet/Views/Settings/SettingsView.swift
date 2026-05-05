//
//  SettingsView.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/30/26.
//

import SwiftUI
import SwiftData

// MARK: - Appearance & Text Size Preferences

enum AppAppearance: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

enum AppTextSize: String, CaseIterable {
    case regular = "A"
    case large = "A+"
    case extraLarge = "A++"

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .regular: return .large
        case .large: return .xLarge
        case .extraLarge: return .xxLarge
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    let authManager: AuthenticationManager

    @AppStorage("appAppearance") private var appearance: String = AppAppearance.system.rawValue
    @AppStorage("appTextSize") private var textSize: String = AppTextSize.regular.rawValue

    @State private var showingAbout = false
    @State private var showingSignOutConfirmation = false
    @State private var showingEditProfile = false

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearance) ?? .system
    }

    private var selectedTextSize: AppTextSize {
        AppTextSize(rawValue: textSize) ?? .regular
    }

    var body: some View {
        NavigationStack {
            List {
                // Profile Header
                Section {
                    Button { showingEditProfile = true } label: {
                        HStack(spacing: AppSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.primary, AppTheme.primary.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)

                                Text(String((authManager.userName.isEmpty ? "U" : authManager.userName).prefix(1)).uppercased())
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(authManager.userName.isEmpty ? "Apple ID User" : authManager.userName)
                                    .font(AppTypography.headlineLarge)
                                    .foregroundColor(AppTheme.textPrimary)

                                if !authManager.userEmail.isEmpty {
                                    Text(authManager.userEmail)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textTertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Preferences
                Section {
                    HStack {
                        Label("Appearance", systemImage: selectedAppearance.icon)
                        Spacer()
                        Picker("", selection: $appearance) {
                            ForEach(AppAppearance.allCases, id: \.rawValue) { option in
                                Text(option.rawValue).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.textSecondary)
                    }

                    HStack {
                        Label("Text Size", systemImage: "textformat.size")
                        Spacer()
                        HStack(spacing: 0) {
                            ForEach(AppTextSize.allCases, id: \.rawValue) { size in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        textSize = size.rawValue
                                    }
                                } label: {
                                    Text(size.rawValue)
                                        .font(.system(
                                            size: size == .regular ? 13 : size == .large ? 15 : 17,
                                            weight: selectedTextSize == size ? .bold : .regular
                                        ))
                                        .foregroundColor(selectedTextSize == size ? .white : AppTheme.textSecondary)
                                        .frame(width: 44, height: 32)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedTextSize == size ? AppTheme.primary : Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(2)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.surfaceBackground)
                        )
                    }
                } header: {
                    Text("Preferences")
                }

                // Manage
                Section {
                    NavigationLink {
                        AccountsListView()
                    } label: {
                        Label("Accounts", systemImage: "wallet.pass.fill")
                    }

                    NavigationLink {
                        CategoriesListView()
                    } label: {
                        Label("Categories", systemImage: "folder.fill")
                    }
                } header: {
                    Text("Manage")
                }

                // About
                Section {
                    Button(action: { showingAbout = true }) {
                        Label("About Track Wallet", systemImage: "info.circle")
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                } header: {
                    Text("About")
                }

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        showingSignOutConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .font(AppTypography.bodyEmphasized)
                            Spacer()
                        }
                    }
                } footer: {
                    Text("Your data stays on this device even after signing out.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(authManager: authManager)
            }
            .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out? Your data will remain on this device.")
            }
        }
    }
}

// MARK: - Edit Profile

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let authManager: AuthenticationManager

    @State private var name = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.primary, AppTheme.primary.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Text(String((name.isEmpty ? "U" : name).prefix(1)).uppercased())
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    TextField("Your Name", text: $name)
                        .focused($isNameFocused)

                    if !authManager.userEmail.isEmpty {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(authManager.userEmail)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                } header: {
                    Text("Profile")
                } footer: {
                    if !authManager.userEmail.isEmpty {
                        Text("Email is managed by your Apple ID")
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        authManager.updateProfile(name: name.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isNameFocused = false }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                name = authManager.userName
            }
        }
    }
}

// MARK: - Accounts List (Settings destination)

struct AccountsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.createdAt, order: .reverse) private var accounts: [Account]

    @State private var showingAddAccount = false

    var assetAccounts: [Account] {
        accounts.filter { $0.isAsset }
    }

    var liabilityAccounts: [Account] {
        accounts.filter { !$0.isAsset }
    }

    var body: some View {
        List {
            if accounts.isEmpty {
                ContentUnavailableView(
                    "No Accounts",
                    systemImage: "wallet.pass",
                    description: Text("Add your first account to start tracking")
                )
            } else {
                if !assetAccounts.isEmpty {
                    Section("Assets") {
                        ForEach(assetAccounts) { account in
                            NavigationLink(destination: AccountDetailView(account: account)) {
                                AccountListRow(account: account)
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(assetAccounts[index])
                            }
                        }
                    }
                }

                if !liabilityAccounts.isEmpty {
                    Section("Liabilities") {
                        ForEach(liabilityAccounts) { account in
                            NavigationLink(destination: AccountDetailView(account: account)) {
                                AccountListRow(account: account)
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(liabilityAccounts[index])
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddAccount = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAccountView()
        }
    }
}

struct AccountListRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            AccountIconView(account: account, size: 32, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(AppTypography.body)

                Text(account.type.rawValue)
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Text(account.currentBalance.currencyFormatted)
                .font(AppTypography.bodyEmphasized)
                .foregroundColor(account.isAsset ? AppTheme.income : AppTheme.expense)
        }
    }
}

// MARK: - Categories List (Settings destination)

struct CategoriesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var showingAddCategory = false
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategory: Category?

    var filteredCategories: [Category] {
        categories.filter { $0.type == selectedType }
    }

    var body: some View {
        List {
            Picker("Type", selection: $selectedType) {
                Text("Expense").tag(TransactionType.expense)
                Text("Income").tag(TransactionType.income)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

            if filteredCategories.isEmpty {
                ContentUnavailableView(
                    "No Categories",
                    systemImage: "folder",
                    description: Text("Add a category to organize transactions")
                )
            } else {
                ForEach(filteredCategories) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        CategoryListRow(category: category)
                    }
                    .tint(AppTheme.textPrimary)
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(filteredCategories[index])
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddCategory = true } label: {
                    Image(systemName: "plus")
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

struct CategoryListRow: View {
    let category: Category

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: category.icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(category.color.toColor)
                )

            Text(category.name)
                .font(AppTypography.body)

            Spacer()

            Text("\(category.transactions?.count ?? 0) txns")
                .font(AppTypography.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

// MARK: - Placeholder Views

struct ExportDataView: View {
    var body: some View {
        ContentUnavailableView(
            "Coming Soon",
            systemImage: "square.and.arrow.up",
            description: Text("Export functionality will be available in a future update")
        )
        .navigationTitle("Export")
    }
}

struct BackupView: View {
    var body: some View {
        ContentUnavailableView(
            "Coming Soon",
            systemImage: "arrow.triangle.2.circlepath",
            description: Text("Backup functionality will be available in a future update")
        )
        .navigationTitle("Backup")
    }
}

struct CurrencySettingsView: View {
    var body: some View {
        ContentUnavailableView(
            "Coming Soon",
            systemImage: "dollarsign.circle",
            description: Text("Currency settings will be available in a future update")
        )
        .navigationTitle("Currency")
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        ContentUnavailableView(
            "Coming Soon",
            systemImage: "bell.badge",
            description: Text("Notification settings will be available in a future update")
        )
        .navigationTitle("Notifications")
    }
}

struct SecuritySettingsView: View {
    var body: some View {
        ContentUnavailableView(
            "Coming Soon",
            systemImage: "lock.shield",
            description: Text("Security settings will be available in a future update")
        )
        .navigationTitle("Security")
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Image(systemName: "dollarsign.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: AppSpacing.xs) {
                    Text("Track Wallet")
                        .font(AppTypography.display)

                    Text("Version 1.0.0")
                        .font(AppTypography.callout)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Text("A personal finance tracking app")
                    .font(AppTypography.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Text("\u{00A9} 2026 Track Wallet")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textTertiary)
                    .padding(.bottom, AppSpacing.xl)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView(authManager: AuthenticationManager())
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Debt.self])
}
