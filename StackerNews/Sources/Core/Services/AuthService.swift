import Foundation
import LocalAuthentication
import Combine

enum AuthState {
    case unauthenticated
    case authenticating
    case authenticated(User)
    case error(String)
}

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var state: AuthState = .unauthenticated
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let api = APIClient.shared
    private let keychain = KeychainService.shared
    
    private init() {
        loadStoredSession()
    }
    
    var canUseBiometrics: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    var biometricType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricsNotAvailable
        }
        
        let reason = "Authenticate to access your Stacker News wallet"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                await MainActor.run {
                    self.isAuthenticated = true
                }
                
                if let token = keychain.getAuthToken() {
                    api.setAuthToken(token)
                    try await loadCurrentUser()
                }
            }
            
            return success
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel:
                throw AuthError.userCancelled
            case .userFallback:
                throw AuthError.userFallback
            case .biometryNotAvailable:
                throw AuthError.biometricsNotAvailable
            case .biometryNotEnrolled:
                throw AuthError.biometricsNotEnrolled
            case .biometryLockout:
                throw AuthError.biometricsLocked
            default:
                throw AuthError.authenticationFailed
            }
        }
    }
    
    func authenticateWithPasscode() async throws -> Bool {
        let context = LAContext()
        
        let reason = "Authenticate to access your Stacker News wallet"
        
        let success = try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        )
        
        if success {
            await MainActor.run {
                self.isAuthenticated = true
            }
            
            if let token = keychain.getAuthToken() {
                api.setAuthToken(token)
                try await loadCurrentUser()
            }
        }
        
        return success
    }
    
    func signIn(username: String, password: String) async throws {
        await MainActor.run {
            state = .authenticating
        }
        
        struct LoginRequest: Codable {
            var username: String
            var password: String
        }
        
        do {
            let response: AuthResponse = try await api.request(
                endpoint: "/api/auth/login",
                method: .post,
                body: LoginRequest(username: username, password: password)
            )
            
            keychain.saveAuthToken(response.token)
            api.setAuthToken(response.token)
            
            await MainActor.run {
                self.currentUser = response.user
                self.isAuthenticated = true
                self.state = .authenticated(response.user)
            }
        } catch {
            await MainActor.run {
                self.state = .error(error.localizedDescription)
            }
            throw error
        }
    }
    
    func signOut() {
        keychain.deleteAuthToken()
        api.setAuthToken(nil)
        
        currentUser = nil
        isAuthenticated = false
        state = .unauthenticated
    }
    
    private func loadStoredSession() {
        if let token = keychain.getAuthToken() {
            api.setAuthToken(token)
        }
    }
    
    private func loadCurrentUser() async throws {
        let user = try await api.getCurrentUser()
        await MainActor.run {
            self.currentUser = user
            self.state = .authenticated(user)
        }
    }
}

enum AuthError: LocalizedError {
    case biometricsNotAvailable
    case biometricsNotEnrolled
    case biometricsLocked
    case authenticationFailed
    case userCancelled
    case userFallback
    
    var errorDescription: String? {
        switch self {
        case .biometricsNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricsNotEnrolled:
            return "No biometric credentials are enrolled"
        case .biometricsLocked:
            return "Biometric authentication is locked. Please use your passcode."
        case .authenticationFailed:
            return "Authentication failed"
        case .userCancelled:
            return "Authentication was cancelled"
        case .userFallback:
            return "User chose to use passcode"
        }
    }
}
