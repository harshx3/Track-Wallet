import XCTest
@testable import Track_Wallet

final class AuthenticationTests: XCTestCase {

    #if DEBUG
    func testMockSignInSetsAuthenticated() {
        let manager = AuthenticationManager()
        manager.mockSignIn()
        XCTAssertTrue(manager.isAuthenticated)
        manager.signOut()
    }

    func testMockSignInCredentialStateSurvivesRecheck() {
        let manager = AuthenticationManager()
        manager.mockSignIn()
        XCTAssertTrue(manager.isAuthenticated)

        manager.checkCredentialState()
        XCTAssertTrue(manager.isAuthenticated)

        manager.signOut()
        XCTAssertFalse(manager.isAuthenticated)
    }
    #endif

    // mockSignIn() is wrapped in #if DEBUG in AuthenticationManager.swift.
    // In Release builds these tests are compiled out along with the function,
    // so there is no way for mock credentials to leak into production.

    func testSignOutClearsAuthentication() {
        let manager = AuthenticationManager()
        manager.signOut()
        XCTAssertFalse(manager.isAuthenticated)
        XCTAssertTrue(manager.userName.isEmpty)
        XCTAssertTrue(manager.userEmail.isEmpty)
    }
}
