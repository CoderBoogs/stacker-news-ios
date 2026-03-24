import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.stackernews.app"
    
    private init() {}
    
    func saveAuthToken(_ token: String) {
        save(key: "authToken", value: token)
    }
    
    func getAuthToken() -> String? {
        get(key: "authToken")
    }
    
    func deleteAuthToken() {
        delete(key: "authToken")
    }
    
    func saveLightningCredentials(_ credentials: String) {
        save(key: "lightningCredentials", value: credentials)
    }
    
    func getLightningCredentials() -> String? {
        get(key: "lightningCredentials")
    }
    
    func deleteLightningCredentials() {
        delete(key: "lightningCredentials")
    }
    
    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
