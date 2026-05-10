//
//  AuthenticationManager.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/30/26.
//

import Foundation
import AuthenticationServices

@Observable
final class AuthenticationManager {
    var isAuthenticated = false
    var userName: String = ""
    var userEmail: String = ""
    var isCheckingCredential = true
    
    private let userIDKey = "appleUserID"
    private let userNameKey = "appleUserName"
    private let userEmailKey = "appleUserEmail"
    
    init() {
        loadUserInfo()
        checkCredentialState()
    }
    
    // MARK: - Keychain
    
    private func saveToKeychain(userID: String) {
        let data = Data(userID.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userIDKey,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.trackwallet"
        ]
        let deleteStatus = SecItemDelete(query as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            print("[Keychain] Delete failed: \(deleteStatus)")
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus != errSecSuccess {
            print("[Keychain] Save failed: \(addStatus)")
        }
    }
    
    private func loadFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userIDKey,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.trackwallet",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    private func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userIDKey,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.trackwallet"
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("[Keychain] Delete failed: \(status)")
        }
    }
    
    // MARK: - User Info (UserDefaults — name/email are non-sensitive)
    
    private func saveUserInfo(name: String, email: String) {
        UserDefaults.standard.set(name, forKey: userNameKey)
        UserDefaults.standard.set(email, forKey: userEmailKey)
        userName = name
        userEmail = email
    }
    
    private func loadUserInfo() {
        userName = UserDefaults.standard.string(forKey: userNameKey) ?? ""
        userEmail = UserDefaults.standard.string(forKey: userEmailKey) ?? ""
    }
    
    func updateProfile(name: String) {
        UserDefaults.standard.set(name, forKey: userNameKey)
        userName = name
    }

    private func clearUserInfo() {
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        userName = ""
        userEmail = ""
    }
    
    // MARK: - Credential State

    func checkCredentialState() {
        guard let userID = loadFromKeychain() else {
            isAuthenticated = false
            isCheckingCredential = false
            return
        }

        #if DEBUG
        if userID == "mock_user_id" {
            isAuthenticated = true
            isCheckingCredential = false
            return
        }
        #endif

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { state, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch state {
                case .authorized:
                    self.isAuthenticated = true
                case .revoked, .notFound:
                    self.signOut()
                default:
                    self.isAuthenticated = false
                }
                self.isCheckingCredential = false
            }
        }
    }

    #if DEBUG
    func mockSignIn() {
        saveToKeychain(userID: "mock_user_id")
        saveUserInfo(name: "User", email: "")
        isAuthenticated = true
    }
    #endif

    // MARK: - Sign In
    
    func handleSignInResult(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return
            }
            
            saveToKeychain(userID: credential.user)
            
            // Apple only provides name/email on the FIRST authorization
            let givenName = credential.fullName?.givenName ?? ""
            let familyName = credential.fullName?.familyName ?? ""
            let fullName = [givenName, familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            let email = credential.email ?? ""
            
            if !fullName.isEmpty || !email.isEmpty {
                saveUserInfo(
                    name: fullName.isEmpty ? userName : fullName,
                    email: email.isEmpty ? userEmail : email
                )
            }
            
            isAuthenticated = true
            
        case .failure:
            break
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        deleteFromKeychain()
        clearUserInfo()
        isAuthenticated = false
    }
    
    // MARK: - Revocation Listener
    
    func startListeningForRevocation() {
        NotificationCenter.default.addObserver(
            forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.signOut()
        }
    }
}
