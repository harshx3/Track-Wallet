import Foundation
import LocalAuthentication

protocol BiometricEvaluator {
    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, (any Error)?) -> Void)
}

extension LAContext: BiometricEvaluator {}

enum AppLockService {
    static func authenticate(
        using evaluator: BiometricEvaluator,
        reason: String,
        completion: @escaping (Bool) -> Void
    ) {
        var error: NSError?
        if evaluator.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            evaluator.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                completion(success)
            }
        } else if evaluator.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            evaluator.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                completion(success)
            }
        } else {
            completion(true)
        }
    }
}
