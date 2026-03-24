import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [Post] = []
    @State private var isSearching = false
    @Environment(\.colorScheme) var colorScheme
    
    let recentSearches = ["Lightning Network", "Bitcoin", "Stacker News", "Zaps"]
    let trendingTopics = ["#bitcoin", "#lightning", "#nostr", "#satsflow"]
    
    var body: some View {
        ZStack {
            AppTheme.shared.background(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                        
                        TextField("Search posts, users, topics...", text: $searchText)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                search()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                            }
                        }
                    }
                    .padding(12)
                    .background(AppTheme.shared.cardBackground(for: colorScheme))
                    .cornerRadius(12)
                }
                .padding(16)
                
                ScrollView {
                    if searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 24) {
                            if !recentSearches.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Recent Searches")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                                        
                                        Spacer()
                                        
                                        Button("Clear") {}
                                            .font(.caption)
                                            .foregroundColor(AppTheme.shared.snYellow)
                                    }
                                    
                                    ForEach(recentSearches, id: \.self) { term in
                                        HStack {
                                            Image(systemName: "clock")
                                                .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                                            
                                            Text(term)
                                                .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            searchText = term
                                            search()
                                        }
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Trending Topics")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                                
                                FlowLayout(spacing: 8) {
                                    ForEach(trendingTopics, id: \.self) { topic in
                                        Text(topic)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(AppTheme.shared.snYellow.opacity(0.2))
                                            .foregroundColor(AppTheme.shared.snYellow)
                                            .cornerRadius(16)
                                            .onTapGesture {
                                                searchText = topic
                                                search()
                                            }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    } else if isSearching {
                        ProgressView()
                            .padding(.top, 40)
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                            
                            Text("No results found")
                                .font(.headline)
                                .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                            
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(searchResults) { post in
                                PostCardView(post: post, onZap: {})
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func search() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSearching = false
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            ), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        let maxViewWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxViewWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX - spacing)
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

#Preview {
    SearchView()
        .environmentObject(ThemeManager.shared)
}
