import Foundation
import Combine

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

class APIClient: ObservableObject {
    static let shared = APIClient()
    
    private let baseURL: String
    private let session: URLSession
    private var authToken: String?
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    init(baseURL: String = "") {
        self.baseURL = baseURL.isEmpty ? (Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "https://your-api.replit.app") : baseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryParams: [String: String]? = nil
    ) async throws -> T {
        var urlString = "\(baseURL)\(endpoint)"
        
        if let params = queryParams, !params.isEmpty {
            var components = URLComponents(string: urlString)
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            urlString = components?.string ?? urlString
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError(message: "Invalid URL", code: "INVALID_URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(message: "Invalid response", code: "INVALID_RESPONSE")
        }
        
        if httpResponse.statusCode >= 400 {
            if let apiError = try? decoder.decode(APIError.self, from: data) {
                throw apiError
            }
            throw APIError(message: "Request failed with status \(httpResponse.statusCode)", code: "HTTP_ERROR")
        }
        
        return try decoder.decode(T.self, from: data)
    }
    
    func getPosts(sort: String = "hot", limit: Int = 20) async throws -> [Post] {
        try await request(
            endpoint: "/api/posts",
            queryParams: ["sort": sort, "limit": String(limit)]
        )
    }
    
    func getPost(id: String) async throws -> Post {
        try await request(endpoint: "/api/posts/\(id)")
    }
    
    func createPost(_ post: CreatePostRequest) async throws -> Post {
        try await request(endpoint: "/api/posts", method: .post, body: post)
    }
    
    func getComments(postId: String) async throws -> [Comment] {
        try await request(endpoint: "/api/posts/\(postId)/comments")
    }
    
    func createComment(_ comment: CreateCommentRequest) async throws -> Comment {
        try await request(endpoint: "/api/comments", method: .post, body: comment)
    }
    
    func zap(_ request: ZapRequest) async throws -> Zap {
        try await self.request(endpoint: "/api/zaps", method: .post, body: request)
    }
    
    func getUser(id: String) async throws -> User {
        try await request(endpoint: "/api/users/\(id)")
    }
    
    func getCurrentUser() async throws -> User {
        try await request(endpoint: "/api/auth/me")
    }
    
    func getTransactions() async throws -> [LightningTransaction] {
        try await request(endpoint: "/api/lightning/transactions")
    }
    
    func generateInvoice(amount: Int, description: String?) async throws -> LightningInvoice {
        struct InvoiceRequest: Codable {
            var amount: Int
            var description: String?
        }
        return try await request(
            endpoint: "/api/lightning/invoice",
            method: .post,
            body: InvoiceRequest(amount: amount, description: description)
        )
    }
    
    func payInvoice(bolt11: String) async throws -> LightningTransaction {
        struct PayRequest: Codable {
            var bolt11: String
        }
        return try await request(
            endpoint: "/api/lightning/pay",
            method: .post,
            body: PayRequest(bolt11: bolt11)
        )
    }
}
