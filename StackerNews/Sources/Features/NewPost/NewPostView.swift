import SwiftUI
import PhotosUI

struct NewPostView: View {
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var title = ""
    @State private var content = ""
    @State private var url = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isPosting = false
    @State private var postType: PostType = .discussion
    
    enum PostType: String, CaseIterable {
        case discussion = "Discussion"
        case link = "Link"
        case image = "Image"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.shared.background(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Picker("Type", selection: $postType) {
                            ForEach(PostType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                            
                            TextField("What's happening?", text: $title)
                                .padding()
                                .background(AppTheme.shared.cardBackground(for: colorScheme))
                                .cornerRadius(12)
                        }
                        
                        if postType == .link {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("URL")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                                
                                TextField("https://...", text: $url)
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(AppTheme.shared.cardBackground(for: colorScheme))
                                    .cornerRadius(12)
                            }
                        }
                        
                        if postType == .image {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Image")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                                
                                if let image = selectedImage {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        Button(action: { selectedImage = nil }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .shadow(radius: 2)
                                        }
                                        .padding(8)
                                    }
                                } else {
                                    PhotosPicker(selection: $selectedItem, matching: .images) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "photo.on.rectangle.angled")
                                                .font(.system(size: 40))
                                            Text("Select Image")
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(AppTheme.shared.snYellow)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 150)
                                        .background(AppTheme.shared.cardBackground(for: colorScheme))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppTheme.shared.snYellow.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                        )
                                    }
                                    .onChange(of: selectedItem) { _, newItem in
                                        Task {
                                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                                               let image = UIImage(data: data) {
                                                selectedImage = image
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content (optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                            
                            TextEditor(text: $content)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(AppTheme.shared.cardBackground(for: colorScheme))
                                .cornerRadius(12)
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: submitPost) {
                        if isPosting {
                            ProgressView()
                        } else {
                            Text("Post")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(title.isEmpty || isPosting)
                    .foregroundColor(title.isEmpty ? AppTheme.shared.textSecondary(for: colorScheme) : AppTheme.shared.snYellow)
                }
            }
        }
    }
    
    private func submitPost() {
        isPosting = true
        
        Task {
            do {
                let request = CreatePostRequest(
                    title: title,
                    content: content.isEmpty ? nil : content,
                    url: postType == .link ? url : nil,
                    imageUrl: nil
                )
                
                _ = try await APIClient.shared.createPost(request)
                
                await MainActor.run {
                    isPosting = false
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    isPosting = false
                }
            }
        }
    }
}

#Preview {
    NewPostView(onDismiss: {})
        .environmentObject(ThemeManager.shared)
}
