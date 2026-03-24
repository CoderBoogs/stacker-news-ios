import SwiftUI

@main
struct StackerNewsApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var authService = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(authService)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isUnlocked = false
    @State private var showAuthError = false
    @State private var authErrorMessage = ""
    
    var body: some View {
        Group {
            if isUnlocked {
                MainTabView()
            } else {
                LockScreenView(
                    onUnlock: { isUnlocked = true },
                    onError: { message in
                        authErrorMessage = message
                        showAuthError = true
                    }
                )
            }
        }
        .alert("Authentication Error", isPresented: $showAuthError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authErrorMessage)
        }
    }
}

struct LockScreenView: View {
    let onUnlock: () -> Void
    let onError: (String) -> Void
    
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    @State private var isAuthenticating = false
    
    var body: some View {
        ZStack {
            AppTheme.shared.background(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                SNLogo(size: 80)
                
                Text("Stacker News")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                
                Text("Lightning-powered social news")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: authenticateWithBiometrics) {
                        HStack {
                            Image(systemName: biometricIcon)
                                .font(.title2)
                            Text(biometricButtonText)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.shared.snYellow)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    .disabled(isAuthenticating)
                    
                    Button(action: authenticateWithPasscode) {
                        Text("Use Passcode")
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.shared.snYellow)
                    }
                    .disabled(isAuthenticating)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            authenticateWithBiometrics()
        }
    }
    
    private var biometricIcon: String {
        switch authService.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.shield"
        }
    }
    
    private var biometricButtonText: String {
        switch authService.biometricType {
        case .faceID:
            return "Unlock with Face ID"
        case .touchID:
            return "Unlock with Touch ID"
        default:
            return "Unlock"
        }
    }
    
    private func authenticateWithBiometrics() {
        guard authService.canUseBiometrics else {
            authenticateWithPasscode()
            return
        }
        
        isAuthenticating = true
        
        Task {
            do {
                let success = try await authService.authenticateWithBiometrics()
                await MainActor.run {
                    isAuthenticating = false
                    if success {
                        onUnlock()
                    }
                }
            } catch let error as AuthError {
                await MainActor.run {
                    isAuthenticating = false
                    if case .userFallback = error {
                        authenticateWithPasscode()
                    } else if case .userCancelled = error {
                    } else {
                        onError(error.localizedDescription ?? "Authentication failed")
                    }
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    onError(error.localizedDescription)
                }
            }
        }
    }
    
    private func authenticateWithPasscode() {
        isAuthenticating = true
        
        Task {
            do {
                let success = try await authService.authenticateWithPasscode()
                await MainActor.run {
                    isAuthenticating = false
                    if success {
                        onUnlock()
                    }
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    onError(error.localizedDescription)
                }
            }
        }
    }
}
