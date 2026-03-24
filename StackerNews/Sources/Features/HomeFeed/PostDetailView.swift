import SwiftUI

struct PostDetailView: View {
    let post: Post
    
    @StateObject private var viewModel = PostDetailViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var newComment = ""
    @State private var isSubmitting = false
    
    var body: some View {
        ZStack {
            AppTheme.shared.background(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                AsyncImage(url: URL(string: post.authorAvatarUrl ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(AppTheme.shared.snYellow.opacity(0.3))
                                        .overlay(
                                            Text(String(post.authorUsername?.prefix(1) ?? "?").uppercased())
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(AppTheme.shared.snYellow)
                                        )
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(post.authorUsername ?? "Anonymous")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                                    
                                    Text(post.createdAt, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                                }
                                
                                Spacer()
                            }
                            
                            Text(post.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                            
                            if let content = post.content, !content.isEmpty {
                                Text(content)
                                    .font(.body)
                                    .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                            }
                            
                            if let url = post.url {
                                Link(destination: URL(string: url)!) {
                                    HStack {
                                        Image(systemName: "link")
                                        Text(URL(string: url)?.host ?? url)
                                            .lineLimit(1)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.shared.snYellow)
                                    .padding(12)
                                    .background(AppTheme.shared.cardBackground(for: colorScheme))
                                    .cornerRadius(8)
                                }
                            }
                            
                            if let imageUrl = post.imageUrl {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(AppTheme.shared.darkCard)
                                }
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            HStack(spacing: 24) {
                                Button(action: {}) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "bolt.fill")
                                        Text("\(post.sats) sats")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppTheme.shared.snYellow)
                                }
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "bubble.left")
                                    Text("\(post.commentCount)")
                                }
                                .font(.subheadline)
                                .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                                }
                            }
                        }
                        .padding(16)
                        .background(AppTheme.shared.cardBackground(for: colorScheme))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Comments")
                                .font(.headline)
                                .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                                .padding(.horizontal, 16)
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else if viewModel.comments.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                                    
                                    Text("No comments yet")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                                    
                                    Text("Be the first to comment!")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(viewModel.comments) { comment in
                                        CommentRow(comment: comment)
                                    }
                                }
                            }
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    TextField("Add a comment...", text: $newComment)
                        .padding(12)
                        .background(AppTheme.shared.cardBackground(for: colorScheme))
                        .cornerRadius(20)
                    
                    Button(action: submitComment) {
                        if isSubmitting {
                            ProgressView()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(newComment.isEmpty ? AppTheme.shared.textSecondary(for: colorScheme) : AppTheme.shared.snYellow)
                        }
                    }
                    .disabled(newComment.isEmpty || isSubmitting)
                }
                .padding(16)
                .background(AppTheme.shared.cardBackground(for: colorScheme))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Post")
                    .fontWeight(.semibold)
            }
        }
        .task {
            await viewModel.loadComments(postId: post.id)
        }
    }
    
    private func submitComment() {
        isSubmitting = true
        
        Task {
            do {
                let request = CreateCommentRequest(
                    content: newComment,
                    postId: post.id,
                    parentId: nil
                )
                _ = try await APIClient.shared.createComment(request)
                
                await MainActor.run {
                    newComment = ""
                    isSubmitting = false
                }
                
                await viewModel.loadComments(postId: post.id)
            } catch {
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: comment.authorAvatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(AppTheme.shared.snYellow.opacity(0.3))
                        .overlay(
                            Text(String(comment.authorUsername?.prefix(1) ?? "?").uppercased())
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.shared.snYellow)
                        )
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())
                
                Text(comment.authorUsername ?? "Anonymous")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                
                Text(comment.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                
                Spacer()
            }
            
            Text(comment.content)
                .font(.subheadline)
                .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
            
            HStack(spacing: 16) {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                        Text("\(comment.sats)")
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.shared.snYellow)
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.left")
                        Text("Reply")
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                }
            }
        }
        .padding(16)
        .background(AppTheme.shared.cardBackground(for: colorScheme))
        .overlay(
            Rectangle()
                .fill(AppTheme.shared.borderColor(for: colorScheme))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

class PostDetailViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let api = APIClient.shared
    
    func loadComments(postId: String) async {
        await MainActor.run { isLoading = true }
        
        do {
            let fetchedComments = try await api.getComments(postId: postId)
            await MainActor.run {
                self.comments = fetchedComments
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

#Preview {
    NavigationView {
        PostDetailView(
            post: Post(
                id: "1",
                title: "Lightning Network Reaches New Heights",
                content: "The Lightning Network continues to grow...",
                url: nil,
                imageUrl: nil,
                authorId: "user1",
                authorUsername: "satoshi",
                authorAvatarUrl: nil,
                sats: 1500,
                commentCount: 42,
                createdAt: Date(),
                isBookmarked: false
            )
        )
    }
    .environmentObject(ThemeManager.shared)
    .environmentObject(AuthService.shared)
}
