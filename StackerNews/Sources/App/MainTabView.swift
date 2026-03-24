import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @Environment(\.colorScheme) var colorScheme
    
    enum Tab {
        case home
        case search
        case newPost
        case wallet
        case profile
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeFeedView()
                    .tag(Tab.home)
                
                SearchView()
                    .tag(Tab.search)
                
                Color.clear
                    .tag(Tab.newPost)
                
                WalletView()
                    .tag(Tab.wallet)
                
                ProfileView()
                    .tag(Tab.profile)
            }
            
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: Binding(
            get: { selectedTab == .newPost },
            set: { if !$0 { selectedTab = .home } }
        )) {
            NewPostView(onDismiss: { selectedTab = .home })
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == .home
            ) {
                selectedTab = .home
            }
            
            TabBarButton(
                icon: "magnifyingglass",
                title: "Search",
                isSelected: selectedTab == .search
            ) {
                selectedTab = .search
            }
            
            NewPostButton {
                selectedTab = .newPost
            }
            
            TabBarButton(
                icon: "bolt.fill",
                title: "Wallet",
                isSelected: selectedTab == .wallet
            ) {
                selectedTab = .wallet
            }
            
            TabBarButton(
                icon: "person.fill",
                title: "Profile",
                isSelected: selectedTab == .profile
            ) {
                selectedTab = .profile
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(
            AppTheme.shared.cardBackground(for: colorScheme)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(
                isSelected 
                    ? AppTheme.shared.snYellow 
                    : AppTheme.shared.textSecondary(for: colorScheme)
            )
            .frame(maxWidth: .infinity)
        }
    }
}

struct NewPostButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppTheme.shared.snYellow)
                    .frame(width: 56, height: 56)
                    .shadow(color: AppTheme.shared.snYellow.opacity(0.5), radius: 8, x: 0, y: 4)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .offset(y: -20)
    }
}

#Preview {
    MainTabView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(AuthService.shared)
}
