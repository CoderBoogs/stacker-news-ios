import Foundation

struct User: Codable, Identifiable {
    let id: String
    var username: String
    var displayName: String?
    var bio: String?
    var avatarUrl: String?
    var lightningAddress: String?
    var walletBalance: Int
    var reputation: Int
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, username, displayName, bio, avatarUrl, lightningAddress, walletBalance, reputation, createdAt
    }
}

struct Post: Codable, Identifiable {
    let id: String
    var title: String
    var content: String?
    var url: String?
    var imageUrl: String?
    var authorId: String
    var authorUsername: String?
    var authorAvatarUrl: String?
    var sats: Int
    var commentCount: Int
    var createdAt: Date
    var isBookmarked: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, url, imageUrl, authorId, authorUsername, authorAvatarUrl, sats, commentCount, createdAt, isBookmarked
    }
}

struct Comment: Codable, Identifiable {
    let id: String
    var content: String
    var authorId: String
    var authorUsername: String?
    var authorAvatarUrl: String?
    var postId: String
    var parentId: String?
    var sats: Int
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, content, authorId, authorUsername, authorAvatarUrl, postId, parentId, sats, createdAt
    }
}

struct Zap: Codable, Identifiable {
    let id: String
    var amount: Int
    var senderId: String
    var senderUsername: String?
    var targetType: String
    var targetId: String
    var message: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, amount, senderId, senderUsername, targetType, targetId, message, createdAt
    }
}

struct LightningTransaction: Codable, Identifiable {
    let id: String
    var type: TransactionType
    var amount: Int
    var description: String?
    var paymentHash: String?
    var invoice: String?
    var status: TransactionStatus
    var createdAt: Date
    
    enum TransactionType: String, Codable {
        case receive
        case send
    }
    
    enum TransactionStatus: String, Codable {
        case pending
        case completed
        case failed
    }
}

struct LightningInvoice: Codable {
    var bolt11: String
    var paymentHash: String
    var amount: Int
    var description: String?
    var expiresAt: Date
}

struct CreatePostRequest: Codable {
    var title: String
    var content: String?
    var url: String?
    var imageUrl: String?
}

struct CreateCommentRequest: Codable {
    var content: String
    var postId: String
    var parentId: String?
}

struct ZapRequest: Codable {
    var amount: Int
    var targetType: String
    var targetId: String
    var message: String?
}

struct AuthResponse: Codable {
    var user: User
    var token: String
}

struct APIError: Codable, Error {
    var message: String
    var code: String?
}
