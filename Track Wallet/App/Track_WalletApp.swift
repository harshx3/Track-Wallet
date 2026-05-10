//
//  Track_WalletApp.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI
import SwiftData

@main
struct Track_WalletApp: App {
    let modelContainer: ModelContainer
    private let authManager = AuthenticationManager()
    @State private var containerFailed = false

    init() {
        let schema = Schema([
            Account.self,
            Transaction.self,
            Category.self,
            Debt.self,
            RecurringPayment.self,
            TransactionTemplate.self
        ])

        var container: ModelContainer?

        do {
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            for suffix in ["", "-wal", "-shm"] {
                let fileURL = storeURL.appending(path: suffix)
                try? FileManager.default.removeItem(at: fileURL)
            }

            do {
                let configuration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic
                )
                container = try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                container = try? ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
                )
            }
        }

        modelContainer = container ?? {
            try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        }()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(authManager: authManager)
                .onAppear {
                    authManager.startListeningForRevocation()
                }
        }
        .modelContainer(modelContainer)
    }
}
