import SwiftUI

struct PostCardView: View {
    let post: Post
    let onZap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isZapping = false
    
    var body: some View {
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
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorUsername ?? "Anonymous")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                    
                    Text(timeAgo(from: post.createdAt))
                        .font(.caption)
                        .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                }
                
                Spacer()
            }
            
            Text(post.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                .lineLimit(2)
            
            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                    .lineLimit(3)
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
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isZapping = true
                    }
                    onZap()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isZapping = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.subheadline)
                            .scaleEffect(isZapping ? 1.3 : 1.0)
                        Text("\(post.sats)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AppTheme.shared.snYellow)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.subheadline)
                    Text("\(post.commentCount)")
                        .font(.subheadline)
                }
                .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: post.isBookmarked == true ? "bookmark.fill" : "bookmark")
                        .font(.subheadline)
                        .foregroundColor(
                            post.isBookmarked == true
                                ? AppTheme.shared.snYellow
                                : AppTheme.shared.textSecondary(for: colorScheme)
                        )
                }
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline)
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
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct PostCardSkeleton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 12)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 50, height: 10)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 16)
            }
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 12)
            
            HStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 30, height: 16)
                
                Spacer()
            }
        }
        .padding(16)
        .background(AppTheme.shared.cardBackground(for: colorScheme))
        .shimmer()
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.1),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + (phase * geo.size.width * 3))
                }
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

#Preview {
    PostCardView(
        post: Post(
            id: "1",
            title: "Lightning Network Reaches New Heights",
            content: "The Lightning Network continues to grow with impressive adoption rates...",
            url: nil,
            imageUrl: nil,
            authorId: "user1",
            authorUsername: "satoshi",
            authorAvatarUrl: nil,
            sats: 1500,
            commentCount: 42,
            createdAt: Date(),
            isBookmarked: false
        ),
        onZap: {}
    )
    .environmentObject(ThemeManager.shared)
}
