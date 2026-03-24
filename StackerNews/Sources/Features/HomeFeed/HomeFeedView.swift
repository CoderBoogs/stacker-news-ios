import SwiftUI

struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.shared.background(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    SNHeaderView()
                    
                    SortPicker(selectedSort: $viewModel.selectedSort)
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if viewModel.isLoading && viewModel.posts.isEmpty {
                                ForEach(0..<5, id: \.self) { _ in
                                    PostCardSkeleton()
                                }
                            } else {
                                ForEach(viewModel.posts) { post in
                                    NavigationLink(destination: PostDetailView(post: post)) {
                                        PostCardView(
                                            post: post,
                                            onZap: { viewModel.zapPost(post) }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadPosts()
        }
    }
}

struct SNHeaderView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            SNLogo()
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("\(authService.currentUser?.walletBalance ?? 0)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.shared.bitcoinOrange)
                
                Text("sats")
                    .font(.caption)
                    .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
            }
            
            Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
            }
            .padding(.leading, 12)
            
            Button(action: {}) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.title3)
                        .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
            .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.shared.cardBackground(for: colorScheme))
    }
}

struct SortPicker: View {
    @Binding var selectedSort: String
    @Environment(\.colorScheme) var colorScheme
    
    let sorts = ["hot", "top", "recent"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(sorts, id: \.self) { sort in
                    Button(action: { selectedSort = sort }) {
                        Text(sort.capitalized)
                            .font(.subheadline)
                            .fontWeight(selectedSort == sort ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedSort == sort
                                    ? AppTheme.shared.snYellow
                                    : AppTheme.shared.cardBackground(for: colorScheme)
                            )
                            .foregroundColor(
                                selectedSort == sort
                                    ? .black
                                    : AppTheme.shared.textPrimary(for: colorScheme)
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(AppTheme.shared.cardBackground(for: colorScheme))
    }
}

class HomeFeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var selectedSort = "hot"
    @Published var error: String?
    
    private let api = APIClient.shared
    
    func loadPosts() async {
        await MainActor.run { isLoading = true }
        
        do {
            let fetchedPosts = try await api.getPosts(sort: selectedSort)
            await MainActor.run {
                self.posts = fetchedPosts
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func refresh() async {
        await loadPosts()
    }
    
    func zapPost(_ post: Post) {
        Task {
            do {
                _ = try await api.zap(ZapRequest(
                    amount: 1,
                    targetType: "post",
                    targetId: post.id,
                    message: nil
                ))
                await loadPosts()
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    HomeFeedView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(AuthService.shared)
}
