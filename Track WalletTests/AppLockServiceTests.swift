import XCTest
import LocalAuthentication
@testable import Track_Wallet

final class AppLockServiceTests: XCTestCase {

    // MARK: - Mock evaluator

    private final class MockEvaluator: BiometricEvaluator {
        var biometricsAvailable = false
        var passcodeAvailable = false
        var shouldSucceed = true

        func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
            switch policy {
            case .deviceOwnerAuthenticationWithBiometrics:
                return biometricsAvailable
            case .deviceOwnerAuthentication:
                return passcodeAvailable
            default:
                return false
            }
        }

        func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, (any Error)?) -> Void) {
            reply(shouldSucceed, nil)
        }
    }

    // MARK: - Tests

    func testUnlocksViaBiometrics() {
        let evaluator = MockEvaluator()
        evaluator.biometricsAvailable = true
        evaluator.shouldSucceed = true

        let expectation = expectation(description: "unlock")
        AppLockService.authenticate(using: evaluator, reason: "Test") { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testFallsBackToPasscodeWhenNoBiometrics() {
        let evaluator = MockEvaluator()
        evaluator.biometricsAvailable = false
        evaluator.passcodeAvailable = true
        evaluator.shouldSucceed = true

        let expectation = expectation(description: "passcode unlock")
        AppLockService.authenticate(using: evaluator, reason: "Test") { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testAutoUnlocksWhenNoPolicyAvailable() {
        let evaluator = MockEvaluator()
        evaluator.biometricsAvailable = false
        evaluator.passcodeAvailable = false

        let expectation = expectation(description: "auto unlock")
        AppLockService.authenticate(using: evaluator, reason: "Test") { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testReportsFailureWhenBiometricsFail() {
        let evaluator = MockEvaluator()
        evaluator.biometricsAvailable = true
        evaluator.shouldSucceed = false

        let expectation = expectation(description: "failed unlock")
        AppLockService.authenticate(using: evaluator, reason: "Test") { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testReportsFailureWhenPasscodeFails() {
        let evaluator = MockEvaluator()
        evaluator.biometricsAvailable = false
        evaluator.passcodeAvailable = true
        evaluator.shouldSucceed = false

        let expectation = expectation(description: "failed passcode")
        AppLockService.authenticate(using: evaluator, reason: "Test") { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
}
