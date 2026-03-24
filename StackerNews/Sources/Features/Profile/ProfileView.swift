import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab: ProfileTab = .posts
    
    enum ProfileTab: String, CaseIterable {
        case posts = "Posts"
        case comments = "Comments"
        case zaps = "Zaps"
    }
    
    var user: User? {
        authService.currentUser
    }
    
    var body: some View {
        ZStack {
            AppTheme.shared.background(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: user?.avatarUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(AppTheme.shared.snYellow.opacity(0.3))
                                .overlay(
                                    Text(String(user?.username.prefix(1) ?? "?").uppercased())
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppTheme.shared.snYellow)
                                )
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        
                        VStack(spacing: 4) {
                            Text(user?.displayName ?? user?.username ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                            
                            Text("@\(user?.username ?? "user")")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                        }
                        
                        if let bio = user?.bio {
                            Text(bio)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        HStack(spacing: 32) {
                            StatView(value: "\(user?.reputation ?? 0)", label: "Reputation")
                            StatView(value: "\(user?.walletBalance ?? 0)", label: "Sats")
                        }
                        
                        Button(action: {}) {
                            Text("Edit Profile")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(AppTheme.shared.cardBackground(for: colorScheme))
                                .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(AppTheme.shared.borderColor(for: colorScheme), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.vertical, 24)
                    
                    HStack(spacing: 0) {
                        ForEach(ProfileTab.allCases, id: \.self) { tab in
                            Button(action: { selectedTab = tab }) {
                                VStack(spacing: 8) {
                                    Text(tab.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(selectedTab == tab ? .semibold : .regular)
                                        .foregroundColor(
                                            selectedTab == tab
                                                ? AppTheme.shared.snYellow
                                                : AppTheme.shared.textSecondary(for: colorScheme)
                                        )
                                    
                                    Rectangle()
                                        .fill(selectedTab == tab ? AppTheme.shared.snYellow : Color.clear)
                                        .frame(height: 2)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .background(AppTheme.shared.cardBackground(for: colorScheme))
                    
                    VStack(spacing: 16) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.shared.cardBackground(for: colorScheme))
                                .frame(height: 100)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct StatView: View {
    let value: String
    let label: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(AuthService.shared)
}
