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
    @State private var authManager = AuthenticationManager()

    init() {
        let schema = Schema([
            Account.self,
            Transaction.self,
            Category.self,
            Debt.self
        ])

        do {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Migration failed — delete the old store and recreate
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            for suffix in ["", "-wal", "-shm"] {
                let fileURL = storeURL.appending(path: suffix)
                try? FileManager.default.removeItem(at: fileURL)
            }

            do {
                let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }
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
